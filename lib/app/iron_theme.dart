import 'package:flutter/material.dart';

import 'iron_palette.dart';

/// Material defaults in the dark-fantasy look (docs/art_style_guide.md):
/// Alegreya for reading, Cinzel for titles and labels, iron and brass.
/// Most screens use the iron widgets directly; this covers text fields,
/// sliders, snack bars and tooltips.
abstract final class IronTheme {
  /// Body text.
  static const font = 'Alegreya';

  /// Titles, buttons, HUD numbers.
  static const display = 'Cinzel';

  /// Cinzel at a weight (it is a variable font).
  static TextStyle displayStyle({
    double size = 16,
    Color color = IronPalette.parchment,
    double weight = 700,
    double letterSpacing = 1.2,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: display,
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', weight)],
    height: 1.15,
    shadows: shadows,
  );

  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: IronPalette.brass,
      onPrimary: IronPalette.ink,
      secondary: IronPalette.steel,
      onSecondary: IronPalette.parchment,
      tertiary: IronPalette.moss,
      onTertiary: IronPalette.parchment,
      error: IronPalette.blood,
      onError: IronPalette.parchment,
      surface: IronPalette.iron,
      onSurface: IronPalette.parchment,
      onSurfaceVariant: IronPalette.mute,
      outline: IronPalette.brassDeep,
      outlineVariant: IronPalette.ironEdge,
      surfaceContainerHighest: IronPalette.ironShade,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: const Color(0xFF0E0D14),
      splashFactory: NoSplash.splashFactory,
    );
    final text = base.textTheme.apply(
      bodyColor: IronPalette.parchment,
      displayColor: IronPalette.parchment,
      fontFamily: font,
    );
    final square = BorderRadius.circular(3);
    return base.copyWith(
      textTheme: text,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: IronPalette.brass,
        selectionColor: Color(0x66C9A45C),
        selectionHandleColor: IronPalette.brass,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFF16171A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: square,
          borderSide: const BorderSide(color: IronPalette.ironEdge),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: square,
          borderSide: const BorderSide(color: IronPalette.ironEdge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: square,
          borderSide: const BorderSide(color: IronPalette.brass, width: 1.5),
        ),
        labelStyle: const TextStyle(fontFamily: font, color: IronPalette.mute),
        floatingLabelStyle: const TextStyle(
          fontFamily: font,
          color: IronPalette.brass,
        ),
        hintStyle: const TextStyle(fontFamily: font, color: IronPalette.ash),
      ),
      tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
      sliderTheme: const SliderThemeData(
        activeTrackColor: IronPalette.brass,
        inactiveTrackColor: IronPalette.ironEdge,
        thumbColor: IronPalette.brassLight,
        overlayColor: Color(0x22C9A45C),
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
        valueIndicatorColor: IronPalette.iron,
        valueIndicatorTextStyle: TextStyle(
          fontFamily: font,
          color: IronPalette.parchment,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: IronPalette.iron,
        contentTextStyle: const TextStyle(
          fontFamily: font,
          fontSize: 16,
          color: IronPalette.parchment,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: square,
          side: const BorderSide(color: IronPalette.brassDeep),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: IronPalette.iron,
          borderRadius: square,
          border: Border.all(color: IronPalette.brassDeep),
        ),
        textStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: IronPalette.parchment,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: IronPalette.brass,
      ),
    );
  }
}
