import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'bubble.dart';
import 'save_menu.dart';
import 'streaming_text.dart';
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
  final GenPhase phase;
  final String prompt;
  final String ratio;
  final String? result;
  final ValueChanged<String>? onRatioPick;

  const GenCard({
    super.key,
    required this.isVideo,
    required this.phase,
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
        ToolCallCard(
          toolName: _toolName,
          detail: _phaseLabel(),
          status: phase == GenPhase.done
              ? ToolStatus.done
              : ToolStatus.running,
        ),
        const SizedBox(height: 8),
        _phaseBody(context),
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
        return const TypingBubble();
      case GenPhase.prompting:
        return _PromptBubble(prompt: prompt);
      case GenPhase.ratio:
        return _RatioBox(
          ratio: ratio,
          onPick: onRatioPick,
        );
      case GenPhase.generating:
        return _GeneratingBox(ratio: ratio, isVideo: isVideo);
      case GenPhase.done:
        if (result == null || result!.isEmpty) {
          return _GeneratingBox(ratio: ratio, isVideo: isVideo);
        }
        return _Sized(
          ratio: ratio,
          child: GestureDetector(
            onLongPressStart: (d) => showSaveMenu(
                context, d.globalPosition,
                path: result!, isVideo: isVideo),
            child: isVideo
                ? _ResultVideo(path: result!, ratio: ratio)
                : _ResultImage(path: result!, ratio: ratio),
          ),
        );
    }
  }
}

class _PromptBubble extends StatelessWidget {
  final String prompt;
  const _PromptBubble({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.aiBubble,
        borderRadius: BorderRadius.circular(AppDims.bubbleRadius),
      ),
      child: StreamingText(text: prompt),
    );
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
        child: SizedBox(
            width: _boxWidth(maxW, _aspectOf(ratio)), child: child),
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

/// Saat membuat: gambar = kilau gradasi bergerak, video = border beam.
class _GeneratingBox extends StatefulWidget {
  final String ratio;
  final bool isVideo;
  const _GeneratingBox({required this.ratio, required this.isVideo});

  @override
  State<_GeneratingBox> createState() => _GeneratingBoxState();
}

class _GeneratingBoxState extends State<_GeneratingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final double aspect = _aspectOf(widget.ratio);
    return LayoutBuilder(builder: (context, cons) {
      final double maxW = cons.maxWidth.isFinite ? cons.maxWidth : 300;
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _boxWidth(maxW, aspect),
          child: AspectRatio(
            aspectRatio: aspect,
            child: AnimatedBuilder(
              animation: _ac,
              builder: (context, _) {
                final double t = _ac.value;
                final Widget dots = Center(
                  child: LoadingAnimationWidget.prograssiveDots(
                      color: c.accent, size: 30),
                );
                if (widget.isVideo) {
                  return CustomPaint(
                    painter: _BeamPainter(t: t, fill: c.surface, accent: c.accent),
                    child: dots,
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment(-1.8 + 3.6 * t, -1),
                      end: Alignment(-0.6 + 3.6 * t, 1),
                      colors: [c.surface, c.surfaceSoft, c.surface],
                    ),
                  ),
                  child: dots,
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

/// Border beam: sinar gradasi berputar mengelilingi tepi kotak.
class _BeamPainter extends CustomPainter {
  final double t;
  final Color fill;
  final Color accent;
  _BeamPainter({required this.t, required this.fill, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rr =
        RRect.fromRectAndRadius(rect, const Radius.circular(14)).deflate(2);
    canvas.drawRRect(rr, Paint()..color = fill);
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withOpacity(0.16));
    final Shader sweep = SweepGradient(
      colors: [
        const Color(0x00FFFFFF),
        accent,
        const Color(0xFFB388FF),
        const Color(0xFF4DD0E1),
        const Color(0xFFFF80AB),
        const Color(0x00FFFFFF),
      ],
      stops: const [0.0, 0.1, 0.26, 0.42, 0.56, 0.68],
      transform: GradientRotation(t * 2 * math.pi),
    ).createShader(rect);
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = sweep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = sweep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) => old.t != t;
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
              Icon(Icons.play_circle_fill_rounded,
                  size: 52, color: c.accent),
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
