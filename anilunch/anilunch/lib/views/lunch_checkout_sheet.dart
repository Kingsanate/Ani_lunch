import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';
import '../services/payment_service.dart';
import '../services/secure_order_service.dart';
import 'order_success_page.dart';

class LunchCheckoutSheet extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback? onSuccess;
  final bool isLunchMode;

  const LunchCheckoutSheet({
    super.key,
    required this.cartItems,
    required this.isLunchMode,
    this.onSuccess,
  });

  @override
  State<LunchCheckoutSheet> createState() => _LunchCheckoutSheetState();
}

class _LunchCheckoutSheetState extends State<LunchCheckoutSheet> {
  late List<Map<String, dynamic>> _items;
  String _paymentMethod = 'COD';
  // Mirrors the server rule (₹30, free above ₹500) for display only; the
  // server remains authoritative for the final charge.
  int get _deliveryFee {
    var subtotal = 0;
    for (final item in _items) {
      final product = item['product'] ?? {};
      final price = item['custom_price'] ?? product['discount_price'] ?? product['item_price'] ?? product['price'] ?? 0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      subtotal += (price as num).toInt() * quantity;
    }
    return subtotal >= 500 ? 0 : 30;
  }
  String _address = 'Fetching address...';
  
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  Map<String, dynamic>? _appliedCoupon;
  int _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the items so we can adjust quantities locally
    _items = List<Map<String, dynamic>>.from(widget.cartItems.map((item) => Map<String, dynamic>.from(item)));
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // API-first: authoritative profile from the Go backend.
        try {
          final profile = await AniApi.instance.api.users.me();
          if (profile.address.isNotEmpty) {
            if (mounted) {
              setState(() {
                _address = profile.address;
              });
            }
            return;
          }
        } catch (e) {
          debugPrint('Error fetching address via API: $e');
        }

