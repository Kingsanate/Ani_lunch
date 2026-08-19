import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData build() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF15A24),
        primary: const Color(0xFFF15A24),
        secondary: const Color(0xFF8CC63F),
        surface: const Color(0xFFF7F3F0),
      ),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF15A24),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFF15A24),
        unselectedItemColor: Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
