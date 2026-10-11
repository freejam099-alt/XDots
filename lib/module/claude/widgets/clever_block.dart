import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import 'markdown_bubble.dart';

final RegExp _kUrlRegExp = RegExp(r'https?://[^\s)]+');

bool _isImageUrl(String url) {
  final String u = url.toLowerCase().split('?').first;
  return u.endsWith('.png') ||
      u.endsWith('.jpg') ||
      u.endsWith('.jpeg') ||
      u.endsWith('.gif') ||
      u.endsWith('.webp');
}

bool _isVideoUrl(String url) {
  final String u = url.toLowerCase();
  return u.endsWith('.mp4') ||
      u.endsWith('.mov') ||
      u.endsWith('.webm') ||
      u.contains('youtube.com/watch') ||
      u.contains('youtu.be/') ||
      u.contains('vimeo.com/');
}

String _domainOf(String url) {
  try {
    return Uri.parse(url).host;
  } catch (_) {
    return url;
  }
}

/// "UI Clever": memecah teks AI menjadi blok cerdas dan interaktif —
/// teks (markdown), kartu link, gambar (tap untuk pratinjau),
/// video (tap untuk buka), dan grid otomatis untuk gambar berurutan.
class CleverMessage extends StatelessWidget {
  final String text;

  const CleverMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final List<_Block> blocks = _parse(text);
    if (blocks.length == 1 && blocks.first is _TextBlock) {
      return MarkdownBubble(text: (blocks.first as _TextBlock).text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          _buildBlock(blocks, i),
          if (i != blocks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildBlock(List<_Block> blocks, int i) {
    final _Block b = blocks[i];
    if (b is _TextBlock) {
      if (b.text.trim().isEmpty) return const SizedBox.shrink();
      return MarkdownBubble(text: b.text);
    }
    if (b is _ImageGroupBlock) {
      if (b.urls.length > 1) return _ImageGrid(urls: b.urls);
      return _ImageCard(url: b.urls.first);
    }
    if (b is _VideoBlock) return _VideoCard(url: b.url);
    if (b is _LinkBlock) return _LinkCard(url: b.url);
    return const SizedBox.shrink();
  }
}

List<_Block> _parse(String text) {
  final List<_Block> out = [];
  int cursor = 0;
  final List<RegExpMatch> matches = _UrlRegExpAll(text);
  for (final RegExpMatch m in matches) {
    if (m.start > cursor) {
      out.add(_TextBlock(text.substring(cursor, m.start)));
    }
    final String url = m.group(0)!;
    if (_isImageUrl(url)) {
      out.add(_ImageBlock(url));
    } else if (_isVideoUrl(url)) {
      out.add(_VideoBlock(url));
    } else {
      out.add(_LinkBlock(url));
    }
    cursor = m.end;
  }
  if (cursor < text.length) {
    out.add(_TextBlock(text.substring(cursor)));
  }
  if (out.isEmpty) out.add(_TextBlock(text));
  return _groupImages(out);
}

/// Gambar berurutan (hanya dipisah spasi) digabung jadi satu grup grid.
List<_Block> _groupImages(List<_Block> src) {
  final List<_Block> out = [];
  List<String> group = [];
  void flush() {
    if (group.isNotEmpty) {
      out.add(_ImageGroupBlock(List.of(group)));
      group = [];
    }
  }

  for (final _Block b in src) {
    if (b is _ImageBlock) {
      group.add(b.url);
    } else if (b is _TextBlock && b.text.trim().isEmpty) {
      continue;
    } else {
      flush();
      out.add(b);
    }
  }
  flush();
  return out;
}

List<RegExpMatch> _UrlRegExpAll(String text) {
  return _kUrlRegExp.allMatches(text).toList();
}

abstract class _Block {
  const _Block();
}

class _TextBlock extends _Block {
  final String text;
  const _TextBlock(this.text);
}

/// Blok mentah hasil parse, digabung jadi grup di [_groupImages].
class _ImageBlock extends _Block {
  final String url;
  const _ImageBlock(this.url);
}

class _ImageGroupBlock extends _Block {
  final List<String> urls;
  const _ImageGroupBlock(this.urls);
}

class _VideoBlock extends _Block {
  final String url;
  const _VideoBlock(this.url);
}

class _LinkBlock extends _Block {
  final String url;
  const _LinkBlock(this.url);
}

Future<void> _openUrl(String url) {
  return launchUrl(Uri.parse(url),
      mode: LaunchMode.externalApplication);
}

class _LinkCard extends StatelessWidget {
  final String url;
  const _LinkCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openUrl(url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [c.shadowFloat],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.public,
                  color: c.accent, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _domainOf(url),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    url,
                    style: TextStyle(
                        fontSize: 13, color: c.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new,
                size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String url;
  final double height;
  const _ImageCard({required this.url, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _previewImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: height,
              color: c.surfaceSoft,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              color: c.surfaceSoft,
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    color: c.textMuted),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: urls.length,
      itemBuilder: (context, i) {
        return _ImageCard(url: urls[i], height: 140);
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String url;
  const _VideoCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openUrl(url),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2B),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.play_circle_fill,
                size: 56, color: Colors.white),
            Positioned(
              left: 12,
              bottom: 10,
              right: 12,
              child: Text(
                _domainOf(url),
                style: TextStyle(
                    fontSize: 13, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _previewImage(BuildContext context, String url) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      );
    },
  );
}
