import 'dart:convert';

import 'package:dio/dio.dart';

class McpException implements Exception {
  final String message;
  const McpException(this.message);
  @override
  String toString() => message;
}

/// Satu tool yang diiklankan server lewat `tools/list`.
class McpToolInfo {
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  const McpToolInfo({
    required this.name,
    this.description,
    this.inputSchema = const <String, dynamic>{},
  });

  factory McpToolInfo.fromJson(Map<String, dynamic> json) {
    final dynamic schema = json['inputSchema'];
    return McpToolInfo(
      name: json['name'] as String,
      description: json['description'] as String?,
      inputSchema: schema is Map
          ? Map<String, dynamic>.from(schema)
          : <String, dynamic>{},
    );
  }

  /// Nama properti teks yang disarankan skema tool.
  List<String> get textProperties {
    final dynamic props = inputSchema['properties'];
    if (props is! Map) return const <String>[];
    final List<String> out = <String>[];
    props.forEach((dynamic key, dynamic value) {
      final Map<String, dynamic>? def = value is Map
          ? Map<String, dynamic>.from(value)
          : null;
      final String type = (def?['type'] ?? 'string').toString();
      if (type == 'string' || def == null || def['type'] == null) {
        out.add(key.toString());
      }
    });
    return out;
  }
}

/// Klien MCP minimal (Streamable HTTP, JSON-RPC 2.0).
/// Dipakai untuk Exa dan server MCP kustom apa pun yang punya endpoint HTTP.
class McpClient {
  final String url;
  final Dio _client;
  McpClient(this.url, {Dio? dio})
      : _client = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              responseType: ResponseType.plain,
              validateStatus: (int? s) => s != null && s < 500,
            ));

  String? _session;
  int _id = 0;
  bool _ready = false;
  Future<void>? _initialization;

  /// Ambil pesan JSON-RPC dari respons JSON biasa atau SSE (`data: {...}`).
  static Map<String, dynamic>? parseResponse(String raw, int id) {
    final String body = raw.trim();
    if (body.isEmpty) return null;
    if (body.startsWith('{')) {
      try {
        final dynamic j = jsonDecode(body);
        if (j is Map && j['jsonrpc'] == '2.0' && j['id'] == id) {
          return Map<String, dynamic>.from(j);
        }
      } catch (_) {}
      return null;
    }
    for (final String line in const LineSplitter().convert(body)) {
      final String l = line.trim();
      if (!l.startsWith('data:')) continue;
      final String payload = l.substring(5).trim();
      if (payload.isEmpty || !payload.startsWith('{')) continue;
      try {
        final dynamic j = jsonDecode(payload);
        if (j is Map && j['jsonrpc'] == '2.0' && j['id'] == id) {
          return Map<String, dynamic>.from(j);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<dynamic> _rpc(String method, Map<String, dynamic>? params,
      {bool notify = false}) async {
    final int id = notify ? 0 : ++_id;
    final Map<String, dynamic> payload = <String, dynamic>{
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
      if (!notify) 'id': id,
    };
    final Response<String> res = await _client.post<String>(
      url,
      data: jsonEncode(payload),
      options: Options(headers: <String, dynamic>{
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
        if (_session != null) 'Mcp-Session-Id': _session,
      }),
    );
    final String? sid = res.headers.value('mcp-session-id');
    if (sid != null && sid.isNotEmpty) _session = sid;
    if ((res.statusCode ?? 500) >= 400) {
      throw McpException('MCP HTTP ${res.statusCode}');
    }
    if (notify) return null;
    final Map<String, dynamic>? msg = parseResponse(res.data ?? '', id);
    if (msg == null) throw const McpException('Respons MCP kosong');
    if (msg['error'] is Map) {
      final dynamic m = (msg['error'] as Map)['message'];
      throw McpException(m?.toString() ?? 'Error MCP');
    }
    return msg['result'];
  }

  Future<void> _init() {
    if (_ready) return Future<void>.value();
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    final dynamic initialized = await _rpc('initialize', <String, dynamic>{
      'protocolVersion': '2025-03-26',
      'capabilities': <String, dynamic>{},
      'clientInfo': <String, dynamic>{'name': 'XDots', 'version': '1.0'},
    });
    if (initialized is! Map) {
      throw const McpException('Respons initialize MCP tidak valid');
    }
    await _rpc('notifications/initialized', null, notify: true);
    _ready = true;
  }

  /// Daftar tool yang tersedia di server ini (JSON-RPC `tools/list`).
  Future<List<McpToolInfo>> listTools() async {
    await _init();
    final dynamic r = await _rpc('tools/list', const <String, dynamic>{});
    if (r is! Map || r['tools'] is! List) return const <McpToolInfo>[];
    final List<McpToolInfo> out = <McpToolInfo>[];
    for (final dynamic t in r['tools'] as List) {
      if (t is Map && t['name'] is String) {
        out.add(McpToolInfo.fromJson(Map<String, dynamic>.from(t)));
      }
    }
    return out;
  }

  /// Panggil tool MCP; mengembalikan gabungan teks hasilnya.
  Future<String> callTool(String name, Map<String, dynamic> args) async {
    await _init();
    final dynamic r = await _rpc('tools/call', <String, dynamic>{
      'name': name,
      'arguments': args,
    });
    if (r is! Map || r['content'] is! List) {
      throw const McpException('Respons tools/call MCP tidak valid');
    }
    final StringBuffer out = StringBuffer();
    for (final dynamic c in r['content'] as List) {
      if (c is Map && c['text'] is String) {
        out.writeln(c['text'] as String);
      }
    }
    final String text = out.toString().trim();
    if (r['isError'] == true) {
      throw McpException(text.isEmpty ? 'Tool MCP gagal' : text);
    }
    if (text.isEmpty) return '(Tool tidak mengembalikan teks.)';
    return text.length > 8000 ? text.substring(0, 8000) : text;
  }
}
