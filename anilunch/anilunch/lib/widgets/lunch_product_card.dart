import 'package:flutter/material.dart';
import '../views/lunch_product_details_view.dart';
import '../widgets/customization_bottom_sheet.dart';
import '../widgets/bouncy_tap.dart';

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
    final resolvedImage = resolveDishImageUrl(name, imageUrl);

    return BouncyTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LunchProductDetailsView(
              product: {
                ...product,
                'image_url': resolvedImage,
              },
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
              Hero(
                tag: 'product-${product['id']}',
                child: _buildProductImage(resolvedImage, name),
              ),

              // Dark overlay if out of stock
              if (!isAvailable)
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'SOLD OUT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

              // Discount badge in top-left
              if (discountPrice != null && discountPrice != price && isAvailable)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Bottom Dark Gradient for text readability
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 95,
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
                bottom: 8, left: 10, right: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${discountPrice ?? price}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        if (discountPrice != null && discountPrice != price) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
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
                    onTap: isAvailable ? () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CustomizationBottomSheet(product: product),
                      );
                    } : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFFF15A24) : Colors.grey.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF15A24).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: isAvailable ? Colors.white : Colors.white54,
                          size: 20,
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

  static String resolveDishImageUrl(String name, String? originalUrl) {
    final lower = name.toLowerCase();
    if (lower.contains('mizo')) {
      return 'assets/images/pork.png';
    }
    if (lower.contains('naga')) {
      return 'assets/images/beef.png';
    }
    if (lower.contains('khasi')) {
      return 'assets/images/chicken.png';
    }
    if (lower.contains('indian') || lower.contains('thali')) {
      return 'assets/images/bento.png';
    }
    if (lower.contains('salad') || lower.contains('veg')) {
      return 'assets/images/salad.png';
    }
    if (lower.contains('chicken') || lower.contains('biryani')) {
      return 'assets/images/chicken.png';
    }
    if (lower.contains('pork') || lower.contains('mutton')) {
      return 'assets/images/pork.png';
    }
    if (lower.contains('beef') || lower.contains('meat')) {
      return 'assets/images/beef.png';
    }
    if (originalUrl != null &&
        originalUrl.startsWith('http') &&
        !originalUrl.contains('shillong') &&
        !originalUrl.contains('teer') &&
        !originalUrl.contains('dummy')) {
      return originalUrl;
    }
    return 'assets/images/bento.png';
  }

  Widget _buildProductImage(String resolvedImage, String name) {
    String fallbackAsset = 'assets/images/bento.png';
    final lower = name.toLowerCase();
    if (lower.contains('chicken') || lower.contains('biryani')) {
      fallbackAsset = 'assets/images/chicken.png';
    } else if (lower.contains('pork') || lower.contains('mutton')) {
      fallbackAsset = 'assets/images/pork.png';
    } else if (lower.contains('beef') || lower.contains('meat')) {
      fallbackAsset = 'assets/images/beef.png';
    } else if (lower.contains('salad') || lower.contains('veg')) {
      fallbackAsset = 'assets/images/salad.png';
    }

    if (resolvedImage.startsWith('assets/')) {
      return Image.asset(resolvedImage, fit: BoxFit.cover);
    }

    return Image.network(
      resolvedImage,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: const Color(0xFFF7F3F0));
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(fallbackAsset, fit: BoxFit.cover);
      },
    );
  }
}
