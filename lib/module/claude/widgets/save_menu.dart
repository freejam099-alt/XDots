import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../app_theme.dart';
import 'vector_icons.dart';

/// Simpan gambar/video ke galeri. URL diunduh dulu ke cache.
Future<void> saveMediaToGallery(String path, bool isVideo) async {
  String file = path;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    final dir = await getTemporaryDirectory();
    file =
        '${dir.path}/dl_${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'png'}';
    await Dio().download(path, file);
  }
  if (isVideo) {
    await Gal.putVideo(file);
  } else {
    await Gal.putImage(file);
  }
}

/// Tekan lama gambar/video -> popup kecil "Simpan" di dekat jari.
Future<void> showSaveMenu(
  BuildContext context,
  Offset anchor, {
  required String path,
  required bool isVideo,
}) {
  const double w = 150;
  const double h = 56;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Simpan',
    barrierColor: Colors.black.withOpacity(0.15),
    transitionDuration: AppDims.animMed,
    pageBuilder: (ctx, _, __) {
      final AppColors c = AppColors.of(ctx);
      final Size screen = MediaQuery.sizeOf(ctx);
      final double left =
          (anchor.dx - w / 2).clamp(16.0, screen.width - w - 16.0).toDouble();
      double top = anchor.dy - h - 12;
      if (top < MediaQuery.paddingOf(ctx).top + 8) top = anchor.dy + 12;
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: left,
            top: top,
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: AppDims.fontFamily),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await saveMediaToGallery(path, isVideo);
                      Fluttertoast.showToast(
                          msg: isVideo
                              ? 'Video disimpan ke galeri'
                              : 'Gambar disimpan ke galeri');
                    } catch (_) {
                      Fluttertoast.showToast(msg: 'Gagal menyimpan');
                    }
                  },
                  child: Container(
                    width: w,
                    height: h,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [c.shadowFloat],
                    ),
                    child: Row(
                      children: [
                        const SaveVectorIcon(size: 22),
                        const SizedBox(width: 12),
                        Text('Simpan',
                            style: TextStyle(
                                fontSize: 16, color: c.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final CurvedAnimation curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
