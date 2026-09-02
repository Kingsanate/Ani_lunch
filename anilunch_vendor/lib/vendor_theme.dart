import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VendorTheme {
  VendorTheme._();

  // ── Colors ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF059669); // Emerald Kitchen Green
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color accent = Color(0xFF10B981);
  
  static const Color background = Color(0xFFF8FAFC); // Clean slate background
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  // Status Colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color pendingBg = Color(0xFFFEF3C7);
  
  static const Color preparing = Color(0xFF2563EB);
  static const Color preparingBg = Color(0xFFDBEAFE);
  
  static const Color ready = Color(0xFF059669);
  static const Color readyBg = Color(0xFFD1FAE5);
  
  static const Color outForDelivery = Color(0xFF7C3AED);
  static const Color outForDeliveryBg = Color(0xFFEDE9FE);

  static const Color delivered = Color(0xFF10B981);
  static const Color deliveredBg = Color(0xFFECFDF5);
  
  static const Color cancelled = Color(0xFFEF4444);
  static const Color cancelledBg = Color(0xFFFEE2E2);

  // Backward-compatible aliases
  static const Color cardBg = surface;
  static const Color greyBg = surfaceMuted;
  static const Color success = readyBg;
  static const Color successText = ready;
  static const Color danger = cancelledBg;
  static const Color dangerText = cancelled;
  static const Color warning = pendingBg;
  static const Color warningText = pending;

  // ── Typography ─────────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textBody,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textMuted,
      );

  // ── Box Shadows ────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Card Decoration ────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({double radius = 16, Color? color, Border? borderOverride}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadow,
      border: borderOverride ?? Border.all(color: border, width: 1),
    );
  }

  // ── Status Helpers ─────────────────────────────────────────────────────────
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pending;
      case 'preparing':
        return preparing;
      case 'ready_for_pickup':
        return ready;
      case 'accepted':
      case 'picked_up':
        return outForDelivery;
      case 'delivered':
        return delivered;
      case 'cancelled':
        return cancelled;
      default:
        return textMuted;
    }
  }

  static Color getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingBg;
      case 'preparing':
        return preparingBg;
      case 'ready_for_pickup':
        return readyBg;
      case 'accepted':
      case 'picked_up':
        return outForDeliveryBg;
      case 'delivered':
        return deliveredBg;
      case 'cancelled':
        return cancelledBg;
      default:
        return surfaceMuted;
    }
  }

  static Widget statusBadge(String status) {
    final color = getStatusColor(status);
    final bg = getStatusBg(status);
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
