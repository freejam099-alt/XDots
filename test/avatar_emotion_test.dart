import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:chat_bot/module/claude/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('frustrated and crying render distinct deterministic pixels',
      (WidgetTester tester) async {
    final Uint8List frustrated = await _renderAvatar(
      tester,
      AgentActivity.frustrated,
      reducedMotion: true,
    );
    final Uint8List crying = await _renderAvatar(
      tester,
      AgentActivity.crying,
      reducedMotion: true,
    );

    expect(frustrated, isNot(equals(crying)));
  });

  testWidgets('frustrated and crying both animate when motion is allowed',
      (WidgetTester tester) async {
    for (final AgentActivity activity in <AgentActivity>[
      AgentActivity.frustrated,
      AgentActivity.crying,
    ]) {
      await _mountAvatar(tester, activity);
      final Uint8List before = await _captureAvatar(tester);
      await tester.pump(const Duration(milliseconds: 500));
      final Uint8List after = await _captureAvatar(tester);
      expect(after, isNot(equals(before)), reason: '$activity should animate');
    }
  });

  testWidgets('reduced motion keeps emotional avatars pixel-identical',
      (WidgetTester tester) async {
    for (final AgentActivity activity in <AgentActivity>[
      AgentActivity.frustrated,
      AgentActivity.crying,
    ]) {
      await _mountAvatar(tester, activity, reducedMotion: true);
      final Uint8List before = await _captureAvatar(tester);
      await tester.pump(const Duration(seconds: 2));
      final Uint8List after = await _captureAvatar(tester);
      expect(after, equals(before), reason: '$activity should be still');
      await tester.pumpAndSettle();
    }
  });

  testWidgets('disabled TickerMode keeps emotional avatars pixel-identical',
      (WidgetTester tester) async {
    for (final AgentActivity activity in <AgentActivity>[
      AgentActivity.frustrated,
      AgentActivity.crying,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: TickerMode(
            enabled: false,
            child: Scaffold(
              body: Center(child: AgentAvatar(activity: activity)),
            ),
          ),
        ),
      );
      final Uint8List before = await _captureAvatar(tester);
      await tester.pump(const Duration(seconds: 2));
      final Uint8List after = await _captureAvatar(tester);
      expect(after, equals(before), reason: '$activity should be still');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _mountAvatar(
  WidgetTester tester,
  AgentActivity activity, {
  bool reducedMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Scaffold(
          body: Center(child: AgentAvatar(activity: activity)),
        ),
      ),
    ),
  );
}

Future<Uint8List> _renderAvatar(
  WidgetTester tester,
  AgentActivity activity, {
  required bool reducedMotion,
}) async {
  await _mountAvatar(tester, activity, reducedMotion: reducedMotion);
  return _captureAvatar(tester);
}

Future<Uint8List> _captureAvatar(WidgetTester tester) async {
  final Finder boundary = find.descendant(
    of: find.byType(AgentAvatar),
    matching: find.byType(RepaintBoundary),
  );
  final RenderRepaintBoundary renderBoundary =
      tester.renderObject<RenderRepaintBoundary>(boundary);
  final image = await renderBoundary.toImage(pixelRatio: 1);
  try {
    final ByteData? data = await tester.runAsync<ByteData?>(
      () => image.toByteData(format: ImageByteFormat.rawRgba),
    );
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
