import 'dart:async';
import 'dart:io';

import 'package:chat_bot/module/claude/agent_failure.dart';
import 'package:chat_bot/module/claude/ai_service.dart';
import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/chat_data.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:chat_bot/module/claude/widgets/agent_avatar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(ChatUiController controller) => MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: ClaudeChatScreen(
          controller: controller,
          navIcons: List.generate(5, (_) => const Icon(Icons.chat)),
          navIndex: 0,
          onNavTap: (_) {},
          hideInputBar: true,
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final status in [408, 425, 429, 500, 502, 503, 504]) {
    test('real HTTP $status is a temporary frustrated state', () {
      expect(
          activityForFailure(
              MuseAiException('Request failed', statusCode: status)),
          AgentActivity.frustrated);
    });
  }
  for (final status in [400, 401, 403, 404, 422]) {
    test('real HTTP $status is a crying failed-request state', () {
      expect(
          activityForFailure(
              MuseAiException('Request failed', statusCode: status)),
          AgentActivity.crying);
    });
  }
  test('typed timeouts and offline failures are temporary, not invented', () {
    expect(activityForFailure(TimeoutException('Timeout')),
        AgentActivity.frustrated);
    expect(activityForFailure(const SocketException('Offline')),
        AgentActivity.frustrated);
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError
    ]) {
      expect(
          activityForFailure(DioException(
              requestOptions: RequestOptions(path: '/test'), type: type)),
          AgentActivity.frustrated);
    }
  });
  test('Dio HTTP status is classified and intentional cancellation is neutral',
      () {
    final options = RequestOptions(path: '/test');
    expect(
        activityForFailure(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 429))),
        AgentActivity.frustrated);
    expect(
        activityForFailure(DioException(
            requestOptions: options, type: DioExceptionType.cancel)),
        AgentActivity.idle);
  });
  test('does not infer retryability by parsing message text', () {
    expect(
        activityForFailure(
            const MuseAiException('Words HTTP 429, timeout, refused')),
        AgentActivity.crying);
  });

  testWidgets(
      'actual backend timeout and failed request produce different runtime faces',
      (tester) async {
    final controller = ChatUiController();
    await tester.pumpWidget(host(controller));
    await tester.pump();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.idle);
    controller.reportFailure(TimeoutException('Request timed out'));
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.frustrated);
    expect(find.text('Gangguan sementara — coba lagi'), findsOneWidget);
    controller.reportFailure(
        const MuseAiException('Request rejected', statusCode: 401));
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.crying);
    expect(find.text('Permintaan gagal'), findsOneWidget);
    controller.clear();
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.idle);
  });

  testWidgets(
      'user and assistant warning text never manufacture an error emotion',
      (tester) async {
    final controller = ChatUiController();
    await tester.pumpWidget(host(controller));
    controller.addMessage(const ChatMsg(
        isUser: true, type: MessageType.text, text: '⚠️ marah, nangis'));
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.idle);
    controller.addMessage(const ChatMsg(
        isUser: false,
        type: MessageType.text,
        text: '⚠️ Informational warning'));
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.idle);
  });

  testWidgets(
      'retry streaming clears failure while real tool uses its computer state',
      (tester) async {
    final controller = ChatUiController();
    await tester.pumpWidget(host(controller));
    controller.reportFailure(TimeoutException('Timeout'));
    await tester.pumpAndSettle();
    controller.appendAiToken('Recovered response');
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.thinking);
    controller.finishAiMessage();
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.idle);
    controller.toolCall('tools_use');
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.tool);
    controller.finishTool('tools_use');
    await tester.pumpAndSettle();
    expect(tester.widget<AgentAvatar>(find.byType(AgentAvatar)).activity,
        AgentActivity.idle);
  });
}
