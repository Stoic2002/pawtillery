import 'package:flutter/material.dart';

import 'field_palette.dart';

/// Paper-and-ink look for every Material widget (docs/art_style_guide.md):
/// Old Standard TT, one weight, square corners, hairline ink.
abstract final class FieldTheme {
  static const font = 'OldStandard';

  static const _square = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(1)),
  );

  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: FieldPalette.stamp,
      onPrimary: FieldPalette.paper,
      secondary: FieldPalette.ink,
      onSecondary: FieldPalette.paper,
      tertiary: FieldPalette.moss,
      onTertiary: FieldPalette.paper,
      error: FieldPalette.stamp,
      onError: FieldPalette.paper,
      surface: FieldPalette.paper,
      onSurface: FieldPalette.ink,
      onSurfaceVariant: FieldPalette.inkSoft,
      outline: FieldPalette.ink,
      outlineVariant: FieldPalette.paperEdge,
      surfaceContainerHighest: FieldPalette.paperShade,
      primaryContainer: FieldPalette.paperShade,
      onPrimaryContainer: FieldPalette.ink,
      tertiaryContainer: FieldPalette.paper,
      onTertiaryContainer: FieldPalette.ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: FieldPalette.paper,
      splashFactory: InkRipple.splashFactory,
    );
    final text = base.textTheme.apply(
      bodyColor: FieldPalette.ink,
      displayColor: FieldPalette.ink,
      fontFamily: font,
    );
    TextStyle? spaced(TextStyle? s, double spacing) =>
        s?.copyWith(letterSpacing: spacing, fontWeight: FontWeight.w400);
    return base.copyWith(
      textTheme: text.copyWith(
        displayMedium: spaced(text.displayMedium, 6),
        displaySmall: spaced(text.displaySmall, 5),
        headlineMedium: spaced(text.headlineMedium, 3),
        headlineSmall: spaced(text.headlineSmall, 2.5),
        titleLarge: spaced(text.titleLarge, 2),
        titleMedium: spaced(text.titleMedium, 1.5),
        titleSmall: spaced(text.titleSmall, 1.2),
        labelLarge: spaced(text.labelLarge, 1.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: FieldPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 20,
          letterSpacing: 4,
          color: FieldPalette.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FieldPalette.stamp,
          foregroundColor: FieldPalette.paper,
          shape: _square,
          textStyle: const TextStyle(
              fontFamily: font, fontSize: 16, letterSpacing: 2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FieldPalette.ink,
          side: const BorderSide(color: FieldPalette.ink),
          shape: _square,
          textStyle: const TextStyle(
              fontFamily: font, fontSize: 16, letterSpacing: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FieldPalette.ink,
          shape: _square,
          textStyle: const TextStyle(
              fontFamily: font, fontSize: 16, letterSpacing: 1.2),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: FieldPalette.ink),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: FieldPalette.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: FieldPalette.ink, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        titleTextStyle: TextStyle(
            fontFamily: font,
            fontSize: 20,
            letterSpacing: 3,
            color: FieldPalette.ink),
        contentTextStyle: TextStyle(
            fontFamily: font,
            fontSize: 16,
            height: 1.45,
            color: FieldPalette.inkSoft),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: FieldPalette.inkSoft,
          selectedBackgroundColor: FieldPalette.ink,
          selectedForegroundColor: FieldPalette.paper,
          side: const BorderSide(color: FieldPalette.ink, width: 1),
          shape: _square,
          textStyle: const TextStyle(fontFamily: font, fontSize: 15),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: UnderlineInputBorder(
            borderSide: BorderSide(color: FieldPalette.inkSoft)),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: FieldPalette.pencil)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: FieldPalette.ink, width: 1.4)),
        labelStyle: TextStyle(
            fontFamily: font,
            fontStyle: FontStyle.italic,
            color: FieldPalette.inkSoft),
        hintStyle: TextStyle(fontFamily: font, color: FieldPalette.pencil),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: FieldPalette.ink,
        unselectedLabelColor: FieldPalette.pencil,
        indicatorColor: FieldPalette.ink,
        dividerColor: FieldPalette.paperEdge,
        labelStyle:
            TextStyle(fontFamily: font, fontSize: 15, letterSpacing: 2),
        unselectedLabelStyle:
            TextStyle(fontFamily: font, fontSize: 15, letterSpacing: 2),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: FieldPalette.ink,
        inactiveTrackColor: FieldPalette.paperEdge,
        thumbColor: FieldPalette.ink,
        overlayColor: Color(0x222B2620),
        trackHeight: 1.5,
      ),
      dividerTheme: const DividerThemeData(
          color: FieldPalette.paperEdge, thickness: 1, space: 1),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: FieldPalette.ink,
        contentTextStyle: TextStyle(
            fontFamily: font, fontSize: 15, color: FieldPalette.paper),
        behavior: SnackBarBehavior.floating,
        shape: _square,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: FieldPalette.ink),
        textStyle: TextStyle(
            fontFamily: font, fontSize: 13, color: FieldPalette.paper),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: FieldPalette.ink),
    );
  }
}
