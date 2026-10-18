import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'save_menu.dart';
import 'tool_card.dart';

/// Fase generasi gambar/video.
enum GenPhase { thinking, prompting, ratio, generating, done }

/// Rasio yang didukung (string -> aspect).
const Map<String, double> kGenRatios = {
  '1:1': 1.0,
  '16:9': 16 / 9,
  '9:16': 9 / 16,
  '3:4': 3 / 4,
  '4:3': 4 / 3,
};

double genAspect(String ratio) => kGenRatios[ratio] ?? 1.0;

/// Kartu alur generasi: berpikir -> susun prompt -> pilih rasio
/// (atau otomatis AI) -> model membuat -> hasil fade-in 2.5 detik.
/// Kotak rasio tanpa border, gradasi, kecil membulat ala ChatGPT.
class GenCard extends StatelessWidget {
  final bool isVideo;
  final bool showActivity;
  final GenPhase phase;
  final String prompt;
  final String ratio;
  final String? result;
  final ValueChanged<String>? onRatioPick;

  const GenCard({
    super.key,
    required this.isVideo,
    required this.phase,
    this.showActivity = true,
    this.prompt = '',
    this.ratio = 'auto',
    this.result,
    this.onRatioPick,
  });

  String get _toolName => isVideo ? 'create_video' : 'create_image';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showActivity)
          ToolCallCard(
            toolName: _toolName,
            detail: _phaseLabel(),
            status:
                phase == GenPhase.done ? ToolStatus.done : ToolStatus.running,
          ),
        if (phase == GenPhase.done || phase == GenPhase.ratio) ...[
          if (showActivity) const SizedBox(height: 8),
          _phaseBody(context),
        ],
      ],
    );
  }

  String _phaseLabel() {
    switch (phase) {
      case GenPhase.thinking:
        return 'Berpikir...';
      case GenPhase.prompting:
        return 'Menyusun prompt...';
      case GenPhase.ratio:
        return 'Pilih rasio';
      case GenPhase.generating:
        return 'Model ${isVideo ? 'video' : 'gambar'} membuat...';
      case GenPhase.done:
        return 'Selesai';
    }
  }

  Widget _phaseBody(BuildContext context) {
    switch (phase) {
      case GenPhase.thinking:
        return const SizedBox.shrink();
      case GenPhase.prompting:
        return const SizedBox.shrink();
      case GenPhase.ratio:
        return _RatioBox(
          ratio: ratio,
          onPick: onRatioPick,
        );
      case GenPhase.generating:
        return const SizedBox.shrink();
      case GenPhase.done:
        if (result == null || result!.isEmpty) {
          final AppColors c = AppColors.of(context);
          return _Sized(
            ratio: ratio,
            child: AspectRatio(
              aspectRatio: _aspectOf(ratio),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_present_outlined,
                          color: c.textMuted, size: 30),
                      const SizedBox(height: 8),
                      Text('Hasil tidak tersedia',
                          style: TextStyle(color: c.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return _Sized(
          ratio: ratio,
          child: GestureDetector(
            onLongPressStart: (d) => showSaveMenu(context, d.globalPosition,
                path: result!, isVideo: isVideo),
            child: isVideo
                ? _ResultVideo(path: result!, ratio: ratio)
                : _ResultImage(path: result!, ratio: ratio),
          ),
        );
    }
  }
}

double _aspectOf(String ratio) => genAspect(ratio == 'auto' ? '1:1' : ratio);

/// Lebar kotak: penuh untuk lanskap/persegi, dibatasi untuk potret.
double _boxWidth(double maxW, double aspect) {
  final double cap = 420 * aspect;
  return aspect < 1 && cap < maxW ? cap : maxW;
}

/// Kotak hasil rata kiri dengan lebar sesuai rasio.
class _Sized extends StatelessWidget {
  final String ratio;
  final Widget child;
  const _Sized({required this.ratio, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final double maxW = cons.maxWidth.isFinite ? cons.maxWidth : 300;
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: _boxWidth(maxW, _aspectOf(ratio)), child: child),
      );
    });
  }
}

/// Kotak rasio tumbuh dari sudut kiri-atas bubble AI (kecil membulat)
/// lalu membentuk rasio gambar/video yang akan dibuat.
class _RatioBox extends StatelessWidget {
  final String ratio;
  final ValueChanged<String>? onPick;
  const _RatioBox({required this.ratio, this.onPick});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final double target = _aspectOf(ratio);
    return LayoutBuilder(builder: (context, cons) {
      final double maxW = cons.maxWidth.isFinite ? cons.maxWidth : 300;
      final double fullW = _boxWidth(maxW, target);
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 950),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final double w = 44 + (fullW - 44) * t;
          final double aspect = 1.0 + (target - 1.0) * t;
          return Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: w,
              height: w / aspect,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22 - 8 * t),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.surface, c.surfaceSoft, c.surface],
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: t,
                  child: Text(ratio == 'auto' ? '1:1' : ratio,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted)),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _ResultImage extends StatefulWidget {
  final String path;
  final String ratio;
  const _ResultImage({required this.path, required this.ratio});

  @override
  State<_ResultImage> createState() => _ResultImageState();
}

class _ResultImageState extends State<_ResultImage> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool network =
        widget.path.startsWith('http://') || widget.path.startsWith('https://');
    return AspectRatio(
      aspectRatio: genAspect(widget.ratio == 'auto' ? '1:1' : widget.ratio),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 2500),
        curve: Curves.easeOutCubic,
        opacity: _opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: network
              ? Image.network(
                  widget.path,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    final AppColors c = AppColors.of(context);
                    return Container(
                      color: c.surfaceSoft,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: c.textMuted),
                      ),
                    );
                  },
                )
              : Image.file(
                  File(widget.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    final AppColors c = AppColors.of(context);
                    return Container(
                      color: c.surfaceSoft,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: c.textMuted),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Hasil video: kartu kecil, ketuk untuk membuka (URL -> browser/pemutar,
/// file lokal -> bagikan ke aplikasi pemutar).
class _ResultVideo extends StatelessWidget {
  final String path;
  final String ratio;
  const _ResultVideo({required this.path, required this.ratio});

  Future<void> _open() async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      await launchUrl(Uri.parse(path), mode: LaunchMode.externalApplication);
    } else {
      await Share.shareXFiles([XFile(path)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return AspectRatio(
      aspectRatio: genAspect(ratio == 'auto' ? '16:9' : ratio),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill_rounded, size: 52, color: c.accent),
              const SizedBox(height: 8),
              Text('Video siap, ketuk untuk membuka',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
