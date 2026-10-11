import 'dart:convert';
import 'dart:io';

import 'package:chat_bot/base/api.dart';
import 'package:chat_bot/base/api_impl/chatgpt_impl.dart';
import 'package:chat_bot/base/db/chat_item.dart';
import 'package:chat_bot/hive_bean/generate_content.dart';
import 'package:chat_bot/hive_bean/local_chat_history.dart';
import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'chat_data.dart';
import 'model_store.dart';

/// Server + model yang dipakai untuk satu percakapan.
class MuseTarget {
  final AllModelBean bean;
  final String model;
  const MuseTarget(this.bean, this.model);
}

/// Panggilan tool yang diminta AI lewat penanda `[[tool:nama|argumen]]`.
class MuseToolCall {
  final String name;
  final String arg;
  const MuseToolCall(this.name, this.arg);
}

class MuseAiException implements Exception {
  final String message;
  const MuseAiException(this.message);
  @override
  String toString() => message;
}

/// Jembatan antara layar chat Muse dan backend AI bawaan app
/// (API / ChatGPTImpl / GeminiImpl / dst). Semua logika non-UI ada di sini.
class MuseAi {
  MuseAi._();

  static final RegExp _toolRe =
      RegExp(r'\[\[tool:([a-z_]+)(?:\|([^\]]*))?\]\]');

  // -- Pemilihan server/model ----------------------------------------------

  /// Pilih server + model dari default Ruang Kreasi.
  /// Mengembalikan null bila belum ada server sama sekali.
  static MuseTarget? resolve() {
    final List<AllModelBean> beans = HiveBox().openAIConfig.values.toList();
    if (beans.isEmpty) return null;
    final String wanted = ModelStore.defaultChat();
    if (wanted.isNotEmpty) {
      for (final AllModelBean b in beans) {
        final List<SupportedModels> list =
            b.supportedModels ?? <SupportedModels>[];
        if (list.any((SupportedModels m) => m.id == wanted)) {
          return MuseTarget(b, wanted);
        }
      }
      // Model manual: pakai server pertama.
      return MuseTarget(beans.first, wanted);
    }
    for (final AllModelBean b in beans) {
      final List<SupportedModels> t = b.getTextModels;
      if (t.isNotEmpty && t.first.id != null && t.first.id!.isNotEmpty) {
        return MuseTarget(b, t.first.id!);
      }
    }
    return null;
  }

  // -- System prompt -----------------------------------------------------------

  static bool _on(String id) => ModelStore.toolEnabled(id);

  static String _state(String id) => _on(id) ? 'AKTIF' : 'NONAKTIF';

