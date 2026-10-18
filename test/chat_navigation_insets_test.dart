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

  for (final size in [const Size(320, 640), const Size(844, 390)]) {
    for (final keyboard in [false, true]) {
      testWidgets('standalone chat safe area $size keyboard=$keyboard',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final keyboardHeight = keyboard ? 160.0 : 0.0;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(extensions: const [AppColors.light]),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(top: 24, bottom: keyboard ? 0 : 20),
              viewInsets: EdgeInsets.only(bottom: keyboardHeight),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: ClaudeChatScreen(
            navIcons: icons,
            navIndex: 0,
            onNavTap: (_) {},
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingPillNavbar),
            keyboard ? findsNothing : findsOneWidget);
        final input = tester.getRect(find.byType(ChatInputBar));
        expect(input.bottom, lessThanOrEqualTo(size.height - keyboardHeight));
        expect(input.left, greaterThanOrEqualTo(0));
        expect(input.right, lessThanOrEqualTo(size.width));
        if (!keyboard) {
          final nav = tester
              .getRect(find.byKey(const ValueKey('floating-nav-surface')));
          expect(nav.bottom,
              closeTo(size.height - 20 - AppDims.pillBottomGap, 0.01));
          expect(input.bottom, lessThan(nav.top));
        }
        expect(find.text('Mulai percakapan baru'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('embedded chat leaves navbar ownership to its parent',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
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
