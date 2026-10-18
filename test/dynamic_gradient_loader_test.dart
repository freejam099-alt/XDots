import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/dynamic_gradient_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required bool reducedMotion, bool tickerEnabled = true}) =>
    MaterialApp(
      theme: ThemeData(
          platform: TargetPlatform.android,
          extensions: const [AppColors.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: TickerMode(enabled: tickerEnabled, child: child!),
      ),
      home: const Scaffold(
        body: MuseDynamicGradientLoader(
          width: 120,
          height: 36,
          child: Center(child: Text('Memuat')),
        ),
      ),
    );

LinearGradient _gradient(WidgetTester tester) {
  final BoxDecoration decoration = tester
      .widget<Container>(find.descendant(
          of: find.byType(MuseDynamicGradientLoader),
          matching: find.byType(Container)))
      .decoration! as BoxDecoration;
  return decoration.gradient! as LinearGradient;
}

void main() {
  testWidgets('Cupertino-style loader gradient animates on Android',
      (tester) async {
    await tester.pumpWidget(_host(reducedMotion: false));
    final AlignmentGeometry before = _gradient(tester).begin;
    await tester.pump(const Duration(milliseconds: 450));
    final AlignmentGeometry after = _gradient(tester).begin;

    expect(after, isNot(before));
    expect(find.text('Memuat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loader remains static with reduced motion enabled',
      (tester) async {
    await tester.pumpWidget(_host(reducedMotion: true));
    final AlignmentGeometry before = _gradient(tester).begin;
    await tester.pump(const Duration(milliseconds: 450));

    expect(_gradient(tester).begin, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loader pauses when its subtree is not ticker-enabled',
      (tester) async {
    await tester.pumpWidget(_host(reducedMotion: false, tickerEnabled: false));
    final AlignmentGeometry before = _gradient(tester).begin;
    await tester.pump(const Duration(milliseconds: 450));

    expect(_gradient(tester).begin, before);
    expect(tester.takeException(), isNull);
  });
}
