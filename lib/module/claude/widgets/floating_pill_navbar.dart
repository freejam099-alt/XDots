import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../app_theme.dart';

/// Bottom navigation mengambang berbentuk pill, minimalis soft.
/// Semua warna dari [AppColors] (terang/gelap otomatis).
///
/// Contoh pemakaian di Scaffold:
/// ```dart
/// Scaffold(
///   extendBody: true,
///   body: Stack(children: [content]),
///   bottomNavigationBar: Padding(
///     padding: EdgeInsets.only(
///       bottom: AppDims.pillBottomGap + MediaQuery.of(context).padding.bottom,
///     ),
///     child: FloatingPillNavbar(
///       icons: const [...5 icon 24x24...],
///       currentIndex: index,
///       onTap: (i) => setState(() => index = i),
///     ),
///   ),
/// );
/// ```
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
        // A percentage-only width becomes an oversized strip on tablets and
        // can exceed a parent with side insets. Keep it centered and bounded.
        final double pillWidth = math.min(
          430,
          math.min(
            constraints.maxWidth,
            MediaQuery.sizeOf(context).width * AppDims.pillWidthFactor,
          ),
        );
        return Center(
          child: SizedBox(
            width: pillWidth,
            height: AppDims.pillHeight,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: c.pillBg,
                shape: const StadiumBorder(),
                shadows: [c.shadowNav],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Every icon and the indicator share an equal slot.
                  final double slotW = constraints.maxWidth / icons.length;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: AppDims.animNav,
                        curve: Curves.easeOutCubic,
                        left: currentIndex * slotW +
                            (slotW - AppDims.indicatorDiameter) / 2,
                        top: (AppDims.pillHeight - AppDims.indicatorDiameter) /
                            2,
                        child: IgnorePointer(
                          child: Container(
                            width: AppDims.indicatorDiameter,
                            height: AppDims.indicatorDiameter,
                            decoration: BoxDecoration(
                              color: c.indicatorBg,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(icons.length, (i) {
                          return SizedBox(
                            width: slotW,
                            height: AppDims.pillHeight,
                            child: Center(
                              child: IconButton(
                                tooltip: labels[i],
                                constraints: const BoxConstraints.tightFor(
                                  width: 48,
                                  height: 48,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => onTap(i),
                                icon: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: icons[i],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
