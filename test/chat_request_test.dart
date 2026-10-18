import 'package:chat_bot/base/db/chat_item.dart';
import 'package:chat_bot/module/claude/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

ChatItem item(ChatType type, String content,
        {MessageStatus status = MessageStatus.success, List<String>? images}) =>
    ChatItem(
        content: content,
        time: 0,
        type: type.index,
        status: status.index,
        images: images ?? []);

void main() {
  test('OpenAI request retains system role and original message ordering', () {
    final messages = MuseAi.openAiMessages([
      item(ChatType.system, 'System instruction'),
      item(ChatType.user, 'User instruction'),
      item(ChatType.bot, 'Assistant response'),
      item(ChatType.user, 'Follow-up'),
    ]);
    expect(messages.map((m) => m['role']),
        ['system', 'user', 'assistant', 'user']);
    expect(messages.first['content'], 'System instruction');
    expect(messages[1]['content'], 'User instruction');
  });

  test('OpenAI request preserves actual multimodal image payload', () {
    final messages = MuseAi.openAiMessages([
      item(ChatType.user, 'Read image', images: ['iVBORtest']),
    ]);
    final content = messages.single['content'] as List;
    expect(content.first['text'], 'Read image');
    expect(content[1]['image_url']['url'], 'data:image/png;base64,iVBORtest');
  });

  test('OpenAI request omits empty, canceled and failed history items', () {
    final messages = MuseAi.openAiMessages([
      item(ChatType.user, ''),
      item(ChatType.bot, 'Failed', status: MessageStatus.failed),
      item(ChatType.bot, 'Canceled', status: MessageStatus.canceled),
      item(ChatType.user, 'Kept'),
    ]);
    expect(messages.length, 1);
    expect(messages.single['content'], 'Kept');
  });
}
