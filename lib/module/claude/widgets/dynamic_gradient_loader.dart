import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../app_theme.dart';

/// A compact Cupertino-style, borderless gradient loader for long operations.
/// Its own controller animates only this small surface and pauses for reduced
/// motion; it never wraps or rebuilds the surrounding widget tree.
class MuseDynamicGradientLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;
  final Color? indicatorColor;

  const MuseDynamicGradientLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 999,
    this.child,
    this.indicatorColor,
  });

  @override
  State<MuseDynamicGradientLoader> createState() =>
      _MuseDynamicGradientLoaderState();
}

class _MuseDynamicGradientLoaderState extends State<MuseDynamicGradientLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  bool get _shouldAnimate =>
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false) &&
      TickerMode.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color base = colors.surfaceSoft;
    final Widget loaderChild = widget.child ??
        Center(
          child: CupertinoActivityIndicator(
            radius: math.min(widget.height * 0.36, 10),
            color: widget.indicatorColor ?? colors.accent,
            animating: _shouldAnimate,
          ),
        );
    return Semantics(
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double phase = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(-1.2 + phase * 2.4, -0.5),
                end: Alignment(0.8 + phase * 2.4, 0.5),
                colors: [
                  Color.alphaBlend(colors.accent.withOpacity(0.18), base),
                  base,
                  Color.alphaBlend(colors.accentEnd.withOpacity(0.24), base),
                  Color.alphaBlend(colors.accent.withOpacity(0.18), base),
                ],
                stops: const [0, 0.38, 0.72, 1],
              ),
            ),
            child: child,
          );
        },
        child: loaderChild,
      ),
    );
  }
}
