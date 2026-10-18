import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/floating_nav_layout.dart';
import 'package:chat_bot/module/claude/widgets/floating_pill_navbar.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _icons = <Widget>[
  ChatVectorIcon(),
  LibraryVectorIcon(),
  MicVectorIcon(),
  ServerVectorIcon(),
  SettingVectorIcon(),
];
const _labels = ['Chat', 'Prompt', 'Ruang Kreasi', 'Server', 'Pengaturan'];

Widget _shell({required AppColors colors, double keyboard = 0}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: colors.brightness,
      extensions: [colors],
      // Deliberately opaque defaults: the shell must override these locally.
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(backgroundColor: colors.surface, elevation: 4),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
        viewInsets: EdgeInsets.only(bottom: keyboard),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: const _TabHarness(),
  );
}

class _TabHarness extends StatefulWidget {
  const _TabHarness();

  @override
  State<_TabHarness> createState() => _TabHarnessState();
}

class _TabHarnessState extends State<_TabHarness> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => FloatingNavLayout(
        icons: _icons,
        currentIndex: selected,
        onTap: (value) => setState(() => selected = value),
        child: IndexedStack(
          index: selected,
          sizing: StackFit.expand,
          children: [
            for (final label in _labels)
              Scaffold(
                appBar: AppBar(title: Text(label)),
                body: Center(
                  child: Builder(builder: (context) {
                    final theme = Theme.of(context);
                    expect(theme.scaffoldBackgroundColor, Colors.transparent);
                    expect(
                        theme.appBarTheme.backgroundColor, Colors.transparent);
                    expect(theme.appBarTheme.scrolledUnderElevation, 0);
                    return Text('$label content');
                  }),
                ),
              ),
          ],
        ),
      );
}

void main() {
  for (final colors in [AppColors.light, AppColors.dark]) {
    final mode = colors.brightness.name;
    testWidgets('all tabs share one aura and one floating navbar ($mode)',
        (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_shell(colors: colors));
      for (var index = 0; index < _labels.length; index++) {
        await tester.tap(find.byTooltip(_labels[index]));
        await tester.pumpAndSettle();
        expect(find.text('${_labels[index]} content'), findsOneWidget);
        expect(find.byType(FloatingPillNavbar), findsOneWidget);
        final background = tester.widget<DecoratedBox>(
            find.byKey(const ValueKey('floating-tabs-background')));
        final decoration = background.decoration as BoxDecoration;
        expect(decoration.color, colors.bgBase);
        expect(decoration.gradient, colors.bgGradientBottom);
        final nav =
            tester.getRect(find.byKey(const ValueKey('floating-nav-surface')));
        expect(nav.bottom, 390 - 20 - AppDims.pillBottomGap);
        expect(nav.left, greaterThanOrEqualTo(24));
        expect(nav.right, lessThanOrEqualTo(844 - 16));
        expect(nav.center.dx, (844 + 24 - 16) / 2);
        final tab = tester.getRect(find.byType(IndexedStack));
        expect(tab.bottom, nav.top);
        final button = tester.widget<IconButton>(find.byWidgetPredicate(
            (widget) =>
                widget is IconButton && widget.tooltip == _labels[index]));
        final states = <MaterialState>{MaterialState.pressed};
        expect(button.style!.overlayColor!.resolve(states), Colors.transparent);
        expect(button.style!.elevation!.resolve(states), 0);
        expect(button.style!.shadowColor!.resolve(states), Colors.transparent);
        expect(button.style!.splashFactory, NoSplash.splashFactory);
        expect(button.style!.foregroundColor!.resolve(states), colors.navIcon);
        expect(button.style!.overlayColor!.resolve({MaterialState.focused}),
            isNot(Colors.transparent));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard hides navbar and reserves visible content ($mode)',
        (tester) async {
      await tester.pumpWidget(_shell(colors: colors, keyboard: 260));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingPillNavbar), findsNothing);
      expect(tester.getRect(find.byType(IndexedStack)).bottom,
          tester.view.physicalSize.height / tester.view.devicePixelRatio - 260);
      expect(tester.takeException(), isNull);
    });
  }
}
