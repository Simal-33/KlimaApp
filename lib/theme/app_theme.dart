import 'package:flutter/material.dart';

/// Zentrale Design-Definitionen der Klima-App.
/// Später hier Firmenlogo/-farben aus den Einstellungen einbinden.
class AppTheme {
  static const Color primary = Color(0xFF0D6EFD);
  static const Color primaryDark = Color(0xFF084298);
  static const Color background = Color(0xFFF4F7FB);
  static const Color cardColor = Colors.white;
  static const Color textStrong = Color(0xFF172033);
  static const Color textMuted = Color(0xFF667085);
  static const Color border = Color(0xFFE3E8EF);
  static const Color danger = Color(0xFFDC3545);
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFFC107);
  static const Color teal = Color(0xFF17B8A6);
  static const Color copper = Color(0xFFC6784A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: cardColor,
        background: background,
        brightness: Brightness.light,
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: textStrong,
            displayColor: textStrong,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textStrong,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
