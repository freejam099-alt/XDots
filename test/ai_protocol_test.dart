import 'dart:convert';

import 'package:chat_bot/module/claude/ai_service.dart';
import 'package:chat_bot/module/claude/dot_browser.dart';
import 'package:chat_bot/module/claude/mcp_client.dart';
import 'package:chat_bot/module/claude/model_store.dart';
import 'package:chat_bot/utils/sp_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MCP JSON-RPC response correlation', () {
    test('accepts only a JSON response with matching id', () {
      final Map<String, dynamic>? response = McpClient.parseResponse(
        jsonEncode(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': 7,
          'result': <String, dynamic>{'ok': true},
        }),
        7,
      );

      expect(response?['id'], 7);
      expect(
          McpClient.parseResponse(
            jsonEncode(<String, dynamic>{
              'jsonrpc': '2.0',
              'id': 8,
              'result': 'unrelated',
            }),
            7,
          ),
          isNull);
    });

    test('selects matching SSE event and rejects unrelated events', () {
      final String sse = [
        'event: message',
        'data: ${jsonEncode(<String, dynamic>{
              'jsonrpc': '2.0',
              'id': 2,
              'result': 'old'
            })}',
        '',
        'data: ${jsonEncode(<String, dynamic>{
              'jsonrpc': '2.0',
              'id': 3,
              'result': 'right'
            })}',
      ].join('\n');

      expect(McpClient.parseResponse(sse, 3)?['result'], 'right');
      expect(McpClient.parseResponse(sse, 4), isNull);
    });
  });

  group('OpenAI-compatible SSE payloads', () {
    test('extracts delta content and ignores done/empty frames', () {
      expect(
        MuseAi.parseOpenAiSseData('{"choices":[{"delta":{"content":"Halo"}}]}'),
        'Halo',
      );
      expect(MuseAi.parseOpenAiSseData('[DONE]'), isNull);
      expect(MuseAi.parseOpenAiSseData(''), isNull);
      expect(MuseAi.parseOpenAiSseData('not-json'), isNull);
    });

    test('redacts a credential echoed in an SSE error', () {
      expect(
        () => MuseAi.parseOpenAiSseData(
          '{"error":{"message":"invalid secret-value"}}',
          secret: 'secret-value',
        ),
        throwsA(isA<MuseAiException>().having(
          (MuseAiException error) => error.message,
          'message',
          isNot(contains('secret-value')),
        )),
      );
    });
  });

  group('tool marker parsing', () {
    test('parses a supported terminal marker and image ratio', () {
      final MuseToolCall? call = MuseAi.parseTool(
          'Saya akan membuatnya.\n[[tool:create_image|a cat|16:9]]');

      expect(call?.name, 'create_image');
      expect(call?.arg, 'a cat');
      expect(call?.ratio, '16:9');
    });

    test('does not execute markers in code, mid-answer, or unknown tools', () {
      expect(MuseAi.parseTool('[[tool:tools_use]]\npenjelasan setelahnya'),
          isNull);
      expect(MuseAi.parseTool('```text\n[[tool:tools_use]]\n```'), isNull);
      expect(MuseAi.parseTool('[[tool:delete_everything]]'), isNull);
    });

    test('strips complete and partial streamed markers from display text', () {
      expect(MuseAi.stripToolMarkers('Jawaban\n[[tool:tools_use]]'), 'Jawaban');
      expect(MuseAi.stripToolMarkers('Jawaban\n[[to'), 'Jawaban');
      expect(MuseAi.stripToolMarkers('Contoh [[tool:tools_use]]'),
          'Contoh [[tool:tools_use]]');
      expect(MuseAi.stripToolMarkers('```text\n[[tool:tools_use]]\n```'),
          '```text\n[[tool:tools_use]]\n```');
    });
  });

  test('classifies explicit Dot Browser topics without making requests', () {
    expect(
        DotBrowser.classify('rain in Bandung', 'general'), DotIntent.general);
    expect(DotBrowser.classify('rain in Bandung', null), DotIntent.weather);
    expect(DotBrowser.classify('anything', 'encyclopedia'),
        DotIntent.encyclopedia);
  });

  test('normalizes OpenAI-compatible base URLs', () {
    expect(MuseAi.normalizeBase(' https://example.test/v1/ '),
        'https://example.test');
    expect(MuseAi.normalizeBase('api.example.test/v1'),
        'https://api.example.test');
  });

  test('serializes concurrent session mutations before persistence', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SpUtil.getInstance();

    final String first = ModelStore.saveSession('first', const []);
    final String second = ModelStore.saveSession('second', const []);
    ModelStore.deleteSession(first);
    await ModelStore.flushSessionWrites();

    expect(ModelStore.sessions().map((Map<String, dynamic> s) => s['id']),
        <String>[second]);
  });
}