  /// Instruksi sistem: memberi tahu AI fitur aplikasi dan tools yang ada.
  static String systemPrompt() {
    final StringBuffer b = StringBuffer();
    b.writeln('Kamu adalah Muse, asisten AI di dalam aplikasi XDots '
        '(Android). Jawab dalam bahasa yang dipakai pengguna '
        '(default Bahasa Indonesia), ringkas, jelas, dan ramah.');
    b.writeln();
    b.writeln('FITUR APLIKASI (boleh kamu jelaskan caranya ke pengguna):');
    b.writeln('- Balasanmu dirender sebagai Markdown: judul, daftar, tabel, '
        'blok kode (ada tombol salin), link, dan gambar.');
    b.writeln('- Lampiran: tombol + di kolom pesan membuka Foto, Kamera, '
        'Video, dan Berkas. Gambar bisa kamu lihat langsung. Isi file '
        'teks/kode dikirim sebagai teks. Untuk PDF/PPTX/DOCX kamu hanya '
        'menerima nama file, jadi minta pengguna menempelkan isinya.');
    b.writeln('- Ikon mic di kolom pesan = input suara (suara diubah jadi '
        'teks, lalu dikirim sebagai pesan biasa).');
    b.writeln('- Tekan lama bubble pesan: Edit, Salin, Bagikan, Kirim ulang, '
        'Hapus.');
    b.writeln('- Tombol menu kiri atas = History percakapan; tombol pena = '
        'obrolan baru; tombol titik tiga = hapus pesan.');
    b.writeln('- Navbar bawah: Chat, Library/Prompt, Ruang Kreasi (ikon '
        'bohlam), Server, Pengaturan.');
    b.writeln('- Ruang Kreasi: memilih Model Chat/Gambar/Video default '
        '(dikelompokkan per provider) dan mengatur tools, layanan search, '
        'serta MCP.');
    b.writeln('- Server: menambah provider (OpenAI-compatible, Gemini, '
        'Ollama, DeepSeek, dll). Fitur Custom Endpoint di Kelola Model: '
        'nama provider, Base URL (tanpa /v1), dan API Key sendiri.');
    b.writeln();
    b.writeln('TOOLS. Untuk memakai tool, tulis PERSIS satu baris penanda '
        'di akhir jawabanmu (bukan di dalam blok kode). Aplikasi akan '
        'menjalankannya; hasilnya dikirim kembali kepadamu sebagai pesan '
        'berawalan [HASIL TOOL].');
    b.writeln('- create_image [${_state('create_image')}]: membuat gambar. '
        'Format: [[tool:create_image|prompt gambar terperinci, bahasa '
        'Inggris]]');
    b.writeln('- tools_browsing [${_state('tools_browsing')}]: membaca teks '
        'sebuah halaman web. Format: [[tool:browse|https://alamat.lengkap]]');
    b.writeln('- tools_use [${_state('tools_use')}]: melihat daftar tool '
        'yang tersedia. Format: [[tool:tools_use]]');
    b.writeln('- create_video [${_state('create_video')}]: BELUM ada '
        'backend-nya, jangan menjanjikan atau mencoba membuat video.');
    b.writeln();
    b.writeln('ATURAN TOOL: pakai tool hanya bila diminta atau memang '
        'perlu; maksimal satu tool per giliran; jangan mengarang hasil '
        'tool; kalau tool NONAKTIF, beri tahu pengguna agar '
        'mengaktifkannya di Ruang Kreasi. Setelah menerima [HASIL TOOL], '
        'jawab pengguna memakai hasil itu tanpa memanggil tool yang sama '
        'lagi.');
    return b.toString();
  }

  // -- Riwayat -> ChatItem ----------------------------------------------------

  static const Set<String> _textExt = <String>{
    'txt', 'md', 'markdown', 'json', 'xml', 'yaml', 'yml', 'csv', 'log',
    'html', 'htm', 'css', 'js', 'ts', 'dart', 'py', 'java', 'kt', 'c', 'h',
    'cpp', 'sh', 'sql', 'ini', 'toml',
  };

  static String _ext(String name) {
    final List<String> p = name.split('.');
    return p.length > 1 ? p.last.toLowerCase() : '';
  }

  static ChatItem _item(int i, bool user, String content,
      {List<String>? images}) {
    return ChatItem(
      content: content,
      time: i,
      type: user ? ChatType.user.index : ChatType.bot.index,
      status: MessageStatus.success.index,
      images: images ?? <String>[],
    );
  }

  static Future<ChatItem?> _fromMsg(int i, ChatMsg m) async {
    if (m.type == MessageType.text) {
      String text = m.text;
      final List<String> images = <String>[];
      if (m.isUser) {
        for (final MsgAttachment a in m.attachments) {
          // kind: 0 foto, 1 kamera, 2 video, 3 berkas (urutan AttachKind)
          if (a.kind == 0 || a.kind == 1) {
            try {
              final File f = File(a.path);
              if (await f.length() <= 4 * 1024 * 1024) {
                images.add(base64Encode(await f.readAsBytes()));
              } else {
                text += '\n[Lampiran gambar ${a.name} terlalu besar]';
              }
            } catch (_) {
              text += '\n[Lampiran gambar ${a.name} tidak terbaca]';
            }
          } else if (a.kind == 2) {
            text += '\n[Lampiran video: ${a.name}]';
          } else {
            if (_textExt.contains(_ext(a.name))) {
              try {
                String body = await File(a.path).readAsString();
                if (body.length > 30000) body = body.substring(0, 30000);
                text += '\n\n[Lampiran file: ${a.name}]\n$body';
              } catch (_) {
                text += '\n[Lampiran file: ${a.name} (tidak terbaca)]';
              }
            } else {
              text += '\n[Lampiran file: ${a.name} '
                  '(isi tidak dapat dibaca aplikasi)]';
            }
          }
        }
      }
      if (text.trim().isEmpty && images.isEmpty) return null;
      return _item(i, m.isUser, text.isEmpty ? '(gambar)' : text,
          images: images);
    }
    if (m.type == MessageType.tool && m.text.trim().isNotEmpty) {
      final String d =
          (m.toolDetail ?? '').isEmpty ? '' : ' ${m.toolDetail}';
      return _item(
          i,
          true,
          '[HASIL TOOL ${m.toolName ?? ''}$d]\n${m.text}\n'
          '[AKHIR HASIL TOOL]');
    }
    if (m.type == MessageType.gen && m.text.trim().isNotEmpty) {
      return _item(i, true, '[HASIL TOOL create_image]\n${m.text}');
    }
    return null;
  }

