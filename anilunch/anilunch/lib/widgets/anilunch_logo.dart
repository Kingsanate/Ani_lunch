import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AniLunchLogo extends StatelessWidget {
  final double size;
  const AniLunchLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.15, height: size * 1.15,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF15A24), Color(0xFFFF8C42)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(size * 0.28), child: Image.asset('assets/images/lunch_logo.png', width: size * 0.8, height: size * 0.8, fit: BoxFit.cover)),
        ),
        const SizedBox(width: 8),
        Text('Ani', style: GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFF2C1A0E))),
        Text('Lunch', style: GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFFF15A24))),
      ],
    );
  }
}
