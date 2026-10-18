import 'package:chat_bot/module/claude/widgets/agent_avatar.dart';
import 'package:chat_bot/module/claude/widgets/bubble.dart';
import 'package:chat_bot/module/claude/widgets/header_pill.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AgentAvatar exposes each activity accessibly',
      (WidgetTester tester) async {
    for (final AgentActivity activity in AgentActivity.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: AgentAvatar(activity: activity, size: 44)),
          ),
        ),
      );
      expect(find.byType(AgentAvatar), findsOneWidget);
      expect(find.bySemanticsLabel(_avatarLabel(activity)), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
    }
  });

  testWidgets('MuseHeader wires runtime activity and statusLabel',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MuseHeader(
            activity: AgentActivity.approval,
            status: 'Legacy status',
            statusLabel: 'Waiting for approval',
          ),
        ),
      ),
    );

    expect(find.byType(AgentAvatar), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Legacy status'), findsNothing);
  });

  testWidgets('delete popup has only a real action and confirms deletion',
      (WidgetTester tester) async {
    bool deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MuseHeader(onDeleteMessages: () => deleted = true),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MoreDotsVectorIcon));
    await tester.pumpAndSettle();
    expect(find.text('Hapus semua pesan'), findsOneWidget);
    expect(find.textContaining('Tools Calls'), findsNothing);
    await tester.tap(find.text('Hapus semua pesan'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('TypingBubble is announced once and settles with reduced motion',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: TypingBubble()),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Assistant is typing'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

String _avatarLabel(AgentActivity activity) => switch (activity) {
      AgentActivity.idle => 'Assistant ready',
      AgentActivity.thinking => 'Assistant thinking',
      AgentActivity.browsing => 'Assistant browsing',
      AgentActivity.tool => 'Assistant using a tool',
      AgentActivity.approval => 'Assistant awaiting approval',
      AgentActivity.error => 'Assistant encountered an error',
    };
