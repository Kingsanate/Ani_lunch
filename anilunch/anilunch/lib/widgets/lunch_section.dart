import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lunch_provider.dart';
import 'lunch_product_card.dart';

class LunchSection extends StatelessWidget {
  const LunchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LunchProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant, color: Colors.grey[300], size: 32),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 50, height: 8, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ),
          );
        }

        if (provider.error != null && provider.products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Unable to load meals. Pull down to refresh.', style: TextStyle(color: Colors.grey, fontSize: 12))),
          );
        }

        final products = provider.products;
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Fresh meals being prepared. Check back soon!', style: TextStyle(color: Colors.grey, fontSize: 13))),
          );
        }

        final width = MediaQuery.of(context).size.width;
        final int crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
        final double childAspectRatio = width > 900 ? 1.75 : (width > 600 ? 1.60 : 1.45);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return LunchProductCard(
                product: product,
                onAddToCart: () {
                  provider.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product['name']} added to Lunch Cart!'),
                      backgroundColor: const Color(0xFF16A34A),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
