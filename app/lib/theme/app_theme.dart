import 'package:flutter/material.dart';

const double pagePadding = 16;
const double sectionGap = 20;
const double itemGap = 12;
const double cardRadius = 16;
const double maxContentWidth = 720;

ThemeData buildAppTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0D9488), // Modern vibrant Deep Teal
    primary: const Color(0xFF0F766E),
    secondary: const Color(0xFF0284C7),
    surface: Colors.white,
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      iconTheme: IconThemeData(color: colors.onSurface),
      titleTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: const Color(0xFFE2E8F0), // Clean Slate-200 border
          width: 1.2,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: buttonShape,
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: buttonShape,
        side: BorderSide(color: const Color(0xFFCBD5E1), width: 1.2),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIconColor: const Color(0xFF64748B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 1.2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: colors.primary.withValues(alpha: 0.12),
        selectedForegroundColor: colors.primary,
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titleTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
  );
}
