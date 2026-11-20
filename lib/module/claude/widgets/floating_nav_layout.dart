import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'floating_pill_navbar.dart';

/// Owns the single floating navigation surface and the aura behind every tab.
/// Tab scaffolds are transparent only inside this shell; pushed routes retain
/// their normal theme. Content stays clear of navigation and system insets.
class FloatingNavLayout extends StatelessWidget {
  final Widget child;
  final List<Widget> icons;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavLayout({
    super.key,
    required this.child,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final ThemeData theme = Theme.of(context);
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final double navBottom = AppDims.pillBottomGap + safe.bottom;
    final double contentBottom =
        math.max(keyboard, navBottom + AppDims.pillHeight);

    return Scaffold(
      backgroundColor: colors.bgBase,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        key: const ValueKey('floating-tabs-background'),
        decoration: BoxDecoration(
          color: colors.bgBase,
          gradient: colors.bgGradientBottom,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: contentBottom,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: MediaQuery.removeViewInsets(
                  context: context,
                  removeBottom: true,
                  child: Theme(
                    data: theme.copyWith(
                      scaffoldBackgroundColor: Colors.transparent,
                      textTheme: theme.textTheme.copyWith(
                        bodyLarge: theme.textTheme.bodyLarge
                            ?.copyWith(color: colors.textPrimary),
                        bodyMedium: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.textPrimary),
                        bodySmall: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                      appBarTheme: theme.appBarTheme.copyWith(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            // Navbar tetap di dasar layar meski keyboard terbuka.
            // Yang naik mengikuti keyboard adalah konten/input bar
            // (lewat contentBottom), bukan navbar. Menyembunyikan navbar
            // saat keyboard muncul membuatnya seolah "ikut naik" saat
            // keyboard tertutup, dan merusak desain "navbar tetap".
            // No full-width Material or opaque strip behind the pill.
            Positioned(
              left: safe.left,
              right: safe.right,
              bottom: navBottom,
              child: FloatingPillNavbar(
                icons: icons,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
