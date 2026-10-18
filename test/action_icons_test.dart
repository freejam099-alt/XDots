import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_bot/module/claude/widgets/action_icons.dart';

void main() {
  testWidgets('all action icon kinds render at the compact default size',
      (WidgetTester tester) async {
    for (final ActionIconKind kind in ActionIconKind.values) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ActionVectorIcon(kind: kind))),
      );

      final Finder iconPaint = find.byWidgetPredicate(
        (Widget widget) =>
            widget is CustomPaint && widget.size == const Size.square(18),
      );
      expect(iconPaint, findsOneWidget, reason: '$kind');
      expect(tester.widget<CustomPaint>(iconPaint).size, const Size.square(18),
          reason: '$kind');
    }
  });

  testWidgets('custom size and tint are accepted', (WidgetTester tester) async {
    const Color tint = Color(0xff123456);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActionVectorIcon(
              kind: ActionIconKind.delete, size: 22, color: tint),
        ),
      ),
    );

    final Finder iconPaint = find.byWidgetPredicate(
      (Widget widget) =>
          widget is CustomPaint && widget.size == const Size.square(22),
    );
    final CustomPaint paint = tester.widget(iconPaint);
    expect(paint.size, const Size.square(22));
    expect(paint.painter, isNotNull);
  });
}
