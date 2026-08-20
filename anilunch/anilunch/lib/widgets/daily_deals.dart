import 'package:flutter/material.dart';
import 'deal_card.dart';

class DailyDeals extends StatelessWidget {
  final List<Map<String, dynamic>> deals;

  const DailyDeals({super.key, required this.deals});

  IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'delivery_dining_rounded': return Icons.delivery_dining_rounded;
      case 'savings_rounded': return Icons.savings_rounded;
      case 'star_rounded': return Icons.star_rounded;
      case 'local_offer_rounded': return Icons.local_offer_rounded;
      case 'bolt_rounded': return Icons.bolt_rounded;
      case 'percent_rounded':
      default: return Icons.percent_rounded;
    }
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFFF15A24);
    try {
      String hex = hexString;
      if (hex.startsWith('#')) {
        hex = '0xFF${hex.substring(1)}';
      }
      return Color(int.parse(hex));
    } catch (_) {
      return const Color(0xFFF15A24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Deals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2C1A0E))),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: deals.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final deal = deals[index];
                return DealCard(
                  title: deal['title'] ?? '',
                  subtitle: deal['subtitle'] ?? '',
                  tagText: deal['tag_text'] ?? 'Today Only',
                  color: _parseColor(deal['color_hex']),
                  icon: _parseIcon(deal['icon_name']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
