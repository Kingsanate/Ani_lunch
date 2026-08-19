import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/lunch_provider.dart';
import '../widgets/customization_bottom_sheet.dart';
import 'lunch_checkout_sheet.dart';
import '../pages/cart_page.dart';

class LunchProductDetailsView extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const LunchProductDetailsView({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<LunchProductDetailsView> createState() => _LunchProductDetailsViewState();
}

class _LunchProductDetailsViewState extends State<LunchProductDetailsView> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  int _currentImageIndex = 0;
  int _selectedPortionIndex = 0;
  int _selectedSpiceIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final productId = widget.product['id'].toString();
      final response = await Supabase.instance.client
          .from('product_reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(response);
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    double sum = 0;
    for (var review in _reviews) {
      sum += double.tryParse(review['rating']?.toString() ?? '5.0') ?? 5.0;
    }
    return sum / _reviews.length;
  }

  void _loadDummyReviews() {
    _reviews = [
      {
        'customer_name': 'Rohan Sharma',
        'rating': 4.5,
        'comment': 'Absolutely delicious! The meat was tender and the packaging was spill-proof. Highly recommended.',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'customer_name': 'Priya Singh',
        'rating': 5.0,
        'comment': 'Best quality food I have ordered in a while. The taste is very authentic and feels home-cooked.',
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'customer_name': 'Vikram Patel',
        'rating': 4.0,
        'comment': 'Great portion size and fast delivery. The spices were perfectly balanced. Will order again.',
        'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      },
    ];
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final name = review['customer_name']?.toString() ?? 'Anonymous';
    final rating = review['rating']?.toString() ?? '5.0';
    final comment = review['comment']?.toString() ?? '';
    
    // Parse date for simple display (e.g. "2 days ago" placeholder logic, but here just a simple text)
    final dateStr = review['created_at']?.toString() ?? '';
    String displayDate = 'Recently';
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        final diff = DateTime.now().difference(date);
        if (diff.inDays == 0) displayDate = 'Today';
        else if (diff.inDays == 1) displayDate = 'Yesterday';
        else displayDate = '${diff.inDays} days ago';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFF15A24).withValues(alpha: 0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'A', style: const TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Text(displayDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (index) {
                final doubleRating = double.tryParse(rating) ?? 5.0;
                if (index < doubleRating.floor()) {
                  return const Icon(Icons.star, color: Color(0xFFFFB800), size: 16);
                } else if (index < doubleRating) {
                  return const Icon(Icons.star_half, color: Color(0xFFFFB800), size: 16);
                } else {
                  return const Icon(Icons.star_border, color: Color(0xFFFFB800), size: 16);
                }
              }),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read the latest product data from the provider to enable realtime updates
    final provider = context.watch<LunchProvider>();
    final product = provider.products.firstWhere(
      (p) => p['id'] == widget.product['id'],
      orElse: () => widget.product,
    );

    final name = product['name']?.toString() ?? '';
    final description = product['description']?.toString() ?? '';
    final price = product['price'];
    final discountPrice = product['discount_price'];
    final imageUrl = product['image_url']?.toString();
    final isAvailable = product['is_available'] == true;

    final displayPrice = discountPrice ?? price;
    
    // Create an image list with the primary image and any additional images
    final List<String> carouselImages = [];
    if (imageUrl != null && imageUrl.isNotEmpty) carouselImages.add(imageUrl);
    
    final imageUrl2 = product['image_url_2']?.toString();
    if (imageUrl2 != null && imageUrl2.isNotEmpty) carouselImages.add(imageUrl2);
    
    final imageUrl3 = product['image_url_3']?.toString();
    if (imageUrl3 != null && imageUrl3.isNotEmpty) carouselImages.add(imageUrl3);

    if (carouselImages.isEmpty) {
      carouselImages.add('https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1000&auto=format&fit=crop');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Container(
              margin: const EdgeInsets.all(16),
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(70),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: carouselImages.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => _FullScreenImageViewer(
                                    imageUrls: carouselImages,
                                    initialIndex: index,
                                    productId: product['id'].toString(),
                                  ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: index == 0 ? 'product-${product['id']}' : carouselImages[index],
                            child: CachedNetworkImage(
                              imageUrl: carouselImages[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.white, child: const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24)))),
                              errorWidget: (context, url, error) => Container(color: Colors.white, child: const Icon(Icons.fastfood, size: 80, color: Colors.grey)),
                            ),
                          ),
                        );
                      },
                    ),
                    // Custom Page Indicator
                    Positioned(
                      bottom: 16,
                      right: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(carouselImages.length, (index) {
                          final isActive = _currentImageIndex == index;
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: isActive ? 16 : 8,
                            height: isActive ? 16 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.8),
                              border: isActive ? Border.all(color: Colors.white, width: 1.5) : null,
                            ),
                            child: isActive
                                ? Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        }),
                      ),
                    ),
                    // Top Left Back Button
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Top Right Action Button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Center(
                            child: Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E)),
                        ),
                      ),
                      // Dynamic Rating Badge
                      if (_reviews.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(_averageRating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (discountPrice != null && discountPrice != price)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text('₹$price', style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                            ),
                          Text('₹$displayPrice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFF15A24))),
                        ],
                      ),
                      // Customize Button
                      ElevatedButton.icon(
                        onPressed: () async {
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
                        },
                        icon: const Icon(Icons.tune, size: 16, color: Colors.white),
                        label: const Text('Customize', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF15A24),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.5)),
                  const SizedBox(height: 24),
                  
                  // --- CUSTOMER REVIEWS SECTION ---
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E))),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
                          const SizedBox(width: 4),
                          Text(_averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(' (${_reviews.length})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoadingReviews)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Color(0xFFF15A24)),
                    ))
                  else
                    ..._reviews.map((review) => _buildReviewCard(review)),
                  
                  const SizedBox(height: 24),
                  
                  if (!isAvailable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Currently Unavailable', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
          ],
        ),
      )),
      bottomNavigationBar: isAvailable ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CustomizationBottomSheet(product: product),
                      );
                      // CustomizationBottomSheet already handles adding to cart internally.
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFFF15A24)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add To Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF15A24))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CustomizationBottomSheet(product: product),
                      );
                      if (result == true && context.mounted) {
                        // It was added to cart provider with customizations, now launch checkout with that cart item
                        final lunchProvider = context.read<LunchProvider>();
                        final lastAddedItem = lunchProvider.cart.last;
                        
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => LunchCheckoutSheet(
                            cartItems: [
                              {
                                'product': lastAddedItem['product'],
                                'quantity': 1,
                                'customizations': lastAddedItem['customizations'],
                                'custom_price': lastAddedItem['custom_price'],
                              }
                            ],
                            isLunchMode: true,
                            onSuccess: () {
                              // We should probably remove it from the cart if they buy it now?
                              // Or just leave it as standard behavior.
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFFF15A24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Order Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String productId;
  const _FullScreenImageViewer({required this.imageUrls, required this.initialIndex, required this.productId});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: index == 0 ? 'product-${widget.productId}' : widget.imageUrls[index],
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24))),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
          );
        },
      ),
    );
  }
}
