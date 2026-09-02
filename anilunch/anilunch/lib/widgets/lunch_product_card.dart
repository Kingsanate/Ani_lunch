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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'SOLD OUT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

              // Deal badge in top-left
              if (discountPrice != null && discountPrice != price && isAvailable)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Text(
                      'DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

              // Bottom Dark Gradient for text readability
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black.withValues(alpha: 0.50),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Product Info & Price
              Positioned(
                bottom: 6, left: 8, right: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${discountPrice ?? price}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (discountPrice != null && discountPrice != price) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white.withValues(alpha: 0.55),
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
                bottom: 6, right: 6,
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFFF15A24) : Colors.grey.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x73F15A24),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
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
    if (originalUrl != null && originalUrl.isNotEmpty) {
      if (originalUrl.startsWith('assets/')) {
        return originalUrl;
      }
      if (originalUrl.startsWith('http') &&
          !originalUrl.contains('shillong') &&
          !originalUrl.contains('teer') &&
          !originalUrl.contains('dummy')) {
        return originalUrl;
      }
    }

    final lower = name.toLowerCase();
    if (lower.contains('mizo')) {
      return 'assets/images/pork.png';
    }
    if (lower.contains('naga')) {
      return 'assets/images/chicken.png';
    }
    if (lower.contains('khasi')) {
      return 'assets/images/beef.png';
    }
    if (lower.contains('indian') || lower.contains('bento') || lower.contains('thali') || lower.contains('lunch')) {
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
