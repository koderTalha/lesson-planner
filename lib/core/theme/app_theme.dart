import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const Color lightPrimary = Color(0xFF3B5BDB);
  static const Color lightAccent = Color(0xFF845EF7);
  static const Color lightPageBg = Color(0xFFF7F8FC);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF3B3B4F);
  static const Color lightTextMuted = Color(0xFF9A9AB0);
  static const Color lightBorder = Color(0xFFD0D5E8);
  static const Color lightRequired = Color(0xFFE03131);

  static const Color darkPrimary = Color(0xFF4A6EF5);
  static const Color darkAccent = Color(0xFF6741D9);
  static const Color darkPageBg = Color(0xFF0F1117);
  static const Color darkCardBg = Color(0xFF1C1F2E);
  static const Color darkTextPrimary = Color(0xFFE8EAF6);
  static const Color darkTextMuted = Color(0xFF5C607A);
  static const Color darkBorder = Color(0xFF2E3250);
  static const Color darkRequired = Color(0xFFFF6B6B);
}

ThemeData buildLightTheme() => _buildTheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      accent: AppColors.lightAccent,
      pageBg: AppColors.lightPageBg,
      cardBg: AppColors.lightCardBg,
      textPrimary: AppColors.lightTextPrimary,
      textMuted: AppColors.lightTextMuted,
      border: AppColors.lightBorder,
      error: AppColors.lightRequired,
    );

ThemeData buildDarkTheme() => _buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      accent: AppColors.darkAccent,
      pageBg: AppColors.darkPageBg,
      cardBg: AppColors.darkCardBg,
      textPrimary: AppColors.darkTextPrimary,
      textMuted: AppColors.darkTextMuted,
      border: AppColors.darkBorder,
      error: AppColors.darkRequired,
    );

ThemeData _buildTheme({
  required Brightness brightness,
  required Color primary,
  required Color accent,
  required Color pageBg,
  required Color cardBg,
  required Color textPrimary,
  required Color textMuted,
  required Color border,
  required Color error,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    tertiary: accent,
    onTertiary: Colors.white,
    surface: cardBg,
    onSurface: textPrimary,
    onSurfaceVariant: textMuted,
    surfaceContainerLowest: pageBg,
    surfaceContainerLow: pageBg,
    surfaceContainer: cardBg,
    surfaceContainerHigh: cardBg,
    surfaceContainerHighest: cardBg,
    outline: border,
    outlineVariant: border,
    error: error,
    onError: Colors.white,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: textPrimary,
    displayColor: textPrimary,
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: pageBg,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: pageBg,
      foregroundColor: textPrimary,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardBg,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 52),
        side: BorderSide(color: border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardBg,
      indicatorColor: primary.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? primary : textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primary : textMuted,
          size: 24,
        );
      }),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
