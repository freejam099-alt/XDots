import 'package:flutter/material.dart';

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
    final double pillWidth =
        MediaQuery.of(context).size.width * AppDims.pillWidthFactor;
    return Center(
      child: Container(
        width: pillWidth,
        height: AppDims.pillHeight,
        decoration: ShapeDecoration(
          color: c.pillBg,
          shape: const StadiumBorder(),
          shadows: [c.shadowNav],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Tiap ikon menempati satu slot sama lebar, indikator
            // memakai slot yang sama -> selalu pas di tengah ikon.
            final double slotW = constraints.maxWidth / icons.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: AppDims.animNav,
                  curve: Curves.easeOutCubic,
                  left: currentIndex * slotW +
                      (slotW - AppDims.indicatorDiameter) / 2,
                  top: (AppDims.pillHeight - AppDims.indicatorDiameter) / 2,
                  child: Container(
                    width: AppDims.indicatorDiameter,
                    height: AppDims.indicatorDiameter,
                    decoration: BoxDecoration(
                      color: c.indicatorBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(icons.length, (i) {
                    return SizedBox(
                      width: slotW,
                      height: AppDims.pillHeight,
                      child: _PressScale(
                        onTap: () => onTap(i),
                        child: Center(
                          child: SizedBox(
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
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDims.animFast,
        child: widget.child,
      ),
    );
  }
}
