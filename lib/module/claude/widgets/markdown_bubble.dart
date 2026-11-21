import 'package:flutter/material.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/extension_string.dart';
import '../app_theme.dart';

TextStyle _body(AppColors c) => TextStyle(
      fontFamily: AppDims.fontFamily,
      fontSize: AppDims.chatFontSize,
      height: AppDims.chatLineHeight,
      color: c.textPrimary,
    );

/// Cek murah (tanpa regex) apakah teks benar-benar butuh parser markdown.
/// Mayoritas token streaming adalah prosa polos — jalur cepat ini menghindari
/// parse ulang O(n²) tiap 45 ms saat AI menulis.
bool _needsMarkdown(String s) {
  if (s.isEmpty) return false;
  for (int i = 0; i < s.length; i++) {
    final int code = s.codeUnitAt(i);
    if (code == 0x23 || // #
        code == 0x2A || // * (bold / bullet)
        code == 0x60 || // `
        code == 0x5B || // [
        code == 0x7C || // |
        code == 0x3E || // >
        code == 0x7E || // ~
        code == 0x5F) {
      // _
      return true;
    }
    if (code == 0x2D && i > 0 && s.codeUnitAt(i - 1) == 0x0A) return true;
  }
  return s.startsWith('- ');
}

/// Renderer markdown gaya Le Chat (mesin flutter_markdown).
/// Dioptimalkan untuk streaming: style sheet di-cache, prosa polos pakai Text,
/// dan syntax highlighting ditunda sampai teks selesai.
class MarkdownBubble extends StatefulWidget {
  final String text;

  /// Saat streaming, blok kode dirender polos (tanpa HighlightView yang berat).
  final bool streaming;

  const MarkdownBubble({
    super.key,
    required this.text,
    this.streaming = false,
  });

  @override
  State<MarkdownBubble> createState() => _MarkdownBubbleState();
}

class _MarkdownBubbleState extends State<MarkdownBubble> {
  MarkdownStyleSheet? _sheet;
  Brightness? _sheetBrightness;
  Color? _sheetAccent;

  MarkdownStyleSheet _styleSheet(AppColors c) {
    final bool same =
        _sheet != null && _sheetBrightness == c.brightness && _sheetAccent == c.accent;
    if (same) return _sheet!;
    _sheetBrightness = c.brightness;
    _sheetAccent = c.accent;

    // Tipografi gaya Le Chat: rapi, jarak lega, heading tebal, kode oranye.
    final TextStyle body = _body(c).copyWith(fontSize: 15, height: 1.55);
    final TextStyle heading =
        body.copyWith(fontWeight: FontWeight.w700, color: c.textTitle);
    return _sheet = MarkdownStyleSheet(
      p: body,
      pPadding: const EdgeInsets.only(bottom: 8),
      h1: heading.copyWith(fontSize: 22),
      h1Padding: const EdgeInsets.only(top: 12, bottom: 6),
      h2: heading.copyWith(fontSize: 19),
      h2Padding: const EdgeInsets.only(top: 10, bottom: 5),
      h3: heading.copyWith(fontSize: 17),
      h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h4: heading.copyWith(fontSize: 16),
      h4Padding: const EdgeInsets.only(top: 6, bottom: 4),
      h5: heading.copyWith(fontSize: 15),
      h6: heading.copyWith(fontSize: 14),
      em: body.copyWith(fontStyle: FontStyle.italic),
      strong: body.copyWith(fontWeight: FontWeight.w700),
      del: body.copyWith(decoration: TextDecoration.lineThrough),
      listBullet: body,
      listIndent: 18,
      listBulletPadding: const EdgeInsets.only(right: 6),
      a: body.copyWith(
        color: c.accent,
        decoration: TextDecoration.underline,
      ),
      code: body.copyWith(
        fontSize: 13,
        fontFamily: AppDims.codeFontFamily,
        color: c.accent,
        backgroundColor: c.surfaceSoft,
      ),
      codeblockDecoration: BoxDecoration(
        color: c.brightness == Brightness.light
            ? atomOneLightTheme['root']?.backgroundColor
            : atomOneDarkTheme['root']?.backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      blockquote: body.copyWith(color: c.textMuted),
      blockquoteDecoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: c.accent, width: 3)),
      ),
      blockSpacing: 8,
      tableHead: body.copyWith(fontWeight: FontWeight.w700),
      tableBody: body,
      tableBorder: TableBorder.all(
        color: c.textMuted.withOpacity(0.25),
        width: 1,
      ),
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);

    // Jalur cepat: prosa tanpa konstruksi markdown -> Text biasa,
    // jangan panggil parser flutter_markdown sama sekali.
    if (!_needsMarkdown(widget.text)) {
      return Text(
        widget.text,
        style: _body(c).copyWith(fontSize: 15, height: 1.55),
      );
    }

    return MarkdownBody(
      data: widget.text,
      selectable: false,
      styleSheet: _styleSheet(c),
      builders: {'code': _MuseCodeBuilder(streaming: widget.streaming)},
      onTapLink: (text, href, title) {
        if (href == null) return;
        launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
      },
      imageBuilder: (uri, title, alt) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              uri.toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: c.surfaceSoft,
                  child: Center(
                    child:
                        Icon(Icons.broken_image_outlined, color: c.textMuted),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MuseCodeBuilder extends MarkdownElementBuilder {
  final bool streaming;
  _MuseCodeBuilder({this.streaming = false});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return _CodeBlock(
      code: element.textContent,
      inline: !element.textContent.contains('\n'),
      language: _languageOf(element),
      streaming: streaming,
    );
  }

  String _languageOf(md.Element element) {
    if (element.attributes['class'] != null) {
      final String lg = element.attributes['class'] as String;
      if (lg.length > 9) return lg.substring(9);
    }
    return '';
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final bool inline;
  final String language;
  final bool streaming;
  const _CodeBlock({
    required this.code,
    required this.inline,
    required this.language,
    this.streaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    if (inline) {
      return Text.rich(
        TextSpan(
            text: code,
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppDims.codeFontFamily,
              backgroundColor: c.surfaceSoft,
              color: c.textPrimary,
            )),
      );
    }
    final bool isLight = c.brightness == Brightness.light;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isLight
            ? atomOneLightTheme['root']?.backgroundColor
            : atomOneDarkTheme['root']?.backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          if (streaming)
            // HighlightView melakukan tokenize regex tiap frame: terlalu berat
            // saat teks masih mengalir. Tampilkan monospace polos dulu.
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppDims.codeFontFamily,
                  color: c.textPrimary,
                ),
              ),
            )
          else
            HighlightView(
              code,
              language: language,
              theme: isLight ? atomOneLightTheme : atomOneDarkTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(
                  fontSize: 14, fontFamily: AppDims.codeFontFamily),
            ),
          Positioned(
            right: 6,
            top: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => code.toClipboard(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.copy_outlined, size: 16, color: c.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
