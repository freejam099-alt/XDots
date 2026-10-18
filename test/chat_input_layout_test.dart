import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/chat_input_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    ChatInputController controller, {
    ValueChanged<String>? onSend,
    ValueChanged<AttachKind>? onAttach,
  }) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 220,
            child: ChatInputBar(
              controller: controller,
              onSubmitted: onSend ?? (_) {},
              onAttach: onAttach,
              plusIcon: const Icon(Icons.add),
              micIcon: const Icon(Icons.mic),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'input honors bounded parent and keeps width across multiline send',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ChatInputController();
    addTearDown(controller.dispose);
    String? sent;
    await tester.pumpWidget(host(controller, onSend: (text) => sent = text));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('chat-input-surface'));
    expect(tester.getRect(surface).width, closeTo(220, 0.01));
    expect(tester.getRect(surface).height, closeTo(48, 0.01));

    const multiline = 'baris pertama\nbaris kedua';
    await tester.enterText(find.byType(TextField), multiline);
    await tester.pumpAndSettle();
    expect(controller.text, multiline);
    expect(tester.getRect(surface).width, closeTo(220, 0.01));
    expect(tester.getRect(surface).height, greaterThan(48));
    expect(find.byKey(const ValueKey('send')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('send')));
    await tester.pumpAndSettle();
    expect(sent, multiline);
    expect(controller.text, multiline);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('plus menu dispatches selected attachment callback',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ChatInputController();
    addTearDown(controller.dispose);
    AttachKind? selected;
    await tester.pumpWidget(
      host(controller, onAttach: (kind) => selected = kind),
    );
    await tester.pumpAndSettle();

    final plusButton = find
        .descendant(
          of: find.byType(ChatInputBar),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(plusButton);
    await tester.pumpAndSettle();
    expect(find.text('Foto'), findsOneWidget);

    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();
    expect(selected, AttachKind.photo);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
