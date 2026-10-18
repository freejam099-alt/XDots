import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_bot/module/claude/app_theme.dart';

void main() {
  group('AppColors surface aura', () {
    test('uses a soft accent-tinted shadow in both brightness modes', () {
      for (final AppColors colors in [AppColors.light, AppColors.dark]) {
        final shadow = colors.shadowFloat;
        expect(shadow.color.alpha, greaterThan(0));
        expect(shadow.color.alpha, lessThan(255));
        expect(shadow.color.red, colors.accent.red);
        expect(shadow.color.green, colors.accent.green);
        expect(shadow.color.blue, colors.accent.blue);
        expect(shadow.color.opacity, lessThanOrEqualTo(0.04));
        expect(shadow.blurRadius, colors.shadowBlur);
        expect(shadow.blurRadius, lessThanOrEqualTo(12));
      }
    });

    test('keeps the background gradient theme-specific', () {
      expect(AppColors.light.bgGradientBottom.colors,
          isNot(AppColors.dark.bgGradientBottom.colors));
      expect(AppColors.light.bgGradientBottom.colors.last,
          AppColors.light.gradEnd);
      expect(
          AppColors.dark.bgGradientBottom.colors.last, AppColors.dark.gradEnd);
    });

    test('uses AppColors surfaces and suppresses Material tint on popups', () {
      for (final AppColors colors in [AppColors.light, AppColors.dark]) {
        final theme = withAuraPopupTheme(ThemeData(), colors);
        expect(theme.dialogTheme.backgroundColor, colors.surface);
        expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
        expect(theme.bottomSheetTheme.backgroundColor, colors.surface);
        expect(theme.bottomSheetTheme.modalBackgroundColor, colors.surface);
        expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
        expect(theme.popupMenuTheme.color, colors.surface);
        expect(theme.popupMenuTheme.surfaceTintColor, Colors.transparent);
        expect(theme.popupMenuTheme.textStyle?.color, colors.textPrimary);
      }
    });

    test('keeps popup accent wash subtle and destructive text legible', () {
      for (final AppColors colors in [AppColors.light, AppColors.dark]) {
        final Color popupSurface = colors.popupGradient.colors.last;
        expect(colors.popupGradient.colors.first, colors.surface);
        expect(
            popupSurface.computeLuminance(),
            closeTo(
              colors.surface.computeLuminance(),
              0.12,
            ));
        final double lighter = colors.dangerAction.computeLuminance() >
                popupSurface.computeLuminance()
            ? colors.dangerAction.computeLuminance()
            : popupSurface.computeLuminance();
        final double darker = colors.dangerAction.computeLuminance() >
                popupSurface.computeLuminance()
            ? popupSurface.computeLuminance()
            : colors.dangerAction.computeLuminance();
        expect((lighter + 0.05) / (darker + 0.05), greaterThan(4.5));
      }
    });
  });
}
