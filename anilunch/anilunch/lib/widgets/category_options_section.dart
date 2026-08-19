import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryOptionsSection extends StatelessWidget {
  final String categoryId;
  final Map<String, List<Map<String, dynamic>>> allCategoryData;
  final Map<String, Map<String, int>> categoryCarts;
  final Function(String itemId, String catId) onToggleItem;

  const CategoryOptionsSection({
    super.key,
    required this.categoryId,
    required this.allCategoryData,
    required this.categoryCarts,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayProducts = categoryId == 'all'
        ? allCategoryData.values.expand((e) => e).toList()
        : allCategoryData[categoryId] ?? [];

    if (displayProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No items in this category', style: TextStyle(color: Colors.grey))),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryId == 'all' ? 'All Specialities' : 'Specialities',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E)),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayProducts.length,
            separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFF0F0F0)),
            itemBuilder: (context, index) {
              final item = displayProducts[index];
              final itemId = item['id'].toString();
              final realCatId = item['catId']?.toString() ?? categoryId;
              final isSelected = categoryCarts[realCatId]?.containsKey(itemId) ?? false;

              return GestureDetector(
                onTap: () => onToggleItem(itemId, realCatId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF2C1A0E)),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text('₹${item['price']}', style: const TextStyle(color: Color(0xFF2C1A0E), fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 6),
                            const Text(
                              'Fresh, high quality, expertly cut. Ready to cook.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => onToggleItem(itemId, realCatId),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 100,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF8CC63F) : const Color(0xFFF15A24),
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isSelected ? Icons.check_rounded : Icons.add_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(isSelected ? 'Added' : 'Add', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ]
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 100,
                              height: 100,
                              color: const Color(0xFFF7F3F0),
                              child: _buildImage(item['image'] as String),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(width: 100, height: 100, color: Colors.grey[100], child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        errorWidget: (context, url, error) => Container(width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.error_outline)),
      );
    }
    return Image.asset(imagePath, width: 100, height: 100, fit: BoxFit.cover);
  }
}
