import 'package:flutter/material.dart';

import 'paw_palette.dart';

/// Material defaults matching the prototype: Nunito, ink outlines, cream
/// fields. Most screens use the paw widgets directly; this covers text
/// fields, snack bars and tooltips.
abstract final class PawTheme {
  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Paw.orange,
      onPrimary: Paw.ink,
      secondary: Paw.green,
      onSecondary: Paw.ink,
      error: Paw.red,
      onError: Paw.ink,
      surface: Paw.cream,
      onSurface: Paw.ink,
      onSurfaceVariant: Paw.muted,
      outline: Paw.ink,
      outlineVariant: Paw.line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: Paw.body,
      scaffoldBackgroundColor: Paw.skyBottom,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
    final round = BorderRadius.circular(14);
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Paw.ink,
        displayColor: Paw.ink,
        fontFamily: Paw.body,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Paw.ink,
        selectionColor: Color(0x66FF8A3D),
        selectionHandleColor: Paw.orange,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: round,
          borderSide: const BorderSide(color: Paw.ink, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: round,
          borderSide: const BorderSide(color: Paw.ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: round,
          borderSide: const BorderSide(color: Paw.orange, width: 2.5),
        ),
        hintStyle: Paw.text(16, color: Paw.muted, weight: 700),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Paw.ink,
        contentTextStyle: Paw.text(14, color: Paw.cream),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Paw.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: Paw.text(13, color: Paw.cream),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Paw.orange,
      ),
    );
  }
}
