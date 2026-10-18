import 'dart:typed_data';

import 'package:chat_bot/base/components/chat_markdown.dart';
import 'package:chat_bot/base/theme.dart';
import 'package:chat_bot/base/typography.dart';
import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/widgets/markdown_bubble.dart';
import 'package:chat_bot/module/claude/widgets/streaming_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved theme preference maps to the corresponding Material mode', () {
    expect(ThemeType.light.materialMode, ThemeMode.light);
    expect(ThemeType.dark.materialMode, ThemeMode.dark);
    expect(ThemeType.system.materialMode, ThemeMode.system);
  });

  test('bundled XDot font is a valid TrueType face with usable metrics',
      () async {
    final ByteData asset = await rootBundle.load('assets/fonts/XDot.ttf');
    final ByteData bytes = asset.buffer.asByteData(
      asset.offsetInBytes,
      asset.lengthInBytes,
    );

    expect(bytes.lengthInBytes, greaterThan(12));
    expect(bytes.getUint32(0), 0x00010000, reason: 'TrueType sfnt signature');
    final int tableCount = bytes.getUint16(4);
    final Map<String, List<int>> tables = <String, List<int>>{};
    for (int i = 0; i < tableCount; i++) {
      final int entry = 12 + (i * 16);
      final String tag = String.fromCharCodes(
        List<int>.generate(4, (int j) => bytes.getUint8(entry + j)),
      );
      tables[tag] = <int>[
        bytes.getUint32(entry + 8),
        bytes.getUint32(entry + 12)
      ];
    }

    expect(tables.keys, containsAll(<String>['head', 'maxp', 'cmap']));
    final int headOffset = tables['head']![0];
    final int maxpOffset = tables['maxp']![0];
    expect(bytes.getUint16(headOffset + 18), 2000, reason: 'units per em');
    expect(bytes.getUint16(maxpOffset + 4), greaterThan(400),
        reason: 'glyph count');
    expect(xDotFontFamily, 'XDot');
  });

  for (final BaseTheme baseTheme in <BaseTheme>[LightTheme(), DarkTheme()]) {
    test(
        '${baseTheme.runtimeType} applies XDot to Material and Cupertino styles',
        () {
      final ThemeData theme = baseTheme.theme(const Color(0xff3366cc));
      expect(theme.textTheme.titleMedium?.fontFamily, xDotFontFamily);
      expect(theme.textTheme.bodyMedium?.fontFamily, xDotFontFamily);
      expect(theme.primaryTextTheme.bodyMedium?.fontFamily, xDotFontFamily);
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, xDotFontFamily);
      expect(theme.bottomNavigationBarTheme.selectedLabelStyle?.fontFamily,
          xDotFontFamily);
      expect(theme.bottomNavigationBarTheme.unselectedLabelStyle?.fontFamily,
          xDotFontFamily);
      final CupertinoTextThemeData cupertinoText =
          theme.cupertinoOverrideTheme!.textTheme!;
      expect(cupertinoText.textStyle.fontFamily, xDotFontFamily);
      expect(cupertinoText.actionTextStyle.fontFamily, xDotFontFamily);
      expect(theme.brightness,
          baseTheme is DarkTheme ? Brightness.dark : Brightness.light);
    });
  }

  testWidgets('active markdown uses XDot paragraph style',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: LightTheme().theme(const Color(0xff3366cc)),
      home: const Scaffold(
        body: ChatMarkDown(content: 'active markdown body'),
      ),
    ));

    final RichText text = tester.widget<RichText>(find.byType(RichText).first);
    expect(text.text.style?.fontFamily, xDotFontFamily);
  });

  testWidgets('legacy markdown and streaming text use XDot',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: LightTheme().theme(const Color(0xff3366cc)).copyWith(
          extensions: const <ThemeExtension<dynamic>>[AppColors.light]),
      home: const Scaffold(
        body: Column(
          children: <Widget>[
            MarkdownBubble(text: 'legacy markdown body'),
            StreamingText(
              text: 'streamed body',
              streaming: false,
              style: TextStyle(fontFamily: 'a-different-caller-font'),
            ),
          ],
        ),
      ),
    ));

    final Iterable<RichText> richTexts =
        tester.widgetList<RichText>(find.byType(RichText));
    expect(
      richTexts.any((RichText value) =>
          value.text.toPlainText().contains('legacy markdown body') &&
          value.text.style?.fontFamily == xDotFontFamily),
      isTrue,
    );
    expect(
      richTexts.any((RichText value) =>
          value.text.toPlainText().contains('streamed body') &&
          value.text.style?.fontFamily == xDotFontFamily),
      isTrue,
    );
  });
}
