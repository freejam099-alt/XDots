import 'package:chat_bot/module/claude/widgets/agent_avatar.dart';
import 'package:chat_bot/module/claude/widgets/header_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('responsive header avatar is ten percent larger than old header',
      (tester) async {
    for (final width in <double>[320, 390, 600]) {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
                child: SizedBox(width: width, child: const MuseHeader())),
          ),
        ),
      ));
      final avatar = tester.widget<AgentAvatar>(find.byType(AgentAvatar));
      final oldResponsiveSize = (width * 0.14).clamp(40.0, 48.0) * 1.1;
      expect(avatar.size, closeTo(oldResponsiveSize * 1.1, 0.000001));
      expect(tester.takeException(), isNull);
    }
  });
}
