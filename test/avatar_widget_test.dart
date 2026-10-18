import 'package:chat_bot/module/claude/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('defaults to exactly ten percent larger than 48.4',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
            body: Center(child: AgentAvatar(activity: AgentActivity.idle))),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(AgentAvatar));
    expect(box.size.width, closeTo(48.4 * 1.1, 0.000001));
    expect(box.size.height, closeTo(53.24, 0.000001));
    final Finder avatar = find.byType(AgentAvatar);
    expect(
      find.descendant(of: avatar, matching: find.byType(RepaintBoundary)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: avatar, matching: find.byType(CustomPaint)),
      findsOneWidget,
    );
  });

  testWidgets('only announces the activity supplied by its caller',
      (WidgetTester tester) async {
    for (final AgentActivity activity in AgentActivity.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: AgentAvatar(activity: activity, size: 44)),
          ),
        ),
      );
      expect(find.bySemanticsLabel(_label(activity)), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 40));
    }
  });

  testWidgets('ticker repaint is isolated and painter survives animation ticks',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
            body: Center(child: AgentAvatar(activity: AgentActivity.tool))),
      ),
    );
    final Finder avatarPaint = find.descendant(
      of: find.byType(AgentAvatar),
      matching: find.byType(CustomPaint),
    );
    final CustomPaint before = tester.widget<CustomPaint>(avatarPaint);
    await tester.pump(const Duration(milliseconds: 80));
    final CustomPaint after = tester.widget<CustomPaint>(avatarPaint);

    expect(identical(before.painter, after.painter), isTrue);
    expect(
      find.descendant(
        of: find.byType(AgentAvatar),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion and disabled TickerMode remain settled',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: AgentAvatar(activity: AgentActivity.thinking)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const MaterialApp(
        home: TickerMode(
          enabled: false,
          child: Scaffold(body: AgentAvatar(activity: AgentActivity.browsing)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

String _label(AgentActivity activity) => switch (activity) {
      AgentActivity.idle => 'Assistant ready',
      AgentActivity.thinking => 'Assistant thinking',
      AgentActivity.browsing => 'Assistant browsing',
      AgentActivity.tool => 'Assistant using a tool',
      AgentActivity.approval => 'Assistant awaiting approval',
      AgentActivity.error => 'Assistant encountered an error',
      AgentActivity.frustrated => 'Assistant frustrated by a temporary failure',
      AgentActivity.crying => 'Assistant crying after a failed request',
    };
