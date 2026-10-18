import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/floating_pill_navbar.dart';
import 'package:chat_bot/module/claude/widgets/message_actions.dart';
import 'package:chat_bot/module/claude/widgets/header_pill.dart';
import 'package:chat_bot/module/claude/widgets/agent_avatar.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const icons = <Widget>[
    Icon(Icons.chat_bubble_outline),
    Icon(Icons.book_outlined),
    Icon(Icons.lightbulb_outline),
    Icon(Icons.dns_outlined),
    Icon(Icons.settings_outlined),
  ];

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
  }

  Widget themed(Widget child, {double textScale = 1}) {
    return MaterialApp(
      theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
        AppColors.light,
      ]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 20),
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );
  }

  testWidgets('floating navbar stays bounded and tab targets remain tappable',
      (tester) async {
    await setViewport(tester, const Size(320, 640));
    var selected = -1;
    await tester.pumpWidget(themed(
      Align(
        alignment: Alignment.bottomCenter,
        child: FloatingPillNavbar(
          icons: icons,
          currentIndex: 0,
          onTap: (index) => selected = index,
        ),
      ),
      textScale: 2,
    ));

    expect(tester.takeException(), isNull);
    expect(find.byType(IconButton), findsNWidgets(5));
    for (final element
        in tester.widgetList<IconButton>(find.byType(IconButton))) {
      expect(tester.getSize(find.byWidget(element)).width,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byWidget(element)).height,
          greaterThanOrEqualTo(48));
    }

    final pill = find.byKey(const ValueKey('floating-nav-surface'));
    expect(tester.getSize(pill).width, lessThanOrEqualTo(320));
    expect(tester.getSize(pill).height, AppDims.pillHeight);
    await tester.tap(find.byTooltip('Ruang Kreasi'));
    expect(selected, 2);
  });

  testWidgets('navbar caps its background width on tablet-sized layouts',
      (tester) async {
    await setViewport(tester, const Size(1200, 800));
    await tester.pumpWidget(themed(
      Align(
        alignment: Alignment.bottomCenter,
        child: FloatingPillNavbar(
          icons: icons,
          currentIndex: 1,
          onTap: (_) {},
        ),
      ),
    ));

    final pill = find.byKey(const ValueKey('floating-nav-surface'));
    expect(tester.getSize(pill).width, lessThanOrEqualTo(430));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 600.0, 1200.0]) {
    testWidgets('navbar equal slots and all callbacks at width $width',
        (tester) async {
      await setViewport(tester, Size(width, 844));
      var selected = 0;
      Widget navbar() => themed(StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FloatingPillNavbar(
                  icons: icons,
                  currentIndex: selected,
                  onTap: (index) => setState(() => selected = index),
                ),
              ),
            );
          }));
      await tester.pumpWidget(navbar());
      final surface =
          tester.getRect(find.byKey(const ValueKey('floating-nav-surface')));
      final expectedWidth = width < 600 ? width - 32 : AppDims.pillMaxWidth;
      expect(surface.width, closeTo(expectedWidth, 0.01));
      expect(surface.center.dx, closeTo(width / 2, 0.01));
      const labels = ['Chat', 'Prompt', 'Ruang Kreasi', 'Server', 'Pengaturan'];
      for (var i = 0; i < labels.length; i++) {
        final target = find.byWidgetPredicate(
            (widget) => widget is IconButton && widget.tooltip == labels[i]);
        expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
        expect(tester.getCenter(target).dx,
            closeTo(surface.left + surface.width / 5 * (i + 0.5), 0.01));
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(selected, i);
        final indicator = tester
            .getRect(find.byKey(const ValueKey('floating-nav-indicator')));
        expect(indicator.center.dx, closeTo(tester.getCenter(target).dx, 0.01));
        expect(surface.contains(indicator.topLeft), isTrue);
        expect(surface.contains(indicator.bottomRight), isTrue);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('character stays centered with large text at width $width',
        (tester) async {
      await setViewport(tester, Size(width, 844));
      var menus = 0;
      var newChats = 0;
      await tester.pumpWidget(themed(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MuseHeader(
              activity: AgentActivity.thinking,
              statusLabel: 'Sedang merespons permintaan Anda',
              onMenuTap: () => menus++,
              onNewChatTap: () => newChats++,
            ),
          ),
        ),
        textScale: 2,
      ));
      final avatar = find.byType(AgentAvatar);
      expect(tester.getCenter(avatar).dx, closeTo(width / 2, 0.01));
      expect(tester.getSize(avatar).width,
          closeTo(((width - 32) * 0.14).clamp(40.0, 48.0) * 1.1, 0.001));
      expect(tester.getRect(find.text('Muse')).top,
          greaterThanOrEqualTo(tester.getRect(avatar).bottom));
      await tester.tap(find.byType(MenuButton));
      await tester.tap(find.byType(NewChatVectorIcon));
      expect(menus, 1);
      expect(newChats, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('message actions fit above keyboard and keep callbacks active',
      (tester) async {
    await setViewport(tester, const Size(320, 360));
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);

    BuildContext? pageContext;
    var copies = 0;
    await tester.pumpWidget(themed(
      Builder(
        builder: (context) {
          pageContext = context;
          return const SizedBox.expand();
        },
      ),
      textScale: 2,
    ));
    final popupFuture = showMessageActions(
      pageContext!,
      isUser: false,
      anchor: const Offset(300, 340),
      onCopy: () => copies++,
      onShare: () {},
      onDelete: () {},
    );
    await tester.pumpAndSettle();

    final popup = find.ancestor(
      of: find.text('Salin'),
      matching: find.byType(Container),
    );
    final rect = tester.getRect(popup.first);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.top, greaterThanOrEqualTo(32));
    expect(rect.bottom, lessThanOrEqualTo(172));
    expect(rect.height, lessThan(180));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Salin'));
    await tester.pumpAndSettle();
    await popupFuture;
    expect(copies, 1);
  });
}