        // Legacy fallback: Supabase users table.
        final legacy = await Supabase.instance.client.from('users').select('address').eq('user_id', user.id).maybeSingle();
        if (legacy != null && legacy['address'] != null && legacy['address'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              _address = legacy['address'].toString();
            });
          }
          return;
        }
      }
    } catch(e) {
      debugPrint('Error fetching address: $e');
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(int subtotal) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);

    try {
      final response = await Supabase.instance.client
          .from('coupons')
          .select()
          .eq('code', code)
          .maybeSingle();

      if (response == null) {
        _showError('Invalid coupon code');
        setState(() => _isApplyingCoupon = false);
        return;
      }

      if (response['is_active'] != true) {
        _showError('This coupon is no longer active');
        setState(() => _isApplyingCoupon = false);
        return;
      }

      final minOrder = (response['min_order_amount'] as num?)?.toInt() ?? 0;
      if (subtotal < minOrder) {
        _showError('Minimum order amount of ₹$minOrder required for this coupon');
        setState(() => _isApplyingCoupon = false);
        return;
      }

      final expiry = response['expiration_date'];
      if (expiry != null && DateTime.parse(expiry).isBefore(DateTime.now())) {
        _showError('This coupon has expired');
        setState(() => _isApplyingCoupon = false);
        return;
      }

      // Valid coupon
      int calculatedDiscount = 0;
      final type = response['discount_type'];
      final value = (response['discount_value'] as num).toDouble();

      if (type == 'flat') {
        calculatedDiscount = value.toInt();
      } else if (type == 'percent') {
        calculatedDiscount = (subtotal * (value / 100)).toInt();
        final maxDiscount = (response['max_discount_amount'] as num?)?.toInt();
        if (maxDiscount != null && calculatedDiscount > maxDiscount) {
          calculatedDiscount = maxDiscount;
        }
      }
      
      if (calculatedDiscount > subtotal) {
        calculatedDiscount = subtotal;
      }

      if (mounted) {
        setState(() {
          _appliedCoupon = response;
          _discountAmount = calculatedDiscount;
          _isApplyingCoupon = false;
        });
      }

    } catch (e) {
      _showError('Error: $e');
      if (mounted) {
        setState(() => _isApplyingCoupon = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Coupon Status'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _increaseQuantity(int index) {
    setState(() => _items[index]['quantity']++);
  }
  
  void _decreaseQuantity(int index) {
    setState(() {
      if (_items[index]['quantity'] > 1) {
        _items[index]['quantity']--;
      } else {
        _items.removeAt(index);
      }
    });
  }

  Future<void> _confirmOrder() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to place an order')));
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    // Show loading indicator
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24))));

    try {
      int subtotal = 0;
      final List<Map<String, dynamic>> cleanItems = [];
      final List<String> productIds = [];

      for (var item in _items) {
        final product = item['product'] ?? {};
        final price = item['custom_price'] ?? product['discount_price'] ?? product['item_price'] ?? product['price'] ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        subtotal += (price as num).toInt() * quantity;
        
        cleanItems.add({
          'id': product['id'].toString(),
          'title': product['item_title'] ?? product['name']?.toString() ?? 'Item',
          'price': price,
          'quantity': quantity,
          'image': product['thumbnail_url'] ?? product['image_url'],
          'isMeat': item['isMeat'] ?? false,
          'customizations': item['customizations'],
        });
        productIds.add(product['id'].toString());
      }
      
      final total = subtotal + _deliveryFee;

      // API-first placement: server-authoritative pricing via the Go backend,
      // including customization extras (extra meat pieces) priced server-side.
      String newOrderId = '';
      bool isOfflineDraft = false;

      try {
        final apiItems = cleanItems.map((i) => <String, dynamic>{
          'item_id': i['id'],
          'quantity': i['quantity'],
          'customizations': i['customizations'],
        }).toList();
        final result = await SecureOrderService.instance.placeOrder(
          userId: user.id,
          cartItems: apiItems,
          paymentMethod: _paymentMethod,
          orderType: widget.isLunchMode ? 'lunch' : 'meat',
          couponCode: _appliedCoupon?['code'],
          deliveryStreet: _address,
        );
        if (result['success'] == true) {
          final order = result['order'];
          newOrderId = order is Order
              ? order.id
              : (order?['id'] ?? result['order_id']).toString();
          isOfflineDraft = result['is_offline_draft'] == true;
        }
      } catch (e) {
        debugPrint('API order placement failed: $e');
      }

      if (newOrderId.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // close loading
          _showError('Could not place order. Please try again.');
        }
        return;
      }

      if (_paymentMethod == 'Online') {
        if (isOfflineDraft) {
          if (mounted) {
            Navigator.pop(context); // close loading
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Order saved offline. Payment will be initiated once you are back online.')));
          }
          return;
        }

        final paymentResult = await PaymentService.processOnlinePayment(
          orderId: newOrderId,
          amount: total.toDouble(),
          customerName: user.userMetadata?['full_name'] ?? 'User',
          customerEmail: user.email ?? '',
          customerPhone: user.userMetadata?['phone_number'] ?? '',
        );

        if (paymentResult != 'launched') {
          if (mounted) {
            Navigator.pop(context); // close loading
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed or was cancelled'), backgroundColor: Colors.red));
          }
          return;
        }
      }

      if (mounted) {
        Navigator.pop(context); // close loading
        Navigator.pop(context); // close sheet
        
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }

        // Navigate to Order Success Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: newOrderId)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int subtotal = 0;
    int totalItems = 0;
    
    for (var item in _items) {
      final product = item['product'] ?? {};
      final price = item['custom_price'] ?? product['discount_price'] ?? product['item_price'] ?? product['price'] ?? 0;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      subtotal += (price as num).toInt() * quantity;
      totalItems += quantity;
    }
    
    final total = subtotal > 0 ? (subtotal + _deliveryFee - _discountAmount) : 0;
    final displayTotal = total < 0 ? 0 : total;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Checkout',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E)),
                    ),
                    Text('${_items.length} item(s)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Colors.black12),
                
                // Product Items List
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  final product = item['product'] ?? {};
                  final name = product['item_title'] ?? product['name']?.toString() ?? 'Item';
                  final price = item['custom_price'] ?? product['discount_price'] ?? product['item_price'] ?? product['price'] ?? 0;
                  final imageUrl = product['thumbnail_url'] ?? product['image_url']?.toString();
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                  final itemSubtotal = (price as num).toInt() * quantity;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFFF7F3F0),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl ?? '',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => const Icon(Icons.fastfood, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('₹$itemSubtotal', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                              Text('₹$price each', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        // Quantity Control
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (quantity > 1) {
                                  setState(() => _items[index]['quantity']--);
                                } else {
                                  setState(() => _items.removeAt(index));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  quantity <= 1 ? Icons.delete_outline : Icons.remove,
                                  size: 16,
                                  color: const Color(0xFFF15A24),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _items[index]['quantity']++);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.add, size: 16, color: Color(0xFFF15A24)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                
                // Deliver To Address Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F2),
                    border: Border.all(color: const Color(0xFFFFDED4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFFF15A24), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Deliver to:', style: TextStyle(fontSize: 12, color: Color(0xFFF15A24), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              _address,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Use Current Location
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    border: Border.all(color: const Color(0xFFD4E8FF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.blue, size: 18),
                      SizedBox(width: 12),
                      Text('Use Current Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Apply Coupon Section
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Text('Have a Coupon?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: 'Enter coupon code',
                                hintStyle: const TextStyle(fontSize: 13),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isApplyingCoupon || _appliedCoupon != null ? null : () => _applyCoupon(subtotal),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF15A24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isApplyingCoupon 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(_appliedCoupon != null ? 'Applied' : 'Apply', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      if (_appliedCoupon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text('Code ${_appliedCoupon!['code']} applied (-₹$_discountAmount)', style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _appliedCoupon = null;
                                      _discountAmount = 0;
                                      _couponController.clear();
                                    });
                                  },
                                  child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Payment Method
                  const Center(
                    child: Text('Select Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = 'COD'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'COD' ? const Color(0xFFFFF5F2) : Colors.white,
                              border: Border.all(color: _paymentMethod == 'COD' ? const Color(0xFFF15A24) : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.money, color: _paymentMethod == 'COD' ? const Color(0xFFF15A24) : Colors.grey),
                                const SizedBox(height: 8),
                                Text('COD', style: TextStyle(fontWeight: FontWeight.bold, color: _paymentMethod == 'COD' ? const Color(0xFFF15A24) : Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = 'Online'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'Online' ? const Color(0xFFFFF5F2) : Colors.white,
                              border: Border.all(color: _paymentMethod == 'Online' ? const Color(0xFFF15A24) : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.credit_card, color: _paymentMethod == 'Online' ? const Color(0xFFF15A24) : Colors.grey),
                                const SizedBox(height: 8),
                                Text('Online', style: TextStyle(fontWeight: FontWeight.bold, color: _paymentMethod == 'Online' ? const Color(0xFFF15A24) : Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Price Breakdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text('₹$subtotal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery fee', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text('₹$_deliveryFee', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (_discountAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500)),
                          Text('-₹$_discountAmount', style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.black12, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      Text('₹$displayTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFF15A24))),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Bottom Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFF15A24)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirmOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF15A24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
