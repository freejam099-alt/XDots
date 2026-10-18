import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;

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
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Simpan',
    barrierColor: Colors.black.withOpacity(0.15),
    transitionDuration: AppDims.animMed,
    pageBuilder: (ctx, _, __) {
      final AppColors c = AppColors.of(ctx);
      final Size screen = MediaQuery.sizeOf(ctx);
      final EdgeInsets pad = MediaQuery.paddingOf(ctx);
      final double bottomInset =
          math.max(pad.bottom, MediaQuery.viewInsetsOf(ctx).bottom);
      final double w = math.min(150, math.max(0, screen.width - 32));
      final double usableTop = pad.top + 8;
      final double usableBottom = screen.height - bottomInset - 8;
      final double availableHeight = math.max(0, usableBottom - usableTop);
      final double h = math.min(
        availableHeight,
        math.max(56, MediaQuery.textScalerOf(ctx).scale(16) * 1.4 + 32),
      );
      final double left = (anchor.dx - w / 2)
          .clamp(0.0, math.max(0, screen.width - w))
          .toDouble();
      double top = anchor.dy - h - 12;
      if (top < usableTop) top = anchor.dy + 12;
      top = top
          .clamp(usableTop, math.max(usableTop, usableBottom - h))
          .toDouble();
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
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    color: c.surfaceSoft,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [c.shadowMenu],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const SaveVectorIcon(size: 22),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'Simpan',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
