import 'package:chat_bot/module/claude/chat_data.dart';
import 'package:chat_bot/module/claude/model_store.dart';
import 'package:chat_bot/module/claude/widgets/clever_block.dart';
import 'package:chat_bot/module/claude/widgets/file_icon.dart';
import 'package:chat_bot/module/claude/widgets/gen_card.dart';
import 'package:chat_bot/module/claude/widgets/provider_rows.dart';
import 'package:chat_bot/utils/sp_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SpUtil.getInstance();
  });

  testWidgets('completed generation without a result is unavailable, not busy',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: GenCard(isVideo: false, phase: GenPhase.done),
          ),
        ),
      ),
    ));

    expect(find.text('Hasil tidak tersedia'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('direct video URLs with query tokens render as video cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CleverMessage(
          text: 'https://cdn.example.test/clip.mp4?token=private',
        ),
      ),
    ));

    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
    expect(find.byIcon(Icons.public), findsNothing);
  });

  testWidgets('image preview provides an error fallback',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CleverMessage(text: 'https://example.test/image.png'),
      ),
    ));

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    final List<Image> images =
        tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images.length, greaterThan(1));
    expect(images.last.errorBuilder, isNotNull);
  });

  testWidgets(
      'search key saves as typed and controller follows service changes',
      (WidgetTester tester) async {
    ModelStore.setSearchKey('tavily', 'saved-for-tavily');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SearchServiceRow(service: const SearchService('brave', 'Brave')),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'typed-key');
    expect(ModelStore.searchKey('brave'), 'typed-key');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body:
            SearchServiceRow(service: const SearchService('tavily', 'Tavily')),
      ),
    ));

    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'saved-for-tavily');
  });

  testWidgets('unknown extensions use a generic file icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FileIconImage(filename: 'archive.unknown')),
    ));

    expect(fileIconAsset('archive.unknown'), isEmpty);
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
