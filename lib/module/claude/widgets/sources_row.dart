import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';

String _host(String url) {
  final Uri? u = Uri.tryParse(url);
  String h = u?.host ?? url;
  if (h.startsWith('www.')) h = h.substring(4);
  return h;
}

/// Sumber hasil pencarian web: ikon favicon provider bertumpuk
/// di ujung bubble AI. Ketuk untuk melihat daftar sumber.
class SourcesRow extends StatelessWidget {
  final List<String> urls;
  const SourcesRow({super.key, required this.urls});

  Widget _icon(AppColors c, String url) {
    final String host = _host(url);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        shape: BoxShape.circle,
        border: Border.all(color: c.aiBubble, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          'https://www.google.com/s2/favicons?domain=$host&sz=64',
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(host.isEmpty ? '?' : host[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: c.textMuted)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final AppColors c = AppColors.of(context);
    final List<String> shown = urls.take(5).toList();
    final double stackW = 24.0 + (shown.length - 1) * 16.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openList(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: stackW,
            height: 24,
            child: Stack(
              children: [
                for (int i = shown.length - 1; i >= 0; i--)
                  Positioned(left: i * 16.0, child: _icon(c, shown[i])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${urls.length} sumber',
              style: TextStyle(fontSize: 12, color: c.textMuted)),
        ],
      ),
    );
  }

  void _openList(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final AppColors c = AppColors.of(ctx);
        return Dialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sumber',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final String u in urls)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => launchUrl(Uri.parse(u),
                              mode: LaunchMode.externalApplication),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _icon(c, u),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(_host(u),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: c.textPrimary)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
