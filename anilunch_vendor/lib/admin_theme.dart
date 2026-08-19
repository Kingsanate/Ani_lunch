import 'package:flutter/material.dart';

// ─── Admin Design System ────────────────────────────────────────────────────
// Single source of truth for the entire admin app UI.
// Usage: import '../admin_theme.dart'; (or 'admin_theme.dart' from lib root)

class AdminTheme {
  AdminTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color bg          = Color(0xFFF4F6F9); // page background
  static const Color surface     = Color(0xFFFFFFFF); // cards
  static const Color border      = Color(0xFFE8ECF0); // dividers / borders
  static const Color primary     = Color(0xFFEA6E21); // orange brand
  static const Color dark        = Color(0xFF0F1621); // headings / nav
  static const Color textBody    = Color(0xFF4A5568); // body copy
  static const Color textMuted   = Color(0xFF94A3B8); // timestamps, subtitles
  static const Color success     = Color(0xFF16A34A);
  static const Color warning     = Color(0xFFD97706);
  static const Color info        = Color(0xFF2563EB);
  static const Color danger      = Color(0xFFDC2626);

  // ── Typography ─────────────────────────────────────────────────────────────
  static const TextStyle pageTitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, color: dark, letterSpacing: -0.2,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, color: dark,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: dark,
  );
  static const TextStyle body = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: textBody,
  );
  static const TextStyle label = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.6,
  );
  static const TextStyle micro = TextStyle(
    fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.4,
  );

  // ── Card Decoration ────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({Color? color, double radius = 10}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1621).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── Status badge colors ────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return success;
      case 'accepted':  return info;
      case 'cancelled': return danger;
      default:          return warning;
    }
  }

  static Color statusBg(String status) =>
      statusColor(status).withValues(alpha: 0.10);

  // ── Input Decoration ───────────────────────────────────────────────────────
  static InputDecoration inputDecoration(String hint, {String? label}) =>
      InputDecoration(
        hintText: hint,
        labelText: label,
        hintStyle: const TextStyle(color: Color(0xFFB0BAC9), fontSize: 12),
        labelStyle: const TextStyle(color: textMuted, fontSize: 12),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      );

  // ── Compact Page Header ────────────────────────────────────────────────────
  /// Use this at the top of every page for a consistent, compact header.
  static Widget pageHeader({
    required BuildContext context,
    required String title,
    Widget? action,
    bool showMenu = true,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 10,
        left: showMenu ? 4 : 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border, width: 0.8)),
      ),
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: dark, size: 20),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                constraints: const BoxConstraints(),
              ),
            ),
          Expanded(
            child: Text(title, style: pageTitle),
          ),
          ?action,
        ],
      ),
    );
  }

  // ── Stat Pill ──────────────────────────────────────────────────────────────
  static Widget statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Primary Button ─────────────────────────────────────────────────────────
  static Widget primaryButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: small ? 14 : 15),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: small ? 12 : 13,
            )),
          ],
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  static Widget sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 1),
    child: Text(text.toUpperCase(), style: label),
  );
}
