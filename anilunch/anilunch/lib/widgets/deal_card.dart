import 'package:flutter/material.dart';

class DealCard extends StatelessWidget {
  final String title, subtitle, tagText;
  final Color color;
  final IconData icon;

  const DealCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.tagText = 'Today Only',
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth * 0.65;
    if (cardWidth > 220) cardWidth = 220;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12, bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tagText.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
