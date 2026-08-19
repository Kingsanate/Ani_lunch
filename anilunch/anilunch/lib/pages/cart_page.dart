import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../providers/lunch_provider.dart';
import '../widgets/cart_item_details_dialog.dart';
import '../providers/menu_provider.dart';
import '../views/lunch_checkout_sheet.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lunchProvider = context.watch<LunchProvider>();
    final cartProvider = context.watch<CartProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final lunchCart = lunchProvider.cart;

    final meatCartItems = cartProvider.getCartItems(menuProvider.itemsByCategory);
    int meatTotal = cartProvider.calculateTotal(menuProvider.itemsByCategory);

    int lunchTotal = 0;
    for (var item in lunchCart) {
      final price = item['custom_price'] ?? item['product']['discount_price'] ?? item['product']['item_price'] ?? item['product']['price'] ?? 0;
      final quantity = item['quantity'] ?? 1;
      lunchTotal += (price as num).toInt() * (quantity as num).toInt();
    }

    final activeCartEmpty = lunchCart.isEmpty && meatCartItems.isEmpty;
    final activeTotal = lunchTotal + meatTotal;

    if (activeCartEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text('Your Cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (meatCartItems.isNotEmpty) ...[
                  const Text('Meat Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                  const SizedBox(height: 12),
                  ...meatCartItems.map((item) => _buildMeatCartItem(context, item, cartProvider)),
                  const SizedBox(height: 24),
                ],
                if (lunchCart.isNotEmpty) ...[
                  const Text('Lunch Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                  const SizedBox(height: 12),
                  ...lunchCart.map((item) => _buildLunchCartItem(context, item, lunchProvider)),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, -4))
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text('Total to pay', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('₹$activeTotal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2C1A0E))),
                  ]
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final checkoutItems = [
                          ...lunchCart.map((item) => ({...item, 'isMeat': false})),
                          ...meatCartItems.map((item) => ({...item, 'isMeat': true})),
                        ];
                            
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => LunchCheckoutSheet(
                            cartItems: checkoutItems,
                            isLunchMode: true,
                            onSuccess: () {
                              lunchProvider.clearCart();
                              cartProvider.clearCart();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15A24),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeatCartItem(BuildContext context, Map<String, dynamic> item, CartProvider cartProvider) {
    final product = (item['product'] as Map<String, dynamic>?) ?? item;
    final quantity = (item['qty'] as num?)?.toInt() ?? (item['quantity'] as num?)?.toInt() ?? 1;
    final catId = (item['catId'] ?? product['catId']).toString();
    final title = product['item_title'] ?? product['name']?.toString() ?? 'Meat Item';
    final price = product['item_price'] ?? product['price'] ?? 0;
    final imageUrl = product['thumbnail_url'] ?? product['image_url']?.toString();

    return _buildCartCard(title, price, imageUrl, quantity, () {
      cartProvider.decrementItem(catId, product['id'].toString());
    }, () {
      cartProvider.incrementItem(catId, product['id'].toString());
    });
  }

  Widget _buildLunchCartItem(BuildContext context, Map<String, dynamic> item, LunchProvider provider) {
    final product = item['product'] ?? {};
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final title = product['name'] ?? product['item_title']?.toString() ?? 'Lunch Item';
    final price = item['custom_price'] ?? product['discount_price'] ?? product['item_price'] ?? product['price'] ?? 0;
    final imageUrl = product['image_url'] ?? product['thumbnail_url']?.toString();
    
    final cartItemId = item['cartItemId']?.toString();
    final customizations = item['customizations'] as Map<String, String>?;

    return _buildCartCard(title, price, imageUrl, quantity, () {
      provider.updateQuantity(cartItemId ?? product['id'].toString(), quantity - 1, isCartItemId: cartItemId != null);
    }, () {
      provider.updateQuantity(cartItemId ?? product['id'].toString(), quantity + 1, isCartItemId: cartItemId != null);
    }, customizations: customizations, onTap: () {
      showDialog(
        context: context,
        builder: (context) => CartItemDetailsDialog(
          title: title,
          price: price,
          imageUrl: imageUrl,
          quantity: quantity,
          customizations: customizations,
        ),
      );
    });
  }

  Widget _buildCartCard(String title, num price, String? imageUrl, int quantity, VoidCallback onMinus, VoidCallback onPlus, {Map<String, String>? customizations, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: imageUrl, width: 64, height: 64, fit: BoxFit.cover)
                : Container(width: 64, height: 64, color: Colors.grey[100], child: const Icon(Icons.fastfood, color: Colors.grey, size: 24)),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C1A0E), letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (customizations != null && customizations.isNotEmpty) ...[
                    Text(
                      customizations.entries.map((e) => '${e.value}').join('  •  '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      'Standard',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Bottom Row: Price and Qty
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹$price', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFF15A24)),
                      ),
                      // Sleek Quantity Selector
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF15A24).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF15A24).withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: onMinus,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Icon(
                                  quantity == 1 ? Icons.delete_outline : Icons.remove, 
                                  size: 14, 
                                  color: quantity == 1 ? Colors.red : const Color(0xFFF15A24),
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              alignment: Alignment.center,
                              child: Text(
                                '$quantity', 
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2C1A0E)),
                              ),
                            ),
                            InkWell(
                              onTap: onPlus,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                              child: Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: const Icon(Icons.add, size: 14, color: const Color(0xFFF15A24)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
