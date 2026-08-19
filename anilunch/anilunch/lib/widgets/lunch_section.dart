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
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFF15A24))),
          );
        }

        if (provider.error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('Error loading lunch products', style: const TextStyle(color: Colors.red))),
          );
        }

        final products = provider.products;
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No lunch products available right now.', style: TextStyle(color: Colors.grey))),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
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
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
