import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/chat_input_bar.dart';
import 'package:chat_bot/module/claude/widgets/header_pill.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader(AppDims.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/XDot.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final bool dark in [false, true]) {
    final String mode = dark ? 'dark' : 'light';
    final AppColors colors = dark ? AppColors.dark : AppColors.light;

    testWidgets('Header delete popup $mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var deletes = 0;
      await tester.pumpWidget(_popupApp(
        colors: colors,
        child: Scaffold(
          backgroundColor: colors.bgBase,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [MuseHeader(onDeleteMessages: () => deletes++)],
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.byType(MoreDotsVectorIcon));
      await tester.pumpAndSettle();
      expect(find.text('Hapus semua pesan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('popup-screen')),
        matchesGoldenFile('goldens/header_popup_$mode.png'),
      );
      await tester.tap(find.text('Hapus semua pesan'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus semua pesan?'), findsOneWidget);
      expect(deletes, 0);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(deletes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Attachment popup $mode', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_popupApp(
        colors: colors,
        child: Scaffold(
          backgroundColor: colors.bgBase,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(
              controller: controller,
              onSubmitted: (_) {},
              plusIcon: const Icon(Icons.add),
              micIcon: const Icon(Icons.mic),
              onAttach: (_) {},
            ),
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      for (final label in ['Foto', 'Kamera', 'Video', 'Berkas']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('popup-screen')),
        matchesGoldenFile('goldens/attachment_popup_$mode.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Widget _popupApp({required AppColors colors, required Widget child}) {
  return RepaintBoundary(
    key: const Key('popup-screen'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withAuraPopupTheme(
        ThemeData(
            brightness: colors.brightness, fontFamily: AppDims.fontFamily),
        colors,
      ).copyWith(extensions: [colors]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: child,
    ),
  );
}
