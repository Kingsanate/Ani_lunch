import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    try {
      final data = await Supabase.instance.client
          .from('pages')
          .select()
          .eq('slug', widget.slug)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (data != null) {
            _title = data['title']?.toString();
            _content = data['content']?.toString();
          } else {
            _notFound = true;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching page content: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _notFound = true;
        });
      }
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
