import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContentPage extends StatefulWidget {
  final String slug;

  const ContentPage({super.key, required this.slug});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  bool _isLoading = true;
  String? _title;
  String? _content;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _fetchPageContent();
  }

  Future<void> _fetchPageContent() async {
    final titleMap = {
      'about': 'About Us',
      'privacy': 'Privacy Policy',
      'terms': 'Terms of Service',
      'faq': 'Frequently Asked Questions',
      'contact': 'Contact Us',
    };
    final contentMap = {
      'about': 'AniLunch is your daily gourmet lunch and meat delivery companion, delivering fresh, chef-curated meals and farm-fresh meat right to your doorstep.',
      'privacy': 'We take your privacy seriously. Your personal and delivery information is encrypted and securely stored.',
      'terms': 'By using the AniLunch service, you agree to our fair delivery and transparent pricing policy.',
      'faq': 'Orders are prepared fresh and dispatched promptly. You can track your order status in real time in the app.',
      'contact': 'Reach out to our support team at support@anilunch.com or call +91 9774164689.',
    };

    if (mounted) {
      setState(() {
        _isLoading = false;
        _title = titleMap[widget.slug] ?? 'AniLunch';
        _content = contentMap[widget.slug] ?? 'AniLunch - Fresh food and meat delivered fast.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          _title ?? '',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24)))
          : _notFound
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.find_in_page_outlined, size: 64, color: Colors.black26),
                      const SizedBox(height: 16),
                      Text(
                        'Content not available',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This page has not been created yet.',
                        style: TextStyle(color: Colors.black38),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _content ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
    );
  }
}
