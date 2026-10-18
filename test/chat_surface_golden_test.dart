import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final FontLoader font = FontLoader(AppDims.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/XDot.ttf'));
    await font.load();
  });

  for (final bool dark in [false, true]) {
    testWidgets('Empty chat surface ${dark ? 'dark' : 'light'}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final AppColors colors = dark ? AppColors.dark : AppColors.light;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          fontFamily: AppDims.fontFamily,
          extensions: [colors],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const Key('surface'),
          child: ClaudeChatScreen(
            navIcons: const [
              ChatVectorIcon(),
              LibraryVectorIcon(),
              MicVectorIcon(),
              ServerVectorIcon(),
              SettingVectorIcon(),
            ],
            navIndex: 0,
            onNavTap: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
          find.byKey(const Key('surface')),
          matchesGoldenFile(
              'goldens/chat_empty_${dark ? 'dark' : 'light'}.png'));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
