import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../views/lunch_product_details_view.dart';
import '../widgets/customization_bottom_sheet.dart';
import '../widgets/bouncy_tap.dart';
import '../pages/cart_page.dart';

class LunchProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const LunchProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final description = product['description']?.toString() ?? '';
    final price = product['price'];
    final discountPrice = product['discount_price'];
    final imageUrl = product['image_url']?.toString();
    final isAvailable = product['is_available'] == true;

    return BouncyTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LunchProductDetailsView(
              product: product,
              onAddToCart: onAddToCart,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Edge-to-edge Background Image
              if (imageUrl != null && imageUrl.isNotEmpty)
                Hero(
                  tag: 'product-${product['id']}',
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  ),
                )
              else
                _buildPlaceholder(),

              // Dark overlay if out of stock
              if (!isAvailable)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: const Text(
                    'Sold Out',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                  ),
                ),

              // Bottom Dark Gradient for text readability
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 90, // Reduced gradient height
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Product Info & Price
              Positioned(
                bottom: 8, left: 10, right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (discountPrice != null && discountPrice != price)
                          Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 2),
                            child: Text(
                              '₹$price',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.5),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        Text(
                          '₹${discountPrice ?? price}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Floating Circular ADD Button
              Positioned(
                bottom: 8, right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isAvailable ? () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CustomizationBottomSheet(product: product),
                      );
                      if (result == true && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Your Cart'),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                              ),
                              body: const CartPage(),
                            ),
                          ),
                        );
                      }
                    } : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 30, // Reduced size
                      width: 30, // Reduced size
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFFF15A24) : Colors.grey.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF15A24).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: isAvailable ? Colors.white : Colors.white54,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.restaurant, size: 28, color: Colors.black12)),
    );
  }
}