  /// Susun ChatItem (system prompt + riwayat) untuk API bawaan.
  static Future<List<ChatItem>> buildItems(List<ChatMsg> msgs) async {
    final List<ChatItem> items = <ChatItem>[
      ChatItem(
        content: systemPrompt(),
        time: 0,
        type: ChatType.system.index,
        status: MessageStatus.success.index,
        images: <String>[],
      ),
    ];
    for (int i = 0; i < msgs.length; i++) {
      final ChatItem? it = await _fromMsg(i + 1, msgs[i]);
      if (it != null) items.add(it);
    }
    return items;
  }

  // -- Streaming ---------------------------------------------------------------

  /// Mengalirkan token balasan AI untuk riwayat [msgs].
  static Future<Stream<String>> stream(List<ChatMsg> msgs) async {
    final MuseTarget? t = resolve();
    if (t == null) {
      throw const MuseAiException(
          'Belum ada server. Tambahkan di tab Server atau lewat '
          'Custom Endpoint (Ruang Kreasi > Kelola model).');
    }
    final List<ChatItem> items = await buildItems(msgs);
    if (!items.any((ChatItem e) => e.type != ChatType.system.index)) {
      throw const MuseAiException('Tidak ada pesan untuk dikirim.');
    }
    final int code = t.bean.model ?? APIType.openAI.code;
    const Set<int> mapped = <int>{1, 2, 3, 5, 6, 7};
    final String temp = HiveBox().temperature;
    final Stream<GenerateContentBean> s;
    if (mapped.contains(code)) {
      s = await API().streamGenerateContent(
          temp, t.bean, t.model, items, <RequestParams>[], false);
    } else {
      // Tipe lain (OpenAI-compatible) memakai implementasi ChatGPT.
      final List<RequestParams> params =
          API().generateChatHistory(items, false);
      s = await ChatGPTImpl().streamGenerateContent(
          temp, t.bean, t.model, items, params, false);
    }
    return s.map((GenerateContentBean e) => e.content ?? '');
  }

