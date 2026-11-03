import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF176B45);
  static const lightGreen = Color(0xFFEAF5EC);
  static const ink = Color(0xFF1C2D24);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F9F5),
    colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F9F5),
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E9E2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E9E2)),
      ),
    ),
  );
}
