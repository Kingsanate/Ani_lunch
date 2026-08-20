import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;

  bool _showHeroBanner = true;
  String _badgeText = '🔥 Fresh Meat Daily';
  String _titleText = 'Your Daily Lunch,\nDelivered Fresh & Fast!';
  String _subtitleText = 'Delicious meals, delivered to your door';
  String _buttonText = 'Order Now';

  @override
  void initState() {
    super.initState();
    _fetchHeroSettings();
  }

  Future<void> _fetchHeroSettings() async {
    try {
      final data = await Supabase.instance.client.from('app_settings').select().maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _showHeroBanner = data['show_hero_banner'] ?? true;
          if (data['hero_badge_text'] != null && data['hero_badge_text'].toString().isNotEmpty) {
            _badgeText = data['hero_badge_text'].toString();
          }
          if (data['hero_title'] != null && data['hero_title'].toString().isNotEmpty) {
            _titleText = data['hero_title'].toString();
          }
          if (data['hero_subtitle'] != null && data['hero_subtitle'].toString().isNotEmpty) {
            _subtitleText = data['hero_subtitle'].toString();
          }
          if (data['hero_button_text'] != null && data['hero_button_text'].toString().isNotEmpty) {
            _buttonText = data['hero_button_text'].toString();
          }
        });
      }

      final url = data?['home_video_url']?.toString();

      if (url != null && url.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url))
          ..setLooping(true)
          ..setVolume(0.0)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _controller!.play();
            }
          }).catchError((error) {
            debugPrint("Video initialization error: $error");
          });
      }
    } catch (e) {
      debugPrint("Error fetching video url: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showHeroBanner) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 200, // Reduced height for a more compact feel
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideoInitialized && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Image.asset(
              'assets/images/hero.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C1A0E), Color(0xFFF15A24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lunch_dining_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          
          // Premium Cinematic Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Glassmorphism Content Area
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF15A24),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF15A24).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    _badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _titleText,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
