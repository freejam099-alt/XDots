import 'package:flutter/material.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/extension_string.dart';
import '../app_theme.dart';

/// Renderer markdown gaya Muse (mesin sama dengan sistem: flutter_markdown).
/// Teks bisa dipilih (selectable), link bisa diketuk, blok kode ada tombol salin.
/// Semua warna dari [AppColors].
class MarkdownBubble extends StatelessWidget {
  final String text;

  const MarkdownBubble({super.key, required this.text});

  TextStyle _body(AppColors c) {
    return TextStyle(
      fontFamily: AppDims.fontFamily,
      fontSize: AppDims.chatFontSize,
      height: AppDims.chatLineHeight,
      color: c.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    // Tipografi gaya Le Chat: rapi, jarak lega, heading tebal, kode oranye.
    final TextStyle body = _body(c).copyWith(fontSize: 15, height: 1.55);
    final TextStyle heading =
        body.copyWith(fontWeight: FontWeight.w700, color: c.textTitle);
    return MarkdownBody(
      data: text,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
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
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      builders: {
        'code': _MuseCodeBuilder(),
      },
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
  _MuseCodeBuilder();

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return _CodeBlock(
        code: element.textContent,
        inline: !element.textContent.contains('\n'),
        language: _languageOf(element));
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
  const _CodeBlock(
      {required this.code, required this.inline, required this.language});

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
