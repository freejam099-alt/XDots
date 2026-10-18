import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palet Muse sebagai ThemeExtension. SEMUA widget wajib mengambil
/// warna dari [AppColors.of(context)], dilarang hardcode di widget.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Brightness brightness;
  final Color bgBase;
  final Color gradMid;
  final Color gradEnd;
  final Color textPrimary;
  final Color textTitle;
  final Color textHint;
  final Color textMuted;
  final Color aiBubble;
  final Color userBubble;
  final Color surface;
  final Color surfaceSoft;
  final Color btnSecondary;
  final Color accent;
  final Color accentEnd;
  final Color linkGreen;
  final Color pdfRed;
  final Color seatAvailable;
  final Color seatTaken;
  final Color seatSelected;
  final Color pillBg;
  final Color indicatorBg;
  final Color navIcon;
  final Color inputIcon;
  final Color micIcon;
  final Color cursor;
  final Color typingDot;
  final Color globeBox;
  final Color globeIcon;
  final Color menuBg;
  final Color menuIcon;
  final Color avatarBg;
  final double shadowOpacity;
  final double shadowBlur;
  final double menuShadowBlur;

  const AppColors({
    required this.brightness,
    required this.bgBase,
    required this.gradMid,
    required this.gradEnd,
    required this.textPrimary,
    required this.textTitle,
    required this.textHint,
    required this.textMuted,
    required this.aiBubble,
    required this.userBubble,
    required this.surface,
    required this.surfaceSoft,
    required this.btnSecondary,
    required this.accent,
    required this.accentEnd,
    required this.linkGreen,
    required this.pdfRed,
    required this.seatAvailable,
    required this.seatTaken,
    required this.seatSelected,
    required this.pillBg,
    required this.indicatorBg,
    required this.navIcon,
    required this.inputIcon,
    required this.micIcon,
    required this.cursor,
    required this.typingDot,
    required this.globeBox,
    required this.globeIcon,
    required this.menuBg,
    required this.menuIcon,
    required this.avatarBg,
    required this.shadowOpacity,
    required this.shadowBlur,
    required this.menuShadowBlur,
  });

  static const AppColors light = AppColors(
    brightness: Brightness.light,
    bgBase: Color(0xFFFAFAFA),
    gradMid: Color(0xFFBBD6F8),
    gradEnd: Color(0xFF8FC0F7),
    textPrimary: Color(0xFF1A1F2B),
    textTitle: Color(0xFF1F3A3D),
    textHint: Color(0xFFA3A8B0),
    textMuted: Color(0xFF6B7280),
    aiBubble: Color(0xFFE9E9EB),
    userBubble: Color(0xFFCDE3FA),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF0F1F3),
    btnSecondary: Color(0xFFEEF0F2),
    accent: Color(0xFF0A66D8),
    accentEnd: Color(0xFF3A4FD0),
    linkGreen: Color(0xFF00D66F),
    pdfRed: Color(0xFFF0345A),
    seatAvailable: Color(0xFFC5CEDB),
    seatTaken: Color(0xFFEDEEF0),
    seatSelected: Color(0xFF0A5FD0),
    pillBg: Color(0xFFF5F5F6),
    indicatorBg: Color(0xFFE4E5E8),
    navIcon: Color(0xFF1A1F2B),
    inputIcon: Color(0xFF1A1F2B),
    micIcon: Color(0xFF5F6672),
    cursor: Color(0xFF0A66D8),
    typingDot: Color(0xFF9AA0AA),
    globeBox: Color(0xFFE3F0FD),
    globeIcon: Color(0xFF0A66D8),
    menuBg: Color(0xFFFFFFFF),
    avatarBg: Color(0xFFF5E6C8),
    menuIcon: Color(0xFF1A1F2B),
    shadowOpacity: 0.08,
    shadowBlur: 24,
    menuShadowBlur: 24,
  );

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    bgBase: Color(0xFF0F1115),
    gradMid: Color(0xFF12233A),
    gradEnd: Color(0xFF1B3A63),
    textPrimary: Color(0xFFECEFF4),
    textTitle: Color(0xFFE6F0F0),
    textHint: Color(0xFF6B7280),
    textMuted: Color(0xFF9AA3AF),
    aiBubble: Color(0xFF23262C),
    userBubble: Color(0xFF1F3A5C),
    surface: Color(0xFF1A1D22),
    surfaceSoft: Color(0xFF23262C),
    btnSecondary: Color(0xFF2A2D33),
    accent: Color(0xFF4C8DF6),
    accentEnd: Color(0xFF6A74E8),
    linkGreen: Color(0xFF00D66F),
    pdfRed: Color(0xFFF0345A),
    seatAvailable: Color(0xFF4A5568),
    seatTaken: Color(0xFF2A2F38),
    seatSelected: Color(0xFF4C8DF6),
    pillBg: Color(0xFF1A1D22),
    indicatorBg: Color(0xFF2E3239),
    navIcon: Color(0xFFE6E8EC),
    inputIcon: Color(0xFFE6E8EC),
    micIcon: Color(0xFF9AA3AF),
    cursor: Color(0xFF4C8DF6),
    typingDot: Color(0xFF6B7280),
    globeBox: Color(0xFF1F3A5C),
    globeIcon: Color(0xFF4C8DF6),
    menuBg: Color(0xFF2A2D33),
    avatarBg: Color(0xFF23262C),
    menuIcon: Color(0xFFF2F4F7),
    shadowOpacity: 0.16,
    shadowBlur: 24,
    menuShadowBlur: 20,
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.light;
  }

  LinearGradient get bgGradientBottom {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.55, 0.8, 1.0],
      colors: [
        bgBase.withOpacity(0),
        bgBase.withOpacity(0),
        gradMid,
        gradEnd,
      ],
    );
  }

  /// A very soft accent wash for compact popup surfaces; unlike the page
  /// gradient it keeps small labels and destructive actions high-contrast.
  LinearGradient get popupGradient {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.55, 0.8, 1.0],
      colors: [
        surface,
        surface,
        Color.alphaBlend(accent.withOpacity(0.03), surface),
        Color.alphaBlend(accent.withOpacity(0.07), surface),
      ],
    );
  }

  /// High-contrast color for small destructive-action labels.
  Color get dangerAction => brightness == Brightness.dark
      ? const Color(0xFFFF647C)
      : const Color(0xFFB4233C);

  BoxShadow get shadowFloat {
    return BoxShadow(
      color: accent.withOpacity(shadowOpacity),
      blurRadius: shadowBlur,
      offset: const Offset(0, 6),
    );
  }

  BoxShadow get shadowNav {
    return BoxShadow(
      color: accent.withOpacity(brightness == Brightness.dark ? 0.16 : 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    );
  }

  BoxShadow get shadowMenu {
    return BoxShadow(
      color: const Color(0xFF000000)
          .withOpacity(brightness == Brightness.dark ? 0.35 : 0.07),
      blurRadius: menuShadowBlur,
      offset: const Offset(0, 6),
    );
  }

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? bgBase,
    Color? gradMid,
    Color? gradEnd,
    Color? textPrimary,
    Color? textTitle,
    Color? textHint,
    Color? textMuted,
    Color? aiBubble,
    Color? userBubble,
    Color? surface,
    Color? surfaceSoft,
    Color? btnSecondary,
    Color? accent,
    Color? accentEnd,
    Color? linkGreen,
    Color? pdfRed,
    Color? seatAvailable,
    Color? seatTaken,
    Color? seatSelected,
    Color? pillBg,
    Color? indicatorBg,
    Color? navIcon,
    Color? inputIcon,
    Color? micIcon,
    Color? cursor,
    Color? typingDot,
    Color? globeBox,
    Color? globeIcon,
    Color? menuBg,
    Color? menuIcon,
    Color? avatarBg,
    double? shadowOpacity,
    double? shadowBlur,
    double? menuShadowBlur,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      bgBase: bgBase ?? this.bgBase,
      gradMid: gradMid ?? this.gradMid,
      gradEnd: gradEnd ?? this.gradEnd,
      textPrimary: textPrimary ?? this.textPrimary,
      textTitle: textTitle ?? this.textTitle,
      textHint: textHint ?? this.textHint,
      textMuted: textMuted ?? this.textMuted,
      aiBubble: aiBubble ?? this.aiBubble,
      userBubble: userBubble ?? this.userBubble,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      btnSecondary: btnSecondary ?? this.btnSecondary,
      accent: accent ?? this.accent,
      accentEnd: accentEnd ?? this.accentEnd,
      linkGreen: linkGreen ?? this.linkGreen,
      pdfRed: pdfRed ?? this.pdfRed,
      seatAvailable: seatAvailable ?? this.seatAvailable,
      seatTaken: seatTaken ?? this.seatTaken,
      seatSelected: seatSelected ?? this.seatSelected,
      pillBg: pillBg ?? this.pillBg,
      indicatorBg: indicatorBg ?? this.indicatorBg,
      navIcon: navIcon ?? this.navIcon,
      inputIcon: inputIcon ?? this.inputIcon,
      micIcon: micIcon ?? this.micIcon,
      cursor: cursor ?? this.cursor,
      typingDot: typingDot ?? this.typingDot,
      globeBox: globeBox ?? this.globeBox,
      globeIcon: globeIcon ?? this.globeIcon,
      menuBg: menuBg ?? this.menuBg,
      menuIcon: menuIcon ?? this.menuIcon,
      avatarBg: avatarBg ?? this.avatarBg,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      menuShadowBlur: menuShadowBlur ?? this.menuShadowBlur,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      bgBase: lerpColor(bgBase, other.bgBase),
      gradMid: lerpColor(gradMid, other.gradMid),
      gradEnd: lerpColor(gradEnd, other.gradEnd),
      textPrimary: lerpColor(textPrimary, other.textPrimary),
      textTitle: lerpColor(textTitle, other.textTitle),
      textHint: lerpColor(textHint, other.textHint),
      textMuted: lerpColor(textMuted, other.textMuted),
      aiBubble: lerpColor(aiBubble, other.aiBubble),
      userBubble: lerpColor(userBubble, other.userBubble),
      surface: lerpColor(surface, other.surface),
      surfaceSoft: lerpColor(surfaceSoft, other.surfaceSoft),
      btnSecondary: lerpColor(btnSecondary, other.btnSecondary),
      accent: lerpColor(accent, other.accent),
      accentEnd: lerpColor(accentEnd, other.accentEnd),
      linkGreen: lerpColor(linkGreen, other.linkGreen),
      pdfRed: lerpColor(pdfRed, other.pdfRed),
      seatAvailable: lerpColor(seatAvailable, other.seatAvailable),
      seatTaken: lerpColor(seatTaken, other.seatTaken),
      seatSelected: lerpColor(seatSelected, other.seatSelected),
      pillBg: lerpColor(pillBg, other.pillBg),
      indicatorBg: lerpColor(indicatorBg, other.indicatorBg),
      navIcon: lerpColor(navIcon, other.navIcon),
      inputIcon: lerpColor(inputIcon, other.inputIcon),
      micIcon: lerpColor(micIcon, other.micIcon),
      cursor: lerpColor(cursor, other.cursor),
      typingDot: lerpColor(typingDot, other.typingDot),
      globeBox: lerpColor(globeBox, other.globeBox),
      globeIcon: lerpColor(globeIcon, other.globeIcon),
      menuBg: lerpColor(menuBg, other.menuBg),
      menuIcon: lerpColor(menuIcon, other.menuIcon),
      avatarBg: lerpColor(avatarBg, other.avatarBg),
      shadowOpacity: shadowOpacity + (other.shadowOpacity - shadowOpacity) * t,
      shadowBlur: shadowBlur + (other.shadowBlur - shadowBlur) * t,
      menuShadowBlur:
          menuShadowBlur + (other.menuShadowBlur - menuShadowBlur) * t,
    );
  }
}

