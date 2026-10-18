import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/chat_data.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:chat_bot/module/claude/widgets/action_icons.dart';
import 'package:chat_bot/module/claude/widgets/gen_card.dart';
import 'package:chat_bot/module/claude/widgets/dynamic_gradient_loader.dart';
import 'package:chat_bot/module/claude/widgets/tool_card.dart';
import 'package:chat_bot/utils/sp_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child,
        {bool dark = false, bool reduced = true, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(
          fontFamily: AppDims.fontFamily,
          brightness: dark ? Brightness.dark : Brightness.light,
          extensions: [dark ? AppColors.dark : AppColors.light]),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Scaffold(body: child),
    );

Widget chat(ChatUiController controller) => host(ClaudeChatScreen(
    controller: controller,
    hideInputBar: true,
    navIcons: List.generate(5, (_) => const Icon(Icons.chat)),
    navIndex: 0,
    onNavTap: (_) {}));

ChatMsg tool(String name,
        {ToolStatus status = ToolStatus.done,
        String? model,
        String text = ''}) =>
    ChatMsg(
        isUser: false,
        type: MessageType.tool,
        text: text,
        toolName: name,
        toolStatus: status,
        modelName: model);
const user =
    ChatMsg(isUser: true, type: MessageType.text, text: 'Permintaan pengguna');

