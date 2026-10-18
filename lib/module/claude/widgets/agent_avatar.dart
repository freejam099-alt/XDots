import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// The real activity currently reported by the assistant runtime.
///
/// This is presentation-only: callers should pass the actual runtime state,
/// not a guessed/demo state.
enum AgentActivity { idle, thinking, browsing, tool, approval, error }

/// A small native, animated assistant character.
///
/// Its soft radial silhouette and simple two-eye face are adapted from the
/// profile/face approach in Bloub (MIT); the Flutter path and animation below
/// are a compact, independent implementation.
class AgentAvatar extends StatefulWidget {
  final AgentActivity activity;
  final double size;

  const AgentAvatar({
    super.key,
    required this.activity,
    this.size = 48.4,
  }) : assert(size > 0);

  @override
  State<AgentAvatar> createState() => _AgentAvatarState();
}

class _AgentAvatarState extends State<AgentAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionAllowed = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AgentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    final bool allowed =
        TickerMode.of(context) && !MediaQuery.of(context).disableAnimations;
    if (allowed == _motionAllowed &&
        (allowed ? _controller.isAnimating : !_controller.isAnimating)) {
      return;
    }
    _motionAllowed = allowed;
    if (allowed) {
      _controller.repeat();
    } else {
      _controller.stop(canceled: false);
      _controller.value = 0;
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
    final Color skin = switch (widget.activity) {
      AgentActivity.idle => colors.avatarBg,
      AgentActivity.thinking => colors.accent,
      AgentActivity.browsing => colors.linkGreen,
      AgentActivity.tool => colors.accentEnd,
      AgentActivity.approval => colors.seatSelected,
      AgentActivity.error => colors.pdfRed,
    };

    return Semantics(
      image: true,
      label: 'Assistant ${_activityLabel(widget.activity)}',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) => CustomPaint(
            painter: _AgentAvatarPainter(
              activity: widget.activity,
              progress: _motionAllowed ? _controller.value : 0,
              skin: skin,
              eyeColor: colors.textTitle,
            ),
          ),
        ),
      ),
    );
  }
}

String _activityLabel(AgentActivity activity) => switch (activity) {
      AgentActivity.idle => 'ready',
      AgentActivity.thinking => 'thinking',
      AgentActivity.browsing => 'browsing',
      AgentActivity.tool => 'using a tool',
      AgentActivity.approval => 'awaiting approval',
      AgentActivity.error => 'encountered an error',
    };

class _AgentAvatarPainter extends CustomPainter {
  final AgentActivity activity;
  final double progress;
  final Color skin;
  final Color eyeColor;

