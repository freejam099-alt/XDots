import 'dart:io';

import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/chat_data.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:chat_bot/module/claude/widgets/cards.dart';
import 'package:chat_bot/module/claude/widgets/tool_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool dark = false}) => MaterialApp(
      theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          fontFamily: AppDims.fontFamily,
          extensions: [dark ? AppColors.dark : AppColors.light]),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!),
      home: Scaffold(body: child),
    );

Widget chat(ChatUiController controller) => host(ClaudeChatScreen(
      controller: controller,
      navIcons: List.generate(5, (_) => const Icon(Icons.chat)),
      navIndex: 0,
      onNavTap: (_) {},
      hideInputBar: true,
    ));

void main() {
  test('URL actions reject non-web schemes and embedded credentials', () {
    expect(webActionUri('javascript:alert(1)'), isNull);
    expect(webActionUri('file:///etc/passwd'), isNull);
    expect(webActionUri('https://user:password@example.com'), isNull);
    expect(webActionUri('https://example.com/path')?.host, 'example.com');
  });

  test('History never resumes a pending approval or interrupted job', () {
    final ChatMsg saved = ChatMsg.fromJson(const ChatMsg(
            isUser: false,
            type: MessageType.checkout,
            text: 'Action',
            requestId: 'request')
        .toJson());
    expect(saved.approvalStatus, ApprovalStatus.expired);
    final ChatMsg stopped = ChatMsg.fromJson(const ChatMsg(
            isUser: false,
            type: MessageType.tool,
            text: '',
            toolStatus: ToolStatus.running)
        .toJson());
    expect(stopped.toolStatus, ToolStatus.failed);
    expect(
        ChatMsg.fromJson(const ChatMsg(
                    isUser: false,
                    type: MessageType.tool,
                    text: '',
                    toolStatus: ToolStatus.done)
                .toJson())
            .toolStatus,
        ToolStatus.done);
  });

  test('File preview reads actual content and bounds the excerpt', () async {
    final Directory directory =
        await Directory.systemTemp.createTemp('xdots-test-');
    addTearDown(() => directory.delete(recursive: true));
    final File file = File('${directory.path}/notes.txt');
    await file
        .writeAsString('Real file contents\n${List.filled(10000, 'x').join()}');
    final String? text = await readFileExcerpt(
        MsgAttachment(kind: 3, path: file.path, name: 'notes.txt'));
    expect(text, startsWith('Real file contents'));
    expect(text!.length, lessThan(8300));
    expect(text, contains('8 KB'));
    expect(
        await readFileExcerpt(
            MsgAttachment(kind: 3, path: file.path, name: 'document.pdf')),
        isNull);
  });

  testWidgets('Inactive checkout has no fabricated card or actionable approval',
      (tester) async {
    await tester.pumpWidget(host(const CheckoutCard(summary: 'Review action')));
    expect(find.textContaining('1234'), findsNothing);
    expect(find.textContaining('VISA'), findsNothing);
    expect(find.text('Izinkan'), findsNothing);
    expect(find.text('Permintaan tidak aktif'), findsOneWidget);
  });

  testWidgets(
      'Browser renders only actual event detail without simulated seats',
      (tester) async {
    await tester.pumpWidget(
        host(const BrowserCard(detail: 'Reading the requested page')));
    expect(find.text('Reading the requested page'), findsOneWidget);
    expect(find.text('SCREEN'), findsNothing);
    expect(find.text('Selecting seats...'), findsNothing);
    expect(find.text('Buka browser'), findsNothing);
  });

  testWidgets('Failed tool shows failure and actual expandable result',
      (tester) async {
    await tester.pumpWidget(host(const SingleChildScrollView(
        child: ToolCallCard(
            toolName: 'dot_read',
            status: ToolStatus.failed,
            result: 'HTTP 503'))));
    expect(find.text('Tindakan gagal'), findsOneWidget);
    await tester.tap(find.text('Lihat detail kegagalan'));
    await tester.pumpAndSettle();
    expect(find.text('HTTP 503'), findsOneWidget);
  });

  testWidgets(
      'Controller insert updates empty state and no initial sample messages',
      (tester) async {
    final ChatUiController controller = ChatUiController();
    await tester.pumpWidget(chat(controller));
    expect(find.text('Mulai percakapan baru'), findsOneWidget);
    controller.addMessage(const ChatMsg(
        isUser: true,
        type: MessageType.text,
        text: 'User-provided test event'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai percakapan baru'), findsNothing);
    expect(find.text('User-provided test event'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Approval resolves once and duplicate requests fail closed',
      (tester) async {
    final ChatUiController controller = ChatUiController();
    await tester.pumpWidget(chat(controller));
    final Future<bool> pending = controller.requestApproval(
        requestId: 'one', summary: 'A backend-originated action');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Izinkan'), findsOneWidget);
    await tester.tap(find.text('Izinkan'));
    await tester.pumpAndSettle();
    expect(await pending, isTrue);
    expect(find.text('Disetujui'), findsOneWidget);
    expect(find.text('Izinkan'), findsNothing);
    expect(
        await controller.requestApproval(requestId: 'one', summary: 'Replay'),
        isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Clear and dispose reject pending approval', (tester) async {
    final ChatUiController controller = ChatUiController();
    await tester.pumpWidget(chat(controller));
    final Future<bool> first =
        controller.requestApproval(requestId: 'first', summary: 'First');
    await tester.pump();
    controller.clear();
    await tester.pumpAndSettle();
    expect(await first, isFalse);
    final Future<bool> second =
        controller.requestApproval(requestId: 'second', summary: 'Second');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(await second, isFalse);
    expect(
        await controller.requestApproval(
            requestId: 'no-screen', summary: 'None'),
        isFalse);
  });
}
