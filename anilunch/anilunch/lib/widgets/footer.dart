import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../content_page.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  String _subtitle = 'Fresh meat, delivered daily.';
  List<String> _supportLinks = ['Help Center', 'Contact Us', 'FAQs'];
  List<String> _legalLinks = ['Privacy Policy', 'Terms of Use', 'Refund Policy'];
  String _copyright = '© 2026 AniLunch. All rights reserved.';

  @override
  void initState() {
    super.initState();
    _fetchFooterSettings();
  }

  Future<void> _fetchFooterSettings() async {
    try {
      final data = await Supabase.instance.client.from('app_settings').select().maybeSingle();
      if (mounted && data != null) {
        setState(() {
          if (data['footer_subtitle'] != null && data['footer_subtitle'].toString().isNotEmpty) {
            _subtitle = data['footer_subtitle'].toString();
          }
          if (data['footer_support_links'] != null && data['footer_support_links'].toString().isNotEmpty) {
            _supportLinks = data['footer_support_links'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
          if (data['footer_legal_links'] != null && data['footer_legal_links'].toString().isNotEmpty) {
            _legalLinks = data['footer_legal_links'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
          if (data['footer_copyright'] != null && data['footer_copyright'].toString().isNotEmpty) {
            _copyright = data['footer_copyright'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching footer settings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      color: const Color(0xFF2C1A0E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF15A24), Color(0xFFFF8C42)]), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Lunch Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFF3E2723), height: 1),
          const SizedBox(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              if (_supportLinks.isNotEmpty) _footerCol(context, 'Support', _supportLinks),
              if (_legalLinks.isNotEmpty) _footerCol(context, 'Legal', _legalLinks),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFF3E2723), height: 1),
          const SizedBox(height: 16),
          Text(_copyright, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _footerCol(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 10),
        ...items.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {
              final slug = e.toLowerCase().replaceAll(' ', '-');
              Navigator.push(context, MaterialPageRoute(builder: (_) => ContentPage(slug: slug)));
            },
            child: Text(e, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          ),
        )),
      ],
    );
  }
}
