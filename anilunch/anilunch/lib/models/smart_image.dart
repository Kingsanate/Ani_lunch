import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  const SmartImage(this.imagePath, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.borderRadius});
  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imagePath.startsWith('http')) {
      image = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(width: width, height: height, color: Colors.grey[100], child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        errorWidget: (context, url, error) => Container(width: width, height: height, color: Colors.grey[200], child: const Icon(Icons.error_outline)),
      );
    } else if (imagePath.startsWith('data:image')) {
      final base64String = imagePath.split(',').last;
      image = Image.memory(base64Decode(base64String), width: width, height: height, fit: fit);
    } else {
      image = Image.asset(imagePath, width: width, height: height, fit: fit);
    }
    return borderRadius != null ? ClipRRect(borderRadius: borderRadius!, child: image) : image;
  }
  static ImageProvider provider(String imagePath) {
    if (imagePath.startsWith('http') || imagePath.startsWith('blob:')) {
      return CachedNetworkImageProvider(imagePath);
    }
    if (imagePath.startsWith('data:image')) {
      final base64String = imagePath.split(',').last;
      return MemoryImage(base64Decode(base64String));
    }
    return AssetImage(imagePath);
  }
}

class AniLunchLogo extends StatelessWidget {
  final double size;
  const AniLunchLogo({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
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
      ),
    );
  }
}
