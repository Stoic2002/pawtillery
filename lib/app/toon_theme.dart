import 'package:flutter/material.dart';

import 'toon_palette.dart';

/// Material defaults in the toon look (docs/art_style_guide.md): Lilita One
/// everywhere, chunky outlines, rounded corners. Most screens use the toon
/// widgets directly; this covers text fields, sliders, tabs and snack bars.
abstract final class ToonTheme {
  static const font = 'LilitaOne';

  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: ToonPalette.sunDeep,
      onPrimary: ToonPalette.white,
      secondary: ToonPalette.skyDeep,
      onSecondary: ToonPalette.white,
      tertiary: ToonPalette.leafDeep,
      onTertiary: ToonPalette.white,
      error: ToonPalette.tomatoDeep,
      onError: ToonPalette.white,
      surface: ToonPalette.cream,
      onSurface: ToonPalette.outline,
      onSurfaceVariant: ToonPalette.bark,
      outline: ToonPalette.outline,
      outlineVariant: ToonPalette.creamDeep,
      surfaceContainerHighest: ToonPalette.creamShade,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: const Color(0xFF8ED3F5),
      splashFactory: NoSplash.splashFactory,
    );
    final text = base.textTheme.apply(
      bodyColor: ToonPalette.outline,
      displayColor: ToonPalette.outline,
      fontFamily: font,
    );
    TextStyle? regular(TextStyle? s) =>
        s?.copyWith(fontWeight: FontWeight.w400);
    final round = BorderRadius.circular(12);
    return base.copyWith(
      textTheme: text.copyWith(
        bodyLarge: regular(text.bodyLarge),
        bodyMedium: regular(text.bodyMedium),
        titleMedium: regular(text.titleMedium),
        titleSmall: regular(text.titleSmall),
        labelLarge: regular(text.labelLarge),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ToonPalette.skyDeep,
        selectionColor: Color(0x665CC8F5),
        selectionHandleColor: ToonPalette.skyDeep,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFFFFDF6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: round,
          borderSide: const BorderSide(color: ToonPalette.outline, width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: round,
          borderSide: const BorderSide(color: ToonPalette.outline, width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: round,
          borderSide: const BorderSide(color: ToonPalette.skyDeep, width: 3),
        ),
        labelStyle: const TextStyle(fontFamily: font, color: ToonPalette.bark),
        floatingLabelStyle: const TextStyle(
          fontFamily: font,
          color: ToonPalette.skyDeep,
        ),
        hintStyle: const TextStyle(fontFamily: font, color: ToonPalette.stoneDeep),
      ),
      tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
      sliderTheme: const SliderThemeData(
        activeTrackColor: ToonPalette.sunDeep,
        inactiveTrackColor: ToonPalette.creamDeep,
        thumbColor: ToonPalette.sun,
        overlayColor: Color(0x33F07C0C),
        trackHeight: 10,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 13, elevation: 0),
        valueIndicatorColor: ToonPalette.outline,
        valueIndicatorTextStyle: TextStyle(fontFamily: font, color: ToonPalette.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ToonPalette.outline,
        contentTextStyle: const TextStyle(
          fontFamily: font,
          fontSize: 16,
          color: ToonPalette.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: round),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ToonPalette.outline,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: ToonPalette.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ToonPalette.sunDeep,
      ),
    );
  }
}
