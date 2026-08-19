import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorTheme {
  // Colors
  static const Color primary = Color(0xFF267A43);
  static const Color secondary = Color(0xFF1B5E20);
  static const Color background = Color(0xFFF8F9FB);
  static const Color cardBg = Colors.white;
  static const Color greyBg = Color(0xFFF2F2F2);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textMuted = Color(0xFF6E6E6E);
  
  static const Color success = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFFFEBEE);
  static const Color dangerText = Color(0xFFC62828);
  static const Color warning = Color(0xFFFFF3E0);
  static const Color warningText = Color(0xFFEF6C00);

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textDark,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textDark,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        color: textDark,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        color: textMuted,
      );
      
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        color: textMuted,
      );

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
      
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ];

  // Decorations
  static BoxDecoration cardDecoration({double radius = 12}) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadow,
      border: Border.all(color: Colors.grey.shade200, width: 1),
    );
  }
}