/// Apply the shared Muse surface treatment to Material popup surfaces.
/// Keeping this in one place prevents default Material tint/white surfaces from
/// leaking into light and dark mode dialogs, sheets, and popup menus.
ThemeData withAuraPopupTheme(ThemeData theme, AppColors colors) {
  final RoundedRectangleBorder shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
  );
  final TextStyle popupText = TextStyle(color: colors.textPrimary);
  return theme.copyWith(
    dialogTheme: DialogTheme(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      titleTextStyle: popupText.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: popupText.copyWith(fontSize: 16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      modalBackgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      textStyle: popupText,
    ),
  );
}

/// Ukuran tetap Muse (bukan warna).
class AppDims {
  AppDims._();

  /// Font bawaan XDots untuk UI + teks chat (kode tetap monospace).
  static const String fontFamily = 'XDot';
  static const String codeFontFamily = 'monospace';

  static const double pillWidthFactor = 0.92;
  static const double pillMaxWidth = 430.0;
  static const double pillHeight = 64.0;
  static const double indicatorDiameter = 52.0;
  static const double pillBottomGap = 12.0;
  static const double pillInnerPaddingH = 10.0;

  /// Input and navigation share edges, even inside an already padded parent.
  /// Cap both on large screens rather than stretching the composer alone.
  static double floatingBarWidth(double screenWidth, double availableWidth) {
    return math.max(
      0,
      math.min(
          pillMaxWidth,
          math.min(
              availableWidth,
              math.min(screenWidth - screenPaddingH * 2,
                  screenWidth * pillWidthFactor))),
    );
  }

  static const double inputMinHeight = 48.0;
  static const int inputMaxLines = 5;
  static const double inputRadiusSingle = 24.0;
  static const double inputRadiusMulti = 24.0;
  static const double inputGapToNav = 10.0;

  static const double screenPaddingH = 16.0;
  static const double chatFontSize = 17.0;
  static const double chatLineHeight = 1.3;
  static const double bubbleMaxWidthFactor = 0.80;
  static const double bubbleRadius = 22.0;

  static const Duration animFast = Duration(milliseconds: 100);
  static const Duration animMed = Duration(milliseconds: 180);
  static const Duration animNav = Duration(milliseconds: 220);
}

/// Status bar mengikuti tema (gelap -> ikon terang, terang -> ikon gelap).
void applySystemUi(BuildContext context) {
  final AppColors c = AppColors.of(context);
  SystemChrome.setSystemUIOverlayStyle(
    c.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent),
  );
}
