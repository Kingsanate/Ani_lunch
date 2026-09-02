import 'package:flutter/material.dart';

class CartItemDetailsDialog extends StatelessWidget {
  final String title;
  final num price;
  final String? imageUrl;
  final int quantity;
  final Map<String, String>? customizations;

  const CartItemDetailsDialog({
    super.key,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.customizations,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Image and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: () {
                      if (imageUrl != null && imageUrl!.startsWith('assets/')) {
                        return Image.asset(
                          imageUrl!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Image.asset('assets/images/bento.png', fit: BoxFit.cover),
                        );
                      }
                      if (imageUrl != null && imageUrl!.startsWith('http')) {
                        return Image.network(
                          imageUrl!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Image.asset('assets/images/bento.png', fit: BoxFit.cover),
                        );
                      }
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[100],
                        child: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
                      );
                    }(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                      const SizedBox(height: 4),
                      Text('₹$price per item', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Customizations
            if (customizations != null) ...[
              const Text('Customizations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFDED4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customizations!.containsKey('Rice')) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rice:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(customizations!['Rice']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (customizations!.containsKey('Meat')) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Meat:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(customizations!['Meat']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Summary
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text('$quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('₹${(price * quantity)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
              ],
            ),
            const SizedBox(height: 24),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF15A24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