  const _AgentAvatarPainter({
    required this.activity,
    required this.progress,
    required this.skin,
    required this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double phase = progress * math.pi * 2;
    final double width = size.width;
    final double height = size.height;
    final double activityWave = switch (activity) {
      AgentActivity.idle => 0.20,
      AgentActivity.thinking => 0.56,
      AgentActivity.browsing => 0.42,
      AgentActivity.tool => 0.64,
      AgentActivity.approval => 0.32,
      AgentActivity.error => 0.12,
    };
    final double motion = switch (activity) {
      AgentActivity.idle => 0.018 * math.sin(phase),
      AgentActivity.thinking => 0.035 * math.sin(phase * 1.25),
      AgentActivity.browsing => 0.025 * math.sin(phase * 1.6),
      AgentActivity.tool => 0.045 * math.sin(phase * 1.4),
      AgentActivity.approval => 0.025 * math.sin(phase * 2),
      AgentActivity.error => 0.008 * math.sin(phase),
    };

    final Path blob = _blobPath(
      Rect.fromLTWH(width * 0.07, height * 0.055, width * 0.86, height * 0.88),
      phase * activityWave,
      motion,
    );
    canvas.drawPath(blob, Paint()..color = skin);

    final double eyeY = height * 0.45;
    final double eyeRadius = math.max(
      1.4,
      size.shortestSide * (activity == AgentActivity.tool ? 0.066 : 0.058),
    );
    double gazeX = 0;
    if (activity == AgentActivity.thinking) {
      gazeX = -size.width * 0.025;
    } else if (activity == AgentActivity.browsing) {
      gazeX = size.width * 0.035 * math.sin(phase);
    }
    final double blink = activity == AgentActivity.approval
        ? (0.28 + 0.72 * (0.5 + 0.5 * math.cos(phase * 2)))
        : 1;
    final Paint eyes = Paint()..color = eyeColor;
    for (final double side in const <double>[-1, 1]) {
      final Rect eyeRect = Rect.fromCenter(
        center: Offset(width * (0.39 + (side > 0 ? 0.22 : 0)) + gazeX,
            eyeY + (activity == AgentActivity.thinking ? -height * 0.018 : 0)),
        width: eyeRadius * 1.45,
        height: math.max(eyeRadius * 0.45, eyeRadius * 2 * blink),
      );
      canvas.drawOval(eyeRect, eyes);
    }

    final Paint expression = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.shortestSide * 0.035)
      ..strokeCap = StrokeCap.round;
    final Path mouth = Path();
    switch (activity) {
      case AgentActivity.idle:
        mouth
          ..moveTo(width * 0.39, height * 0.64)
          ..quadraticBezierTo(
              width * 0.5, height * 0.75, width * 0.61, height * 0.64);
        canvas.drawPath(mouth, expression);
      case AgentActivity.approval:
        mouth
          ..moveTo(width * 0.37, height * 0.63)
          ..quadraticBezierTo(
              width * 0.5, height * 0.77, width * 0.63, height * 0.63);
        canvas.drawPath(mouth, expression);
        final Paint cheek = Paint()..color = eyeColor.withOpacity(0.55);
        canvas.drawCircle(Offset(width * 0.31, height * 0.62),
            size.shortestSide * 0.027, cheek);
        canvas.drawCircle(Offset(width * 0.69, height * 0.62),
            size.shortestSide * 0.027, cheek);
      case AgentActivity.thinking:
        mouth
          ..moveTo(width * 0.43, height * 0.68)
          ..quadraticBezierTo(
              width * 0.5, height * 0.65, width * 0.57, height * 0.68);
        canvas.drawPath(mouth, expression);
        final Paint thinkingBrow = Paint()
          ..color = eyeColor
          ..strokeWidth = expression.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(width * 0.31, height * 0.34),
            Offset(width * 0.43, height * 0.31), thinkingBrow);
        canvas.drawLine(Offset(width * 0.57, height * 0.31),
            Offset(width * 0.69, height * 0.34), thinkingBrow);
      case AgentActivity.browsing:
        canvas.drawCircle(
          Offset(width * 0.5, height * 0.68),
          size.shortestSide * 0.045,
          Paint()..color = eyeColor,
        );
        final Paint raisedBrow = Paint()
          ..color = eyeColor
          ..strokeWidth = expression.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(width * 0.57, height * 0.30),
            Offset(width * 0.69, height * 0.32), raisedBrow);
      case AgentActivity.tool:
        mouth
          ..moveTo(width * 0.38, height * 0.63)
          ..quadraticBezierTo(
              width * 0.5, height * 0.79, width * 0.62, height * 0.63)
          ..close();
        canvas.drawPath(mouth, Paint()..color = eyeColor);
      case AgentActivity.error:
        mouth
          ..moveTo(width * 0.40, height * 0.70)
          ..quadraticBezierTo(
              width * 0.5, height * 0.62, width * 0.60, height * 0.70);
        canvas.drawPath(mouth, expression);
        final Paint brow = Paint()
          ..color = eyeColor
          ..strokeWidth = expression.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(width * 0.31, height * 0.32),
            Offset(width * 0.43, height * 0.35), brow);
        canvas.drawLine(Offset(width * 0.57, height * 0.35),
            Offset(width * 0.69, height * 0.32), brow);
    }
  }

  Path _blobPath(Rect bounds, double phase, double amplitude) {
    const int samples = 32;
    final List<Offset> points = List<Offset>.generate(samples, (int index) {
      final double angle = (index / samples) * math.pi * 2 - math.pi / 2;
      final double lobes = math.sin(angle * 3 + phase) * 0.045 +
          math.sin(angle * 5 - phase * 0.72) * 0.025;
      final double idleBreath = math.sin(angle * 2 + phase * 0.6) * amplitude;
      final double radius = 0.92 + lobes + idleBreath;
      return Offset(
        bounds.center.dx + math.cos(angle) * bounds.width * 0.5 * radius,
        bounds.center.dy + math.sin(angle) * bounds.height * 0.5 * radius,
      );
    });
    final Offset firstMid = Offset(
      (points.last.dx + points.first.dx) / 2,
      (points.last.dy + points.first.dy) / 2,
    );
    final Path path = Path()..moveTo(firstMid.dx, firstMid.dy);
    for (int i = 0; i < samples; i++) {
      final Offset point = points[i];
      final Offset next = points[(i + 1) % samples];
      path.quadraticBezierTo(
        point.dx,
        point.dy,
        (point.dx + next.dx) / 2,
        (point.dy + next.dy) / 2,
      );
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _AgentAvatarPainter oldDelegate) =>
      activity != oldDelegate.activity ||
      progress != oldDelegate.progress ||
      skin != oldDelegate.skin ||
      eyeColor != oldDelegate.eyeColor;
}
