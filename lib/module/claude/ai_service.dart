import 'dart:convert';
import 'dart:io';

import 'package:chat_bot/base/api.dart';
import 'package:chat_bot/base/api_impl/chatgpt_impl.dart';
import 'package:chat_bot/base/db/chat_item.dart' hide MessageType;
import 'package:chat_bot/const.dart';
import 'package:chat_bot/hive_bean/generate_content.dart';
import 'package:chat_bot/hive_bean/local_chat_history.dart';
import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'chat_data.dart';
import 'mcp_client.dart';
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

  /// MCP Exa aktif bila tool mcp_exa DAN server MCP Exa sama-sama aktif.
  static bool exaOn() =>
      ModelStore.toolEnabled('mcp_exa') &&
      ModelStore.mcpEnabled('exa', defValue: true);

  static String _exaState() => exaOn() ? 'AKTIF' : 'NONAKTIF';

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
    b.writeln('- Ruang Kreasi (tab bohlam): memilih Model Chat/Gambar/Video '
        'default (model hasil fetch dipilah otomatis) dan mengatur tools.');
    b.writeln('- Server: menambah provider (OpenAI-compatible, Gemini, '
        'Ollama, DeepSeek, dll). Di bawahnya ada kartu MCP (Exa), '
        'Browsing (layanan pencarian), dan Custom Endpoint (nama '
        'provider, Base URL tanpa /v1, API Key sendiri).');
    b.writeln();
    b.writeln('TOOLS. Untuk memakai tool, tulis PERSIS satu baris penanda '
        'di akhir jawabanmu (bukan di dalam blok kode). Aplikasi akan '
        'menjalankannya; hasilnya dikirim kembali kepadamu sebagai pesan '
        'berawalan [HASIL TOOL].');
    b.writeln('- create_image [${_state('create_image')}]: membuat gambar '
        'memakai Model Gambar Default. Format: '
        '[[tool:create_image|prompt gambar terperinci, bahasa Inggris]]');
    b.writeln('- create_video [${_state('create_video')}]: membuat video '
        'memakai Model Video Default (butuh server yang mendukung API '
        'video; bila gagal, jelaskan penyebabnya ke pengguna). Format: '
        '[[tool:create_video|prompt video terperinci, bahasa Inggris]]');
    b.writeln('- web_search_exa [${_exaState()}] (MCP Exa): mencari '
        'informasi terbaru di web. Format: '
        '[[tool:web_search_exa|kata kunci pencarian]]');
    b.writeln('- web_fetch_exa [${_exaState()}] (MCP Exa): membaca isi '
        'halaman web dari URL. Format: '
        '[[tool:web_fetch_exa|https://alamat.lengkap]]');
    b.writeln('- tools_use [${_state('tools_use')}]: melihat daftar tool '
        'yang tersedia beserta statusnya. Format: [[tool:tools_use]]');
    b.writeln();
    b.writeln('ATURAN TOOL: pakai tool hanya bila diminta atau memang '
        'perlu (misal info terbaru, berita, atau isi sebuah URL); '
        'maksimal satu tool per giliran; jangan mengarang hasil tool; '
        'kalau tool NONAKTIF, beri tahu pengguna agar mengaktifkannya '
        '(tool di Ruang Kreasi, MCP di tab Server). Setelah menerima '
        '[HASIL TOOL], jawab pengguna memakai hasil itu dan sebutkan '
        'sumbernya bila ada, tanpa memanggil tool yang sama berulang.');
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

  /// Hasil tools_use: daftar tool + statusnya.
  static String toolsOverview() {
    final StringBuffer b = StringBuffer();
    b.writeln('- create_image [${_state('create_image')}]: membuat gambar');
    b.writeln('- create_video [${_state('create_video')}]: membuat video');
    b.writeln('- web_search_exa [${_exaState()}]: cari di web (MCP Exa)');
    b.writeln('- web_fetch_exa [${_exaState()}]: baca isi URL (MCP Exa)');
    b.writeln('- tools_use [${_state('tools_use')}]: daftar tool ini');
    return b.toString().trim();
  }

  // -- MCP Exa -----------------------------------------------------------------

  static final McpClient _exa = McpClient('https://mcp.exa.ai/mcp');

  /// Jalankan tool Exa: web_search_exa (query) / web_fetch_exa (url).
  static Future<String> exaCall(String tool, String arg) async {
    if (arg.trim().isEmpty) throw const MuseAiException('Argumen tool kosong.');
    if (tool == 'web_search_exa') {
      return _exa.callTool(
          tool, <String, dynamic>{'query': arg.trim(), 'numResults': 5});
    }
    try {
      return await _exa.callTool(tool, <String, dynamic>{
        'urls': <String>[arg.trim()],
      });
    } catch (_) {
      return _exa.callTool(tool, <String, dynamic>{'url': arg.trim()});
    }
  }

  // -- Klasifikasi model hasil fetch -----------------------------------------------

  /// 0 = chat, 1 = gambar, 2 = video, 3 = lain (embedding/suara/dll).
  static int kindOf(String id) {
    final String s = id.toLowerCase();
    if (RegExp(r'(video|sora|kling|seedance|hailuo|runway|cogvideo|i2v|t2v|'
                r'(^|[/\-_.])(wan|veo|vidu|ltx|luma|pika)[\d\-_.]?)')
            .hasMatch(s) &&
        !s.contains('wanx2.1-t2i')) {
      return 2;
    }
    if (RegExp(r'(image|dall-e|dalle|imagen|flux|sdxl|stable-diffusion|'
                r'midjourney|cogview|seedream|recraft|ideogram|t2i|wanx)')
            .hasMatch(s) ||
        paintModelKeys.contains(id)) {
      return 1;
    }
    if (RegExp(r'(embed|tts|whisper|moderation|rerank|speech|asr|'
                r'transcrib|realtime|audio)')
            .hasMatch(s)) {
      return 3;
    }
    return 0;
  }

  // -- Judul otomatis ------------------------------------------------------------------

  /// Judul singkat dari pertukaran pertama; null bila gagal.
  static Future<String?> generateTitle(List<ChatMsg> msgs) async {
    final MuseTarget? t = resolve();
    if (t == null) return null;
    String? user;
    String? ai;
    for (final ChatMsg m in msgs) {
      if (m.type != MessageType.text || m.text.trim().isEmpty) continue;
      if (m.isUser) {
        user ??= m.text;
      } else {
        ai ??= m.text;
      }
    }
    if (user == null || ai == null) return null;
    String clip(String x) => x.length > 600 ? x.substring(0, 600) : x;
    final List<ChatItem> items = <ChatItem>[
      _item(1, true, clip(user)),
      _item(2, false, clip(ai)),
    ];
    try {
      final String raw = await API()
          .generateChatTitle(HiveBox().temperature, t.bean, t.model, items,
              <RequestParams>[])
          .timeout(const Duration(seconds: 25));
      String title = raw
          .replaceAll(RegExp(r'["`*#]'), '')
          .replaceAll('\n', ' ')
          .trim();
      if (title.isEmpty) return null;
      if (title.length > 40) title = '${title.substring(0, 40)}...';
      return title;
    } catch (_) {
      return null;
    }
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

  // -- Tool: video ------------------------------------------------------------------

  static String? _pickId(dynamic m) {
    if (m is Map) {
      for (final String k in <String>['id', 'task_id', 'video_id']) {
        if (m[k] is String && (m[k] as String).isNotEmpty) {
          return m[k] as String;
        }
      }
      if (m['data'] is Map) return _pickId(m['data']);
      if (m['data'] is List && (m['data'] as List).isNotEmpty) {
        return _pickId((m['data'] as List).first);
      }
    }
    return null;
  }

  static String? _pickVideoUrl(dynamic m, [int depth = 0]) {
    if (depth > 3) return null;
    if (m is Map) {
      for (final String k in <String>[
        'video_url', 'download_url', 'output_url', 'result_url', 'url'
      ]) {
        final dynamic v = m[k];
        if (v is String && v.startsWith('http')) return v;
      }
      for (final dynamic v in m.values) {
        final String? r = _pickVideoUrl(v, depth + 1);
        if (r != null) return r;
      }
    } else if (m is List) {
      for (final dynamic v in m) {
        final String? r = _pickVideoUrl(v, depth + 1);
        if (r != null) return r;
      }
    }
    return null;
  }

  /// Membuat video (best-effort, API video gaya OpenAI /v1/videos lalu
  /// /v1/video/generations). Mengembalikan URL atau path file lokal.
  static Future<String> generateVideo(String prompt) async {
    final MuseTarget? t = resolve();
    if (t == null) {
      throw const MuseAiException('Belum ada server untuk membuat video.');
    }
    final String model = ModelStore.defaultVideo();
    if (model.isEmpty) {
      throw const MuseAiException(
          'Model Video Default belum dipilih (tab Ruang Kreasi).');
    }
    final String base = normalizeBase(t.bean.apiServer ?? '');
    final Dio dio = _dio(t.bean, receive: const Duration(seconds: 60));
    String root = '/v1/videos';
    dynamic created;
    try {
      created = (await dio.post<dynamic>('$base$root',
              data: <String, dynamic>{'model': model, 'prompt': prompt}))
          .data;
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        root = '/v1/video/generations';
        created = (await dio.post<dynamic>('$base$root',
                data: <String, dynamic>{'model': model, 'prompt': prompt}))
            .data;
      } else {
        rethrow;
      }
    }
    String? url = _pickVideoUrl(created);
    final String? id = _pickId(created);
    if (url == null && id == null) {
      throw const MuseAiException('Respons video tidak dikenali server.');
    }
    for (int i = 0; url == null && i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final dynamic r = (await dio.get<dynamic>('$base$root/$id')).data;
      url = _pickVideoUrl(r);
      if (url != null) break;
      final String st = (r is Map
              ? (r['status'] ?? r['state'] ?? r['task_status'] ?? '')
              : '')
          .toString()
          .toLowerCase();
      if (<String>['failed', 'error', 'cancelled', 'canceled'].contains(st)) {
        throw MuseAiException('Pembuatan video gagal ($st).');
      }
      if (<String>['completed', 'succeeded', 'success', 'done']
          .contains(st)) {
        final Directory dir = await getTemporaryDirectory();
        final String out =
            '${dir.path}/muse_${DateTime.now().millisecondsSinceEpoch}.mp4';
        await dio.download('$base$root/$id/content', out);
        return out;
      }
    }
    if (url == null) {
      throw const MuseAiException('Pembuatan video terlalu lama (timeout).');
    }
    return url;
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