  static String friendlyError(Object e) {
    if (e is MuseAiException) return e.message;
    if (e is DioException) {
      final int? code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'API key ditolak server (HTTP $code). Periksa API key.';
      }
      if (code == 404) {
        return 'Endpoint/model tidak ditemukan (HTTP 404). Periksa '
            'Base URL dan nama model.';
      }
      if (code == 429) {
        return 'Terlalu banyak permintaan / kuota habis (HTTP 429).';
      }
      return 'Koneksi gagal: ${e.message ?? e.type.name}';
    }
    final String s = e.toString();
    return s.length > 300 ? '${s.substring(0, 300)}...' : s;
  }

  // -- Penanda tool ------------------------------------------------------------

  static MuseToolCall? parseTool(String text) {
    final RegExpMatch? m = _toolRe.firstMatch(text);
    if (m == null) return null;
    return MuseToolCall(m.group(1) ?? '', (m.group(2) ?? '').trim());
  }

  /// Hapus penanda tool (lengkap maupun yang baru setengah tertulis
  /// saat streaming) dari teks yang ditampilkan.
  static String stripToolMarkers(String s) {
    String out = s.replaceAll(RegExp(r'\[\[tool:[^\]]*\]\]'), '');
    final int open = out.indexOf('[[tool:');
    if (open >= 0) out = out.substring(0, open);
    // Potongan awal "[" / "[[" / "[[to" di ujung teks.
    final RegExpMatch? tail = RegExp(r'\[{1,2}(t(o(o(l)?)?)?)?$').firstMatch(out);
    if (tail != null) out = out.substring(0, tail.start);
    return out.trimRight();
  }

  /// Hasil tool_use: daftar tool + statusnya.
  static String toolsOverview() {
    final StringBuffer b = StringBuffer();
    for (final AiTool t in kAiTools) {
      b.writeln('- ${t.id} [${_state(t.id)}]: ${t.desc}');
    }
    return b.toString().trim();
  }

  // -- Tool: gambar ---------------------------------------------------------------

  static String normalizeBase(String raw) {
    String u = raw.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (u.endsWith('/v1')) u = u.substring(0, u.length - 3);
    return u;
  }

  static Dio _dio(AllModelBean bean, {Duration? receive}) {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: receive ?? const Duration(seconds: 120),
      headers: <String, dynamic>{
        'Authorization': 'Bearer ${bean.apiKey ?? ''}',
        'Content-Type': 'application/json',
      },
    ));
  }

  /// Membuat gambar via endpoint OpenAI-compatible /v1/images/generations
  /// memakai Model Gambar Default. Mengembalikan path file lokal.
  static Future<String> generateImage(String prompt) async {
    final MuseTarget? t = resolve();
    if (t == null) {
      throw const MuseAiException('Belum ada server untuk membuat gambar.');
    }
    String model = ModelStore.defaultImage();
    if (model.isEmpty) model = 'dall-e-3';
    final String base = normalizeBase(t.bean.apiServer ?? '');
    final Dio dio = _dio(t.bean);
    final Response<dynamic> res = await dio.post<dynamic>(
      '$base/v1/images/generations',
      data: <String, dynamic>{'model': model, 'prompt': prompt, 'n': 1},
    );
    final dynamic data = res.data;
    if (data is! Map || data['data'] is! List || (data['data'] as List).isEmpty) {
      throw const MuseAiException('Server tidak mengembalikan gambar.');
    }
    final dynamic first = (data['data'] as List).first;
    final Directory dir = await getTemporaryDirectory();
    final File out = File(
        '${dir.path}/muse_${DateTime.now().millisecondsSinceEpoch}.png');
    if (first is Map && first['b64_json'] is String) {
      await out.writeAsBytes(base64Decode(first['b64_json'] as String));
    } else if (first is Map && first['url'] is String) {
      await Dio().download(first['url'] as String, out.path);
    } else {
      throw const MuseAiException('Format respons gambar tidak dikenali.');
    }
    return out.path;
  }

  // -- Tool: browsing --------------------------------------------------------------

  /// Mengambil teks sebuah halaman web (maks ±8000 karakter).
  static Future<String> browse(String url) async {
    String u = url.trim();
    if (u.isEmpty) throw const MuseAiException('URL kosong.');
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    final Dio dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.plain,
      followRedirects: true,
      maxRedirects: 5,
      headers: <String, dynamic>{
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) XDots/1.0',
        'Accept': 'text/html,application/xhtml+xml,text/plain,*/*',
      },
    ));
    final Response<String> res = await dio.get<String>(u);
    String html = res.data ?? '';
    html = html.replaceAll(
        RegExp(r'<(script|style|noscript)[\s\S]*?</\1>',
            caseSensitive: false),
        ' ');
    html = html.replaceAll(
        RegExp(r'<br\s*/?>|</p>|</div>|</li>|</h[1-6]>|</tr>',
            caseSensitive: false),
        '\n');
    html = html.replaceAll(RegExp(r'<[^>]+>'), ' ');
    html = html
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    html = html
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .trim();
    if (html.length > 8000) html = html.substring(0, 8000);
    if (html.isEmpty) return '(Halaman kosong atau tidak berisi teks.)';
    return html;
  }

  // -- Custom endpoint ---------------------------------------------------------------

  /// Mengambil daftar model dari {baseUrl}/v1/models (OpenAI-compatible).
  static Future<List<SupportedModels>> fetchModels(AllModelBean bean) async {
    final String base = normalizeBase(bean.apiServer ?? '');
    final Dio dio = _dio(bean, receive: const Duration(seconds: 30));
    final Response<dynamic> res = await dio.get<dynamic>('$base/v1/models');
    final dynamic data = res.data;
    final List<SupportedModels> out = <SupportedModels>[];
    if (data is Map && data['data'] is List) {
      for (final dynamic e in data['data'] as List) {
        if (e is Map && e['id'] is String) {
          out.add(SupportedModels(
            id: e['id'] as String,
            ownedBy: (e['owned_by'] as String?) ?? 'custom',
          ));
        }
      }
    }
    return out;
  }
}
