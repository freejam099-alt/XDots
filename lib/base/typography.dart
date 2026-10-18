import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Family yang didaftarkan pada `assets/fonts/XDot.ttf` di pubspec.yaml.
const String xDotFontFamily = 'XDot';

/// Terapkan XDot ke gaya bawaan tema (termasuk kontrol Material yang mengambil
/// gaya dari TextTheme), tanpa mengganti warna atau ukuran tema yang diberikan.
ThemeData withXDotFont(ThemeData theme) {
  final TextTheme xDotTextTheme =
      theme.textTheme.apply(fontFamily: xDotFontFamily);
  final TextTheme xDotPrimaryTextTheme =
      theme.primaryTextTheme.apply(fontFamily: xDotFontFamily);
  final CupertinoTextThemeData baseCupertinoTextTheme =
      theme.cupertinoOverrideTheme?.textTheme ?? const CupertinoTextThemeData();
  final CupertinoTextThemeData xDotCupertinoTextTheme =
      baseCupertinoTextTheme.copyWith(
    textStyle:
        baseCupertinoTextTheme.textStyle.copyWith(fontFamily: xDotFontFamily),
    actionTextStyle: baseCupertinoTextTheme.actionTextStyle
        .copyWith(fontFamily: xDotFontFamily),
    tabLabelTextStyle: baseCupertinoTextTheme.tabLabelTextStyle
        .copyWith(fontFamily: xDotFontFamily),
    navTitleTextStyle: baseCupertinoTextTheme.navTitleTextStyle
        .copyWith(fontFamily: xDotFontFamily),
    navLargeTitleTextStyle: baseCupertinoTextTheme.navLargeTitleTextStyle
        .copyWith(fontFamily: xDotFontFamily),
    navActionTextStyle: baseCupertinoTextTheme.navActionTextStyle
        .copyWith(fontFamily: xDotFontFamily),
    pickerTextStyle: baseCupertinoTextTheme.pickerTextStyle
        .copyWith(fontFamily: xDotFontFamily),
    dateTimePickerTextStyle: baseCupertinoTextTheme.dateTimePickerTextStyle
        .copyWith(fontFamily: xDotFontFamily),
  );

  return theme.copyWith(
    textTheme: xDotTextTheme,
    primaryTextTheme: xDotPrimaryTextTheme,
    cupertinoOverrideTheme:
        (theme.cupertinoOverrideTheme ?? const NoDefaultCupertinoThemeData())
            .copyWith(textTheme: xDotCupertinoTextTheme),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle
          ?.copyWith(fontFamily: xDotFontFamily),
    ),
    bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
      selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle
          ?.copyWith(fontFamily: xDotFontFamily),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      labelStyle: theme.inputDecorationTheme.labelStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      floatingLabelStyle: theme.inputDecorationTheme.floatingLabelStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      helperStyle: theme.inputDecorationTheme.helperStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      hintStyle: theme.inputDecorationTheme.hintStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      errorStyle: theme.inputDecorationTheme.errorStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      prefixStyle: theme.inputDecorationTheme.prefixStyle
          ?.copyWith(fontFamily: xDotFontFamily),
      suffixStyle: theme.inputDecorationTheme.suffixStyle
          ?.copyWith(fontFamily: xDotFontFamily),
    ),
  );
}
