import 'package:chat_bot/base.dart';
import 'package:chat_bot/base/theme.dart';
import 'package:chat_bot/base/db/prompt_item.dart';
import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/floating_nav_layout.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:chat_bot/module/prompt/prompt_page.dart';
import 'package:chat_bot/module/prompt/prompt_viewmodel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// No database writes, generated conversations, or sample Library entries.
class _EmptyPrompts extends PromptListNotify {
  _EmptyPrompts() : super(const AsyncData(<PromptItem>[]));

  @override
  Future<void> load() async {
    state = const AsyncData(<PromptItem>[]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader(AppDims.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/XDot.ttf'));
    await font.load();
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(rootBundle
          .load('packages/cupertino_icons/assets/CupertinoIcons.ttf'));
    await icons.load();
  });

  for (final colors in [AppColors.light, AppColors.dark]) {
    testWidgets('Library empty shell ${colors.brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        overrides: [promptListProvider.overrideWith((ref) => _EmptyPrompts())],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          theme: withAuraPopupTheme(
            (colors.brightness == Brightness.dark ? DarkTheme() : LightTheme())
                .theme(colors.accent),
            colors,
          ).copyWith(extensions: [colors]),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 20),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const Key('library-surface'),
            child: FloatingNavLayout(
              icons: const [
                ChatVectorIcon(),
                LibraryVectorIcon(),
                MicVectorIcon(),
                ServerVectorIcon(),
                SettingVectorIcon(),
              ],
              currentIndex: 1,
              onTap: (_) {},
              child: const PromptPage(),
            ),
          ),
        ),
      ));
      await tester.runAsync(() => precacheImage(
            const AssetImage('assets/images/empty.png'),
            tester.element(find.byType(PromptPage)),
          ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('library-surface')),
        matchesGoldenFile(
            'goldens/library_empty_${colors.brightness.name}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
