import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// The real activity currently reported by the assistant runtime.
///
/// This is presentation-only: callers should pass the actual runtime state,
/// not a guessed/demo state.
enum AgentActivity {
  idle,
  thinking,
  browsing,
  tool,
  approval,
  error,
  frustrated,
  crying
}

/// A small native, animated assistant character.
class AgentAvatar extends StatefulWidget {
  final AgentActivity activity;
  final double size;

  /// Default size is 10% larger than the former 48.4 logical-pixel avatar.
  const AgentAvatar({
    super.key,
    required this.activity,
    this.size = 53.24,
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
      duration: const Duration(milliseconds: 2100),
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
    return Semantics(
      image: true,
      label: 'Assistant ${_activityLabel(widget.activity)}',
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AgentAvatarPainter(
              activity: widget.activity,
              animation: _controller,
              skin: const Color(0xFF429DFA),
              ink: const Color(0xFF1A1A1A),
              accent: colors.accent,
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
      AgentActivity.frustrated => 'frustrated by a temporary failure',
      AgentActivity.crying => 'crying after a failed request',
    };

/// Painter is directly subscribed to the avatar's ticker. Its repaint is
/// contained by a RepaintBoundary, so animation frames never rebuild or dirty
/// the surrounding chat page.
class _AgentAvatarPainter extends CustomPainter {
  final AgentActivity activity;
  final Animation<double> animation;
  final Color skin;
  final Color ink;
  final Color accent;

  _AgentAvatarPainter({
    required this.activity,
    required this.animation,
    required this.skin,
    required this.ink,
    required this.accent,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final double t = animation.value;
    final double phase = t * math.pi * 2;
    final double breath = switch (activity) {
      AgentActivity.idle => math.sin(phase) * 0.014,
      AgentActivity.thinking => math.sin(phase * 0.72) * 0.009,
      AgentActivity.browsing => math.sin(phase) * 0.012,
      AgentActivity.tool => math.sin(phase * 0.8) * 0.01,
      AgentActivity.approval => math.sin(phase * 0.65) * 0.008,
      AgentActivity.error => math.sin(phase * 0.5) * 0.006,
      AgentActivity.frustrated => math.sin(phase * 0.5) * 0.004,
      AgentActivity.crying => math.sin(phase * 0.5) * 0.005,
    };
    final double tilt = switch (activity) {
      AgentActivity.idle => 0.012 * math.sin(phase * 0.5),
      AgentActivity.thinking => -0.025 + 0.012 * math.sin(phase * 0.5),
      AgentActivity.browsing => 0.016 * math.sin(phase),
      AgentActivity.tool => 0.008 * math.sin(phase),
      AgentActivity.approval => 0.012 * math.sin(phase * 0.5),
      AgentActivity.error => -0.012,
      AgentActivity.frustrated => 0.006 * math.sin(phase * 0.7),
      AgentActivity.crying => -0.01 + 0.004 * math.sin(phase * 0.5),
    };

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(tilt);
    canvas.scale(1 + breath);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.save();
    canvas.scale(size.width / 99, size.height / 98);

    // The supplied SVG's asymmetric, softly rounded eight-point silhouette.
    final Path star = Path()
      ..moveTo(34.2773, 14.5035)
      ..cubicTo(36.3307, 10.9214, 40.9176, 9.69249, 44.5224, 11.7584)
      ..lineTo(53.2846, 16.7807)
      ..lineTo(63.0127, 14.174)
      ..cubicTo(67.0137, 13.102, 71.1465, 15.4708, 72.2436, 19.465)
      ..lineTo(74.9111, 29.1766)
      ..lineTo(83.6865, 34.2065)
      ..cubicTo(87.2913, 36.2728, 88.549, 40.8519, 86.4958, 44.4342)
      ..lineTo(81.4973, 53.1548)
      ..lineTo(84.1625, 62.8579)
      ..cubicTo(85.2595, 66.852, 82.9055, 70.9591, 78.9046, 72.0312)
      ..lineTo(69.1849, 74.6355)
      ..lineTo(64.1878, 83.3537)
      ..cubicTo(62.1344, 86.9357, 57.5475, 88.1649, 53.9428, 86.0989)
      ..lineTo(45.1698, 81.0704)
      ..lineTo(35.4379, 83.678)
      ..cubicTo(31.437, 84.75, 27.3042, 82.3811, 26.207, 78.387)
      ..lineTo(23.5382, 68.6707)
      ..lineTo(14.7796, 63.6505)
      ..cubicTo(11.1747, 61.5842, 9.91696, 57.0052, 11.9703, 53.4228)
      ..lineTo(16.959, 44.718)
      ..lineTo(14.2881, 34.9942)
      ..cubicTo(13.191, 31, 15.5451, 26.893, 19.546, 25.8209)
      ..lineTo(29.2864, 23.211)
      ..close();
    canvas.drawPath(star, Paint()..color = skin);

    final bool isError = activity == AgentActivity.error;
    final bool isCrying = activity == AgentActivity.crying || isError;
    final bool isFrustrated = activity == AgentActivity.frustrated;
    final bool isThinking = activity == AgentActivity.thinking;
    final bool isBrowsing = activity == AgentActivity.browsing;
    final bool hasTwoEyes = isFrustrated || isCrying;
    final double gaze = isThinking
        ? -2.3
        : isBrowsing
            ? 1.8 * math.sin(phase)
            : 0;

    // The supplied eye silhouette and pupil; emotional expressions use its
    // mirrored counterpart so both frustrated and crying faces have two open
    // eyes instead of the normal wink.
    final Path sclera = Path()
      ..moveTo(25.369, 50.142)
      ..cubicTo(23.906, 44.816, 27.045, 39.340, 32.380, 37.911)
      ..cubicTo(37.715, 36.481, 43.225, 39.640, 44.688, 44.966)
      ..lineTo(45.570, 48.180)
      ..cubicTo(47.033, 53.505, 43.895, 58.981, 38.560, 60.411)
      ..cubicTo(33.225, 61.840, 27.715, 58.682, 26.252, 53.356)
      ..close();
    final Path pupil = Path()
      ..moveTo(30.199, 48.848)
      ..cubicTo(29.467, 46.185, 31.037, 43.447, 33.704, 42.732)
      ..cubicTo(36.371, 42.018, 39.127, 43.597, 39.858, 46.260)
      ..lineTo(40.741, 49.474)
      ..cubicTo(41.472, 52.136, 39.903, 54.875, 37.236, 55.589)
      ..cubicTo(34.568, 56.304, 31.813, 54.725, 31.082, 52.062)
      ..close();
    for (int eye = 0; eye < (hasTwoEyes ? 2 : 1); eye++) {
      canvas.save();
      if (eye == 1) {
        canvas.translate(100, 0);
        canvas.scale(-1, 1);
      }
      canvas.translate(gaze, 0);
      canvas.drawPath(sclera, Paint()..color = Colors.white);
      canvas.drawPath(pupil, Paint()..color = ink);
      canvas.restore();
    }

    final Paint faceStroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (!hasTwoEyes) {
      final Path rightWink = Path()
        ..moveTo(58.46, 33.01)
        ..quadraticBezierTo(61.95, 30.8, 64.0, 34.2)
        ..quadraticBezierTo(65.2, 36.8, 62.92, 37.99)
        ..lineTo(56.78, 43.45)
        ..lineTo(64.87, 45.10);
      canvas.drawPath(rightWink, faceStroke);
    }

    // Brows and mouth follow the runtime activity; error is an upset, teary
    // expression instead of a fabricated status or random emotional change.
    final Paint browPaint = Paint()
      ..color = ink
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (isFrustrated) {
      // Brows angle down toward the nose, making the frustration unambiguous.
      canvas.drawLine(const Offset(28, 31), const Offset(44, 38), browPaint);
      canvas.drawLine(const Offset(56, 38), const Offset(72, 31), browPaint);
    } else if (isCrying) {
      // Raised inner brows signal sadness; paired tear streaks remain visibly
      // distinct from the dry, clenched frustrated expression.
      canvas.drawLine(const Offset(29, 35), const Offset(43, 30), browPaint);
      canvas.drawLine(const Offset(57, 30), const Offset(71, 35), browPaint);
      final Paint tearPaint = Paint()..color = const Color(0xFFB9E8FF);
      final Path leftTear = Path()
        ..moveTo(28, 56)
        ..cubicTo(25, 61, 25, 68, 29, 71)
        ..cubicTo(33, 68, 32, 61, 30, 56)
        ..close();
      final Path rightTear = Path()
        ..moveTo(70, 56)
        ..cubicTo(67, 61, 67, 68, 71, 71)
        ..cubicTo(75, 68, 74, 61, 72, 56)
        ..close();
      canvas.drawPath(leftTear, tearPaint);
      canvas.drawPath(rightTear, tearPaint);
    } else if (isThinking) {
      canvas.drawLine(const Offset(31, 33), const Offset(42, 31), browPaint);
      canvas.drawLine(const Offset(57, 31), const Offset(68, 33), browPaint);
      canvas.drawCircle(Offset(73 + 2 * math.sin(phase), 29), 1.35,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(78 + 2 * math.sin(phase), 23), 1.0,
          Paint()..color = Colors.white);
    } else if (isBrowsing) {
      canvas.drawLine(const Offset(58, 30), const Offset(69, 32), browPaint);
    }

    final Path mouth = Path();
    switch (activity) {
      case AgentActivity.idle:
        mouth
          ..moveTo(39, 64)
          ..quadraticBezierTo(49.5, 74, 61, 64);
        canvas.drawPath(mouth, faceStroke);
      case AgentActivity.thinking:
        mouth
          ..moveTo(43, 68)
          ..quadraticBezierTo(49.5, 65, 56, 68);
        canvas.drawPath(mouth, faceStroke);
      case AgentActivity.browsing:
        canvas.drawCircle(const Offset(51, 68), 2.25, Paint()..color = ink);
      case AgentActivity.tool:
        mouth
          ..moveTo(40, 64)
          ..quadraticBezierTo(49.5, 76, 60, 64)
          ..close();
        canvas.drawPath(mouth, Paint()..color = ink);
      case AgentActivity.approval:
        mouth
          ..moveTo(41, 64)
          ..quadraticBezierTo(49.5, 75, 60, 64);
        canvas.drawPath(mouth, faceStroke);
        final Paint cheek = Paint()..color = const Color(0x66FFFFFF);
        canvas.drawCircle(const Offset(29, 62), 2, cheek);
        canvas.drawCircle(const Offset(71, 62), 2, cheek);
      case AgentActivity.error:
      case AgentActivity.crying:
        mouth
          ..moveTo(40, 69)
          ..quadraticBezierTo(50, 60, 61, 69);
        canvas.drawPath(mouth, faceStroke);
      case AgentActivity.frustrated:
        final RRect clenchedMouth = RRect.fromRectAndRadius(
          const Rect.fromLTRB(41, 63, 61, 70),
          const Radius.circular(1.6),
        );
        canvas.drawRRect(clenchedMouth, Paint()..color = ink);
        canvas.drawLine(
          const Offset(43, 66.4),
          const Offset(59, 66.4),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.35
            ..strokeCap = StrokeCap.round,
        );
    }

    if (activity == AgentActivity.tool) {
      _paintMiniComputer(canvas, phase, accent);
    }
    canvas.restore();
    canvas.restore();
  }

  void _paintMiniComputer(Canvas canvas, double phase, Color displayColor) {
    // A real tool activity opens its little hinged computer from the bottom
    // bezel; the easing is cyclic but no activity is invented by animation.
    final double open = 0.36 + 0.16 * (0.5 + 0.5 * math.sin(phase));
    canvas.save();
    canvas.translate(50, 75);
    final Paint device = Paint()..color = ink;
    final Path screen = Path()
      ..moveTo(-8, 0)
      ..lineTo(-8, -5)
      ..quadraticBezierTo(-8, -6, -7, -6)
      ..lineTo(7, -6)
      ..quadraticBezierTo(8, -6, 8, -5)
      ..lineTo(8, 0)
      ..close();
    canvas.save();
    canvas.rotate(-open);
    canvas.drawPath(screen, device);
    const Rect display = Rect.fromLTWH(-6.5, -5, 13, 3.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(display, const Radius.circular(0.8)),
      Paint()..color = displayColor,
    );
    canvas.restore();
    final Path base = Path()
      ..moveTo(-10, 1)
      ..lineTo(10, 1)
      ..lineTo(7.5, 3)
      ..lineTo(-7.5, 3)
      ..close();
    canvas.drawPath(base, device);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AgentAvatarPainter oldDelegate) =>
      activity != oldDelegate.activity ||
      animation != oldDelegate.animation ||
      skin != oldDelegate.skin ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent;
}
