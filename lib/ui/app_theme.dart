import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF0E2238);
  static const Color plum = Color(0xFF2B63D9);
  static const Color coral = Color(0xFF6DB9FF);
  static const Color mint = Color(0xFFB7E2FF);
  static const Color sand = Color(0xFFEEF6FF);
  static const Color cloud = Color(0xFFF7FBFF);
  static const Color border = Color(0xFFD7E6F5);
  // Legacy palette aliases for older screens.
  static const Color navy = plum;
  static const Color sky = mint;
  static const Color softBg = sand;
  static const Color softSurface = cloud;
  static const Color softBorder = border;

  static ThemeData light() {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        color: ink,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        color: ink,
        height: 1.4,
      ),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: plum,
      brightness: Brightness.light,
    ).copyWith(
      primary: plum,
      onPrimary: Colors.white,
      secondary: coral,
      onSecondary: Colors.white,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: sand,
      textTheme: textTheme,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: cloud,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: plum, width: 1.4),
        ),
        labelStyle: const TextStyle(color: ink),
        prefixIconColor: ink,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: plum,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: plum),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cloud,
        selectedColor: mint,
        disabledColor: border,
        labelStyle: textTheme.bodyMedium!,
        secondaryLabelStyle: textTheme.bodyMedium!,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  static const List<BoxShadow> softShadows = [
    BoxShadow(
      color: Color(0x1A1C1A27),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFE7F2FF), Color(0xFFD7EAFF), Color(0xFFF7FBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
