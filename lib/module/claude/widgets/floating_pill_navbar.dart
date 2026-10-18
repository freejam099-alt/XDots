import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Floating navigation with equal tab slots and screen-relative side margins.
/// Tab order, labels and callbacks are shared by embedded and standalone chat.
class FloatingPillNavbar extends StatelessWidget {
  final List<Widget> icons;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingPillNavbar({
    super.key,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
  }) : assert(icons.length == 5, 'icons harus 5 item');

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    const labels = ['Chat', 'Prompt', 'Ruang Kreasi', 'Server', 'Pengaturan'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = MediaQuery.sizeOf(context).width;
        // Use screen margins once, not again when the parent is already inset.
        // A tablet still gets a compact, centered navigation surface.
        final double pillWidth = math.min(
          AppDims.pillMaxWidth,
          math.min(
              constraints.maxWidth,
              math.min(screenWidth - AppDims.screenPaddingH * 2,
                  screenWidth * AppDims.pillWidthFactor)),
        );
        final double slotWidth = pillWidth / icons.length;
        final double iconSize = (slotWidth * 0.38).clamp(24.0, 26.0);
        final double indicatorWidth = math.min(64, slotWidth - 4);
        return Center(
          child: SizedBox(
            key: const ValueKey('floating-nav-surface'),
            width: pillWidth,
            height: AppDims.pillHeight,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: c.pillBg,
                shape: const StadiumBorder(),
                shadows: [c.shadowNav],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppDims.animNav,
                    curve: Curves.easeOutCubic,
                    left: currentIndex * slotWidth +
                        (slotWidth - indicatorWidth) / 2,
                    top: (AppDims.pillHeight - AppDims.indicatorDiameter) / 2,
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey('floating-nav-indicator'),
                        width: indicatorWidth,
                        height: AppDims.indicatorDiameter,
                        decoration: ShapeDecoration(
                          color: c.indicatorBg,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(icons.length, (i) {
                      return Expanded(
                        child: SizedBox(
                          height: AppDims.pillHeight,
                          child: Center(
                            child: Semantics(
                              selected: i == currentIndex,
                              child: IconButton(
                                tooltip: labels[i],
                                constraints: const BoxConstraints.tightFor(
                                  width: 48,
                                  height: 48,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => onTap(i),
                                icon: SizedBox.square(
                                  dimension: iconSize,
                                  child: icons[i],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
