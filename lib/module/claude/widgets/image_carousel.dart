import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'save_menu.dart';

/// Galeri gambar hasil pencarian: baris horizontal yang bisa digeser.
/// Ketuk = lihat besar, tekan lama = popup Simpan.
class ImageCarousel extends StatelessWidget {
  final List<String> urls;
  const ImageCarousel({super.key, required this.urls});

  void _open(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        onLongPressStart: (d) => showSaveMenu(ctx, d.globalPosition,
            path: urls[index], isVideo: false),
        child: Center(
          child: InteractiveViewer(
            child: Image.network(urls[index], fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final AppColors c = AppColors.of(context);
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _open(context, i),
            onLongPressStart: (d) => showSaveMenu(context, d.globalPosition,
                path: urls[i], isVideo: false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 190,
                height: 150,
                child: Image.network(
                  urls[i],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(color: c.surfaceSoft);
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: c.surfaceSoft,
                    child: Icon(Icons.broken_image_outlined,
                        color: c.textMuted),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
