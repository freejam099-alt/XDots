import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:chat_bot/module/claude/widgets/chat_input_bar.dart';
import 'package:chat_bot/module/claude/widgets/floating_pill_navbar.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const icons = <Widget>[
    ChatVectorIcon(),
    LibraryVectorIcon(),
    MicVectorIcon(),
    ServerVectorIcon(),
    SettingVectorIcon(),
  ];

  Future<void> setViewport(
    WidgetTester tester,
    Size size, {
    double safeLeft = 0,
    double safeRight = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewPadding = FakeViewPadding(
      left: safeLeft,
      right: safeRight,
      top: 24,
      bottom: 20,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
  }

  Widget themedChat({
    required bool keyboard,
    required double safeLeft,
    required double safeRight,
  }) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(
            left: safeLeft,
            right: safeRight,
            top: 24,
            bottom: keyboard ? 0 : 20,
          ),
          viewInsets: EdgeInsets.only(bottom: keyboard ? 160 : 0),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: ClaudeChatScreen(
        navIcons: icons,
        navIndex: 0,
        onNavTap: (_) {},
      ),
    );
  }

  final viewports =
      <({Size size, double safeLeft, double safeRight, double expectedWidth})>[
    (
      size: const Size(320, 640),
      safeLeft: 0,
      safeRight: 0,
      expectedWidth: 288,
    ),
    (
      size: const Size(390, 844),
      safeLeft: 0,
      safeRight: 0,
      expectedWidth: 358,
    ),
    (
      size: const Size(600, 844),
      safeLeft: 0,
      safeRight: 0,
      expectedWidth: 430,
    ),
    // Landscape with asymmetric horizontal system insets.
    (
      size: const Size(844, 390),
      safeLeft: 24,
      safeRight: 16,
      expectedWidth: 430,
    ),
    (
      size: const Size(1200, 800),
      safeLeft: 0,
      safeRight: 0,
      expectedWidth: 430,
    ),
  ];

  for (final viewport in viewports) {
    for (final keyboard in [false, true]) {
      testWidgets(
        'input and navbar surfaces align at ${viewport.size} keyboard=$keyboard',
        (tester) async {
          await setViewport(
            tester,
            viewport.size,
            safeLeft: viewport.safeLeft,
            safeRight: viewport.safeRight,
          );
          await tester.pumpWidget(themedChat(
            keyboard: keyboard,
            safeLeft: viewport.safeLeft,
            safeRight: viewport.safeRight,
          ));
          await tester.pumpAndSettle();

          final inputFinder = find.byKey(const ValueKey('chat-input-surface'));
          final navFinder = find.byKey(const ValueKey('floating-nav-surface'));
          expect(inputFinder, findsOneWidget);
          expect(navFinder, keyboard ? findsNothing : findsOneWidget);

          final input = tester.getRect(inputFinder);
          final expectedWidth = viewport.expectedWidth;
          expect(input.width, closeTo(expectedWidth, 0.01));
          expect(
            input.center.dx,
            closeTo(
              (viewport.size.width + viewport.safeLeft - viewport.safeRight) /
                  2,
              0.01,
            ),
          );
          expect(input.left, greaterThanOrEqualTo(viewport.safeLeft));
          expect(input.right,
              lessThanOrEqualTo(viewport.size.width - viewport.safeRight));

          if (keyboard) {
            expect(
              input.bottom,
              lessThanOrEqualTo(viewport.size.height - 160),
            );
          } else {
            final nav = tester.getRect(navFinder);
            expect(nav.width, closeTo(expectedWidth, 0.01));
            expect(input.left, closeTo(nav.left, 0.01));
            expect(input.right, closeTo(nav.right, 0.01));
            expect(input.height, closeTo(48, 0.01));
            expect(nav.height, closeTo(64, 0.01));
            expect(nav.top - input.bottom, closeTo(10, 0.01));
            expect(
              nav.bottom,
              closeTo(
                viewport.size.height - 20 - AppDims.pillBottomGap,
                0.01,
              ),
            );
          }
          expect(find.byType(FloatingPillNavbar),
              keyboard ? findsNothing : findsOneWidget);
          expect(find.text('Mulai percakapan baru'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('embedded chat leaves navbar ownership to its parent',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: ClaudeChatScreen(
          navIcons: icons,
          navIndex: 0,
          onNavTap: (_) {},
          embedded: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(FloatingPillNavbar), findsNothing);
    expect(find.byType(ChatInputBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
