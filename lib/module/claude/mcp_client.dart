import 'dart:convert';

import 'package:dio/dio.dart';

class McpException implements Exception {
  final String message;
  const McpException(this.message);
  @override
  String toString() => message;
}

/// Klien MCP minimal (Streamable HTTP, JSON-RPC 2.0).
/// Dipakai untuk server MCP Exa: https://mcp.exa.ai/mcp
class McpClient {
  final String url;
  McpClient(this.url);

  String? _session;
  int _id = 0;
  bool _ready = false;

  Dio _dio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.plain,
        validateStatus: (int? s) => s != null && s < 500,
      ));

  /// Ambil pesan JSON-RPC dari respons JSON biasa atau SSE (`data: {...}`).
  Map<String, dynamic>? _parse(String raw, int id) {
    final String body = raw.trim();
    if (body.isEmpty) return null;
    if (body.startsWith('{')) {
      final dynamic j = jsonDecode(body);
      return j is Map<String, dynamic> ? j : null;
    }
    Map<String, dynamic>? last;
    for (final String line in const LineSplitter().convert(body)) {
      final String l = line.trim();
      if (!l.startsWith('data:')) continue;
      final String payload = l.substring(5).trim();
      if (payload.isEmpty || !payload.startsWith('{')) continue;
      try {
        final dynamic j = jsonDecode(payload);
        if (j is Map<String, dynamic>) {
          if (j['id'] == id) return j;
          last = j;
        }
      } catch (_) {}
    }
    return last;
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
    final Response<String> res = await _dio().post<String>(
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
    if (notify) return null;
    if ((res.statusCode ?? 500) >= 400) {
      throw McpException('MCP HTTP ${res.statusCode}');
    }
    final Map<String, dynamic>? msg = _parse(res.data ?? '', id);
    if (msg == null) throw const McpException('Respons MCP kosong');
    if (msg['error'] is Map) {
      final dynamic m = (msg['error'] as Map)['message'];
      throw McpException(m?.toString() ?? 'Error MCP');
    }
    return msg['result'];
  }

  Future<void> _init() async {
    if (_ready) return;
    try {
      await _rpc('initialize', <String, dynamic>{
        'protocolVersion': '2025-03-26',
        'capabilities': <String, dynamic>{},
        'clientInfo': <String, dynamic>{'name': 'XDots', 'version': '1.0'},
      });
      await _rpc('notifications/initialized', null, notify: true);
    } catch (_) {
      // Server stateless: langsung tools/call tetap bisa.
    }
    _ready = true;
  }

  /// Panggil tool MCP; mengembalikan gabungan teks hasilnya.
  Future<String> callTool(String name, Map<String, dynamic> args) async {
    await _init();
    final dynamic r = await _rpc('tools/call', <String, dynamic>{
      'name': name,
      'arguments': args,
    });
    final StringBuffer out = StringBuffer();
    if (r is Map && r['content'] is List) {
      for (final dynamic c in r['content'] as List) {
        if (c is Map && c['text'] is String) {
          out.writeln(c['text'] as String);
        }
      }
    }
    final String text = out.toString().trim();
    if (r is Map && r['isError'] == true) {
      throw McpException(text.isEmpty ? 'Tool MCP gagal' : text);
    }
    if (text.isEmpty) return '(Tool tidak mengembalikan teks.)';
    return text.length > 8000 ? text.substring(0, 8000) : text;
  }
}
