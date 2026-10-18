import 'dart:convert';

import 'package:chat_bot/module/claude/chat_data.dart';
import 'package:chat_bot/module/claude/model_store.dart';
import 'package:chat_bot/utils/sp_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'history survives send, new session, reopen, continue, delete and repair',
      () async {
    const ChatMsg firstMessage = ChatMsg(
      isUser: true,
      type: MessageType.text,
      text: 'first prompt',
    );
    final String malformedRecordRaw = jsonEncode(<Object>[
      <String, Object?>{
        'id': 'active-session',
        'title': 'Existing chat',
        'time': 1e300,
        'messages': <Object>[
          firstMessage.toJson(),
          <String, Object?>{'isUser': 'not-a-bool', 'text': 42},
        ],
      },
      <String, Object?>{
        'id': 'broken-session',
        'title': 'Broken',
        'time': 101,
        'messages': 'not-a-list',
      },
      'not a session map',
    ]);
    SharedPreferences.setMockInitialValues(<String, Object>{
      ModelStore.kSessions: malformedRecordRaw,
    });
    await SpUtil.getInstance();
    ModelStore.resetSessionStateForTesting();

    // One corrupt record/message does not hide other recoverable conversation data.
    expect(
        ModelStore.sessions().map((s) => s['id']), <String>['active-session']);
    expect(ModelStore.sessions().single['time'], 0);
    expect(
        () => DateTime.fromMillisecondsSinceEpoch(
            ModelStore.sessions().single['time'] as int),
        returnsNormally);
    expect(ModelStore.loadSession('active-session').map((m) => m.text),
        <String>['first prompt']);

    // Sending to the restored active history updates its original identity.
    final List<ChatMsg> sentMessages = <ChatMsg>[
      ...ModelStore.loadSession('active-session'),
      const ChatMsg(isUser: true, type: MessageType.text, text: 'follow-up'),
    ];
    final String activeId = ModelStore.saveSession(
      'Existing chat',
      sentMessages,
      id: 'active-session',
    );
    expect(activeId, 'active-session');

    // Starting a new chat allocates a separate stable identity.
    final String newId = ModelStore.saveSession('new prompt', const <ChatMsg>[
      ChatMsg(isUser: true, type: MessageType.text, text: 'new prompt'),
    ]);
    expect(newId, isNot(activeId));
    await ModelStore.flushSessionWrites();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getString(ModelStore.kCorruptSessionsBackup), malformedRecordRaw);
    expect(
        ModelStore.sessions().map((s) => s['id']), <String>[newId, activeId]);

    // Force a disk read as if the app had been reopened; continuing the old
    // history with its id updates it rather than creating a duplicate.
    ModelStore.resetSessionStateForTesting();
    expect(ModelStore.loadSession(activeId).map((m) => m.text),
        <String>['first prompt', 'follow-up']);
    final String continuedId = ModelStore.saveSession(
      'Existing chat continued',
      <ChatMsg>[
        ...ModelStore.loadSession(activeId),
        const ChatMsg(isUser: false, type: MessageType.text, text: 'answer'),
      ],
      id: activeId,
    );
    expect(continuedId, activeId);
    await ModelStore.flushSessionWrites();
    expect(
        ModelStore.sessions().where((s) => s['id'] == activeId), hasLength(1));

    ModelStore.deleteSession(newId);
    await ModelStore.flushSessionWrites();
    ModelStore.resetSessionStateForTesting();
    expect(ModelStore.sessions().map((s) => s['id']), <String>[activeId]);

    // Invalid JSON used to permanently disable session writes. Preserve the raw
    // value in a backup and recover into a writable session store instead.
    const String malformedRaw = '{not valid json';
    await prefs.setString(ModelStore.kSessions, malformedRaw);
    ModelStore.resetSessionStateForTesting();
    expect(ModelStore.sessions(), isEmpty);
    final String recoveredId = ModelStore.saveSession('recovered', <ChatMsg>[
      const ChatMsg(isUser: true, type: MessageType.text, text: 'recovered'),
    ]);
    await ModelStore.flushSessionWrites();
    expect(prefs.getString(ModelStore.kCorruptSessionsBackup), malformedRaw);
    ModelStore.resetSessionStateForTesting();
    expect(ModelStore.loadSession(recoveredId).single.text, 'recovered');
  });
}
