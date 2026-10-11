import 'dart:io';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'bubble.dart';
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
        return _GeneratingBox(ratio: ratio);
      case GenPhase.done:
        if (result == null || result!.isEmpty) {
          return _GeneratingBox(ratio: ratio);
        }
        return _ResultImage(path: result!, ratio: ratio);
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

/// Kotak pilih rasio: gradasi, kecil membulat, tanpa border.
class _RatioBox extends StatelessWidget {
  final String ratio;
  final ValueChanged<String>? onPick;
  const _RatioBox({required this.ratio, this.onPick});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final List<String> ratios = ['auto', ...kGenRatios.keys];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [c.accent, c.accentEnd]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rasio',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final String r in ratios)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      onPick == null ? null : () => onPick!(r),
                  child: AnimatedContainer(
                    duration: AppDims.animMed,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: ratio == r
                          ? Colors.white
                          : Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      r == 'auto' ? 'Otomatis (AI)' : r,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ratio == r
                            ? c.accent
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeneratingBox extends StatefulWidget {
  final String ratio;
  const _GeneratingBox({required this.ratio});

  @override
  State<_GeneratingBox> createState() => _GeneratingBoxState();
}

class _GeneratingBoxState extends State<_GeneratingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return AspectRatio(
      aspectRatio: genAspect(widget.ratio == 'auto' ? '1:1' : widget.ratio),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Opacity(
              opacity: 0.45 + 0.4 * _c.value,
              child: const Center(child: TypingBubble()),
            );
          },
        ),
      ),
    );
  }
}

/// Hasil: muncul perlahan selama 2.5 detik.
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