void main() {
  setUpAll(() async {
    final font = FontLoader(AppDims.fontFamily)
      ..addFont(rootBundle.load('assets/fonts/XDot.ttf'));
    await font.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SpUtil.getInstance();
  });

  test('group includes interleaved assistant text but never the next user turn',
      () {
    final messages = [
      user,
      tool('dot_search'),
      const ChatMsg(isUser: false, type: MessageType.text, text: 'Teks asli'),
      tool('dot_read'),
      user,
      tool('tools_use')
    ];
    expect(toolActivityIndices(messages, 1), [1, 3]);
    expect(toolActivityIndices(messages, 3), [1, 3]);
    expect(toolActivityIndices(messages, 5), [5]);
    expect(toolActivityIndices(messages, -1), isEmpty);
  });

  test(
      'model label uses five Unicode characters and history keeps actual model',
      () {
    expect(shortModelName('gpt-5-mini'), 'gpt-5...');
    expect(shortModelName('model'), 'model');
    expect(shortModelName('😀😀😀😀😀😀'), '😀😀😀😀😀...');
    final message = tool('dot_read', model: 'gpt-5-mini');
    expect(ChatMsg.fromJson(message.toJson()).modelName, 'gpt-5-mini');
    expect(
        ChatMsg.fromJson({'type': MessageType.tool.index}).modelName, isNull);
  });

  test('explicit run groups survive queued user messages and JSON history', () {
    final first = tool('dot_search').copyWith(activityGroupId: 'run-one');
    final next = tool('dot_read').copyWith(activityGroupId: 'run-one');
    final second = tool('tools_use').copyWith(activityGroupId: 'run-two');
    final messages = [user, first, user, next, second];
    expect(toolActivityIndices(messages, 1), [1, 3]);
    expect(toolActivityIndices(messages, 3), [1, 3]);
    expect(toolActivityIndices(messages, 4), [4]);
    expect(ChatMsg.fromJson(first.toJson()).activityGroupId, 'run-one');
  });

  test('legacy history never absorbs a later explicit retry group', () {
    final messages = [
      user,
      tool('dot_search'),
      tool('dot_read').copyWith(activityGroupId: 'retry-run')
    ];
    expect(toolActivityIndices(messages, 1), [1]);
    expect(toolActivityIndices(messages, 2), [2]);
  });

  for (final dark in [false, true]) {
    testWidgets('tool pill visual ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(390, 140);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final colors = dark ? AppColors.dark : AppColors.light;
      await tester.pumpWidget(host(
          RepaintBoundary(
            key: const ValueKey('pill-golden'),
            child: ColoredBox(
                color: colors.bgBase,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ToolActivityPill(activities: [
                    tool('dot_search', model: 'gpt-5-mini'),
                    tool('dot_read',
                        model: 'gpt-5-mini', status: ToolStatus.running),
                  ]),
                )),
          ),
          dark: dark));
      await tester.pumpAndSettle();
      await expectLater(
          find.byKey(const ValueKey('pill-golden')),
          matchesGoldenFile(
              'goldens/tool_pill_${dark ? 'dark' : 'light'}.png'));
    });

    testWidgets(
        'pill is compact borderless and details are preserved ${dark ? 'dark' : 'light'}',
        (tester) async {
      await tester.pumpWidget(host(
          ToolActivityPill(activities: [
            tool('dot_search',
                model: 'gpt-5-mini', text: 'Hasil pencarian asli'),
            tool('dot_read',
                status: ToolStatus.failed,
                model: 'gpt-5-mini',
                text: 'HTTP 503'),
          ]),
          dark: dark));
      final pill = find.byKey(const ValueKey('tool-activity-pill'));
      expect(pill, findsOneWidget);
      expect(tester.getSize(pill).width, lessThan(190));
      expect(tester.getSize(pill).height, lessThan(40));
      final decoration =
          tester.widget<Container>(pill).decoration! as BoxDecoration;
      expect(decoration.border, isNull);
      expect(decoration.gradient, isNotNull);
      expect(decoration.boxShadow, isNull);
      expect(find.text('gpt-5...'), findsOneWidget);
      expect(find.text('dot_read'), findsNothing);
      expect(find.text('HTTP 503'), findsNothing);
      await tester.tap(pill);
      await tester.pumpAndSettle();
      expect(find.text('HTTP 503'), findsOneWidget);
      expect(find.text('Hasil pencarian asli'), findsOneWidget);
      expect(find.text('dot_search'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'two controller tools become one pill and stream waits until both finish',
      (tester) async {
    final controller = ChatUiController();
    await tester.pumpWidget(chat(controller));
    controller.addMessage(user);
    controller.toolCall('dot_search', detail: 'query');
    controller.toolCall('dot_read', detail: 'https://example.test');
    controller.appendAiToken('Jawaban hasil tools');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ToolActivityPill), findsOneWidget);
    expect(find.byKey(const ValueKey('tool-activity-pill')), findsOneWidget);
    expect(find.text('Jawaban hasil tools'), findsNothing);
    controller.finishAiMessage();
    controller.finishTool('dot_search');
    await tester.pump();
    expect(find.text('Jawaban hasil tools'), findsNothing);
    controller.finishTool('dot_read');
    await tester.pumpAndSettle();
    expect(find.text('Jawaban hasil tools'), findsOneWidget);
    expect(find.byType(ToolActivityPill), findsOneWidget);
    controller.addMessage(user);
    controller.toolCall('tools_use');
    controller.finishTool('tools_use');
    await tester.pumpAndSettle();
    expect(find.byType(ToolActivityPill), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('one tool does not hold streaming text', (tester) async {
    final controller = ChatUiController();
    await tester.pumpWidget(chat(controller));
    controller.toolCall('dot_search');
    controller.appendAiToken('Streaming langsung');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Streaming langsung'), findsOneWidget);
    controller.finishTool('dot_search');
    controller.finishAiMessage();
    await tester.pumpAndSettle();
    expect(find.text('Streaming langsung'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('generation while running uses a compact animated loader',
      (tester) async {
    await tester.pumpWidget(host(const GenCard(
        isVideo: false, phase: GenPhase.generating, ratio: '9:16')));
    expect(find.byType(AspectRatio), findsNothing);
    expect(find.byType(ToolActivityPill), findsOneWidget);
    expect(find.byType(MuseDynamicGradientLoader), findsOneWidget);
    expect(find.text('Membuat gambar…'), findsOneWidget);
    expect(tester.getSize(find.byType(GenCard)).height, lessThan(100));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'multiple tool transition supports motion, no overflow at large text',
      (tester) async {
    tester.view.physicalSize = const Size(240, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget view(String name) => host(
        ToolActivityPill(activities: [
          tool('dot_search'),
          tool(name, status: ToolStatus.running, model: 'long-model-name'),
        ]),
        reduced: false,
        scale: 2);
    await tester.pumpWidget(view('dot_read'));
    await tester.pumpWidget(view('create_image'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ImageFiltered), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'correct action vectors are selected without fabricated tool events',
      (tester) async {
    for (final entry in {
      'create_image': ActionIconKind.image,
      'tools_use': ActionIconKind.terminal,
      'dot_read': ActionIconKind.read,
      'dot_search': ActionIconKind.search,
      'web_fetch_exa': ActionIconKind.read,
      'summary': ActionIconKind.summary,
      'smart': ActionIconKind.smart,
      'fast': ActionIconKind.fast,
    }.entries) {
      await tester.pumpWidget(host(toolIconFor(entry.key)));
      expect(
          tester.widget<ActionVectorIcon>(find.byType(ActionVectorIcon)).kind,
          entry.value);
    }
  });
}
