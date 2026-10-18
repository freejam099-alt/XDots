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
        expect(shadow.blurRadius, colors.shadowBlur);
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
  });
}
