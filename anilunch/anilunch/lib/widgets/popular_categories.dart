import 'package:flutter/material.dart';

class PopularCategories extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedId;
  final Function(String) onSelected;

  const PopularCategories({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Text('Explore Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2C1A0E), letterSpacing: 0.2)),
        ),
      ],
    );
  }
}
