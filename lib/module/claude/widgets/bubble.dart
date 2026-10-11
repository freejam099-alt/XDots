import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Bubble chat AI (kiri) / user (kanan).
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? reaction;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.reaction,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final double maxW =
        MediaQuery.of(context).size.width * AppDims.bubbleMaxWidthFactor;
    final Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? c.userBubble : c.aiBubble,
        borderRadius: BorderRadius.circular(AppDims.bubbleRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppDims.chatFontSize,
          height: AppDims.chatLineHeight,
          color: c.textPrimary,
        ),
      ),
    );
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isUser && reaction != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              bubble,
              Positioned(
                right: -6,
                bottom: -6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [c.shadowFloat],
                  ),
                  child: Center(
                    child: Text(reaction!,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          )
        else
          bubble,
      ],
    );
  }
}

/// Typing indicator AI: pill 64x44, 3 bola kecil diameter 7 yang
/// naik-turun secara simetris dan berurutan (gelombang 1 -> 2 -> 3).
/// Satu siklus 900ms: tiap titik tertinggal 1/3 fase dengan kurva
/// sinus penuh sehingga geraknya halus naik maupun turun.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const double _dotSize = 7;
  static const double _amplitude = 5;
  static const Duration _cycle = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _cycle)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: c.aiBubble,
            borderRadius: BorderRadius.circular(AppDims.bubbleRadius),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  // Fase berurutan: 0, 1/3, 2/3 siklus.
                  final double phase = (_c.value + i / 3) % 1.0;
                  // Sinus penuh: naik-turun simetris (0 di tengah).
                  final double dy =
                      -_amplitude * _sin01(phase * 2 * _pi);
                  // Opacity mengikuti ketinggian agar terasa hidup.
                  final double opacity =
                      (0.45 + 0.55 * (1 - (dy.abs() / _amplitude)))
                          .clamp(0.0, 1.0)
                          .toDouble();
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Container(
                      width: _dotSize,
                      height: _dotSize,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: c.typingDot
                            .withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

const double _pi = 3.141592653589793;

/// sin(x) berbasis deret Taylor (tanpa dart:math agar mandiri).
double _sin01(double x) {
  const double twoPi = 2 * _pi;
  x = x % twoPi;
  if (x < 0) x += twoPi;
  final double x2 = x * x;
  double term = x;
  double sum = x;
  for (int k = 1; k <= 9; k++) {
    term *= -x2 / ((2 * k) * (2 * k + 1));
    sum += term;
  }
  return sum;
}
