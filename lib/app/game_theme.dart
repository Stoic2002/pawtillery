import 'package:flutter/material.dart';

/// The game's look: deep slate surfaces, a warm amber accent, frosted
/// panels over the arena. System font, heavier weights for game feel.
abstract final class GameColors {
  static const background = Color(0xFF111A22);
  static const surface = Color(0xFF1B2631);
  static const surfaceHigh = Color(0xFF243240);
  static const glass = Color(0xC70E151C);
  static const glassBorder = Color(0x33FFFFFF);
  static const accent = Color(0xFFF5A623);
  static const accentDeep = Color(0xFFE0701A);
  static const text = Color(0xFFF4F6F8);
  static const textDim = Color(0xFFAEB9C4);
  static const danger = Color(0xFFFF6B5A);
}

abstract final class GameTheme {
  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: GameColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: GameColors.accent,
      onPrimary: const Color(0xFF2A1A05),
      secondary: GameColors.accentDeep,
      surface: GameColors.surface,
      surfaceContainerHighest: GameColors.surfaceHigh,
      onSurface: GameColors.text,
      outline: GameColors.glassBorder,
    );
    const radius = BorderRadius.all(Radius.circular(14));
    return ThemeData(
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: GameColors.background,
        foregroundColor: GameColors.text,
        elevation: 0,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: GameColors.text),
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: GameColors.text,
        displayColor: GameColors.text,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.accent,
          foregroundColor: const Color(0xFF2A1A05),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GameColors.text,
          backgroundColor: const Color(0x1AFFFFFF),
          side: const BorderSide(color: GameColors.glassBorder, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GameColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: const CardThemeData(
        color: GameColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: GameColors.glassBorder),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: GameColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: GameColors.glassBorder),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0x14FFFFFF),
          foregroundColor: GameColors.textDim,
          selectedBackgroundColor: GameColors.accent,
          selectedForegroundColor: const Color(0xFF2A1A05),
          side: const BorderSide(color: GameColors.glassBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0x14FFFFFF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none),
        labelStyle: TextStyle(color: GameColors.textDim),
        hintStyle: TextStyle(color: Color(0x88AEB9C4)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: GameColors.text,
        unselectedLabelColor: GameColors.textDim,
        indicatorColor: GameColors.accent,
        labelStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: GameColors.accent,
        thumbColor: GameColors.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? GameColors.accent : null),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: GameColors.surfaceHigh,
        contentTextStyle: TextStyle(color: GameColors.text),
      ),
    );
  }
}

/// A frosted dark panel used across the HUD and menus.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.radius = 14,
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  /// Optional coloured edge (e.g. the active team).
  final Color? accent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: GameColors.glass,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              color: accent ?? GameColors.glassBorder,
              width: accent == null ? 1 : 2),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Padding(padding: padding, child: child),
      );
}
