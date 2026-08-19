import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:anilunch_core/anilunch_core.dart' as core;

import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/lunch_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/hero_section.dart';
import '../widgets/daily_deals.dart';
import '../widgets/popular_categories.dart';
import '../widgets/category_options_section.dart';
import '../widgets/footer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/lunch_section.dart';
import '../models/smart_image.dart';
import '../services/payment_service.dart';
import '../services/secure_order_service.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';
import 'edit_information_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _profileImageUrl;
  String? _profileAddressText;

  double? _customerLat;
  double? _customerLng;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    final auth = context.read<AuthProvider>();
    _fetchProfile(auth.user);
    final menu = context.read<MenuProvider>();
    final order = context.read<OrderProvider>();
    if (auth.user != null) {
      order.fetchOrders(auth.user!.id, isLunchMode: true);
      order.subscribeToUpdates(auth.user!.id, isLunchMode: true);
    }
  }

  Future<void> _fetchProfile(User? user) async {
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('users')
          .select('profile_image_url, address')
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted && profile != null) {
        setState(() {
          _profileImageUrl = profile['profile_image_url']?.toString();
          _profileAddressText = profile['address']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _customerLat = position.latitude;
        _customerLng = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOrderSheet() {
    final cart = context.read<CartProvider>();
    final menu = context.read<MenuProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedPaymentMethod = 'COD';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cartItems = cart.getCartItems(menu.itemsByCategory);
final total = cart.calculateTotal(menu.itemsByCategory);
            // Display-only mirror of the server fee rule (₹30, free ≥ ₹500).
            final deliveryFee = total >= 500 ? 0 : 30;
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.80),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(children: [
                      const Text('Your Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E))),
                      const Spacer(),
                      Text('${cartItems.length} item${cartItems.length != 1 ? 's' : ''}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ]),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (_, i) {
                        final item = cartItems[i];
                        final itemId = item['id'].toString();
                        final catId = item['catId'].toString();
                        final qty = item['qty'] as int;
                        final itemPrice = item['price'] as int;
                        return Row(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: SmartImage(item['image'] as String, width: 52, height: 52, fit: BoxFit.cover)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2C1A0E)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('₹${itemPrice * qty}', style: const TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('₹$itemPrice each', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ])),
                          Row(children: [
                            GestureDetector(
                              onTap: () {
                                cart.decrementItem(catId, itemId);
                                setSheetState(() {});
                              },
                              child: Container(width: 28, height: 28,
                                decoration: BoxDecoration(color: qty == 1 ? Colors.red[50] : const Color(0xFFF15A24).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Icon(qty == 1 ? Icons.delete_outline : Icons.remove, size: 16,
                                  color: qty == 1 ? Colors.red : const Color(0xFFF15A24))),
                            ),
                            SizedBox(width: 32, child: Text('$qty', textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            GestureDetector(
                              onTap: () { cart.incrementItem(catId, itemId); setSheetState(() {}); },
                              child: Container(width: 28, height: 28,
                                decoration: BoxDecoration(color: const Color(0xFFF15A24).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.add, size: 16, color: Color(0xFFF15A24))),
                            ),
                          ]),
                        ]);
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))]),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFF15A24).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF15A24).withValues(alpha: 0.1))),
                        child: Row(children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFFF15A24), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Deliver to:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                            Text(_profileAddressText ?? Supabase.instance.client.auth.currentUser?.userMetadata?['address']?.toString() ?? 'No address set',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2C1A0E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          TextButton(
                            onPressed: () async {
                              final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditInformationPage()));
                              if (updated == true) { _fetchProfile(Supabase.instance.client.auth.currentUser); setSheetState(() {}); }
                            },
                            child: const Text('Change', style: TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async { await _fetchLocation(); setSheetState(() {}); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: _customerLat != null ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (_customerLat != null ? Colors.green : Colors.blue).withValues(alpha: 0.2))),
                          child: Row(children: [
                            Icon(Icons.my_location, color: _customerLat != null ? Colors.green : Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Use Current Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _customerLat != null ? Colors.green : Colors.blue)),
                              if (_customerLat != null) const Text('GPS coordinates captured', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ])),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: InkWell(
                          onTap: () => setSheetState(() => selectedPaymentMethod = 'COD'),
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: selectedPaymentMethod == 'COD' ? const Color(0xFFF15A24).withValues(alpha: 0.1) : Colors.white,
                              border: Border.all(color: selectedPaymentMethod == 'COD' ? const Color(0xFFF15A24) : Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                            child: Column(children: [Icon(Icons.money, size: 20, color: selectedPaymentMethod == 'COD' ? const Color(0xFFF15A24) : Colors.grey),
                              const Text('COD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: InkWell(
                          onTap: () => setSheetState(() => selectedPaymentMethod = 'Online'),
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: selectedPaymentMethod == 'Online' ? const Color(0xFFF15A24).withValues(alpha: 0.1) : Colors.white,
                              border: Border.all(color: selectedPaymentMethod == 'Online' ? const Color(0xFFF15A24) : Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                            child: Column(children: [Icon(Icons.payment, size: 20, color: selectedPaymentMethod == 'Online' ? const Color(0xFFF15A24) : Colors.grey),
                              const Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                          ),
                        )),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)), const Spacer(),
                        Text('₹$total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C1A0E)))]),
                      const SizedBox(height: 4),
                      Row(children: [const Text('Delivery fee', style: TextStyle(fontSize: 14, color: Colors.grey)), const Spacer(),
                        Text('₹$deliveryFee', style: const TextStyle(fontSize: 14, color: Colors.grey))]),
                      const Divider(height: 20),
                      Row(children: [const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const Spacer(),
                        Text('₹${total + deliveryFee}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF15A24)))]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF15A24), side: const BorderSide(color: Color(0xFFF15A24)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: ElevatedButton(
                          onPressed: () async {
                            final savedItems = cart.getCartItems(menu.itemsByCategory);
                            final savedTotal = cart.calculateTotal(menu.itemsByCategory);
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            nav.pop();
                            showDialog(context: context, barrierDismissible: false,
                              builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24))));
                            try {
                              final user = Supabase.instance.client.auth.currentUser;
                              final addressText = _profileAddressText ?? user?.userMetadata?['address']?.toString() ?? '';
                              if (addressText.isEmpty || addressText == 'No address provided') {
                                nav.pop();
                                messenger.showSnackBar(const SnackBar(content: Text('Please update your delivery address before confirming.'),
                                  backgroundColor: Colors.red, duration: Duration(seconds: 4)));
                                return;
                              }

                              // API-first placement: server-authoritative pricing via the Go backend.
                              String newOrderId = '';
                              bool isOfflineDraft = false;
                              try {
                                final apiItems = savedItems.map((item) => <String, dynamic>{
                                  'item_id': item['id']?.toString(),
                                  'quantity': item['qty'] ?? 1,
                                }).toList();
                                final result = await SecureOrderService.instance.placeOrder(
                                  userId: user!.id,
                                  cartItems: apiItems,
                                  paymentMethod: selectedPaymentMethod,
                                  orderType: 'meat',
                                  deliveryStreet: addressText,
                                  deliveryLat: _customerLat,
                                  deliveryLng: _customerLng,
                                );
                                if (result['success'] == true) {
                                  final order = result['order'];
                                  newOrderId = order is core.Order
                                      ? order.id
                                      : (order?['id'] ?? result['order_id']).toString();
                                  isOfflineDraft = result['is_offline_draft'] == true;
                                }
                              } catch (e) {
                                debugPrint('API order placement failed: $e');
                              }

                              if (newOrderId.isEmpty) {
                                nav.pop();
                                messenger.showSnackBar(const SnackBar(content: Text('Could not place order. Please try again.'),
                                  backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                                return;
                              }

                              if (selectedPaymentMethod == 'Online') {
                                if (isOfflineDraft) {
                                  nav.pop();
                                  messenger.showSnackBar(SnackBar(content: const Text('Order saved offline. Payment will be initiated once you are back online.'),
                                    backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                                  return;
                                }
                                final paymentResult = await PaymentService.processOnlinePayment(
                                  orderId: newOrderId, amount: (savedTotal + deliveryFee).toDouble(),
                                  customerName: user?.userMetadata?['full_name'] ?? 'User',
                                  customerEmail: user?.email ?? '',
                                  customerPhone: user?.userMetadata?['phone_number'] ?? '',
                                );
                                nav.pop();
                                if (paymentResult == 'launched') {
                                  messenger.showSnackBar(const SnackBar(content: Text('Redirected to Payment.')));
                                  final result = await PaymentService.waitForPaymentCompletion(newOrderId);
                                  messenger.showSnackBar(SnackBar(content: Text(result == 'success' ? 'Payment Successful!' : 'Payment $result.'),
                                    backgroundColor: result == 'success' ? Colors.green : Colors.orange));
                                } else {
                                  messenger.showSnackBar(SnackBar(content: Text('Payment Error: $paymentResult'), backgroundColor: Colors.red));
                                }
                              } else {
                                nav.pop();
                                cart.clearCart();
                                context.read<OrderProvider>().fetchOrders(user!.id, isLunchMode: true);
                                messenger.showSnackBar(SnackBar(content: const Text('Order placed successfully!'),
                                  backgroundColor: const Color(0xFF8CC63F), behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                              }
                            } catch (e) {
                              nav.pop();
                              messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF15A24), foregroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        )),
                      ]),
                    ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 900;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))]),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          const Text('AniLunch', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
                          const Spacer(),
                          _navButton('Home', 0),
                          const SizedBox(width: 4),
                          _navButton('Cart', 1),
                          const SizedBox(width: 4),
                          _navButton('Play', 2),
                          const SizedBox(width: 4),
                          _navButton('Orders', 3),
                          const SizedBox(width: 4),
                          _navButton('Profile', 4),
                          const SizedBox(width: 24),
                          Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF15A24), width: 2)),
                            child: CircleAvatar(radius: 18, backgroundImage: _profileImageUrl != null
                              ? SmartImage.provider(_profileImageUrl!) : const AssetImage('assets/images/hero.png'))),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : AppBar(
              title: const Text('AniLunch', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF15A24))),
              backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2C1A0E), size: 22), onPressed: () {}),
                const SizedBox(width: 4),
              ],
            ),
      body: _buildCurrentPage(context, menu, cart),
      extendBody: true,
      extendBodyBehindAppBar: false,
      bottomNavigationBar: isDesktop ? null : BottomNavBar(currentIndex: _selectedIndex, onTap: (index) => setState(() => _selectedIndex = index)),
    );
  }

  Widget _navButton(String label, int index) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFF15A24).withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isActive ? const Color(0xFFF15A24) : const Color(0xFF7A6A62),
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
      ),
    );
  }

  Widget _buildCurrentPage(BuildContext context, MenuProvider menu, CartProvider cart) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeContent(context, menu, cart),
        const CartPage(),
        const OrdersPage(),
        const ProfilePage(),
      ],
    );
  }

  Widget _buildHomeContent(BuildContext context, MenuProvider menu, CartProvider cart) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    
    if (menu.isLoading && menu.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF15A24)));
    }

    if (menu.error != null && menu.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load menu. Please check your connection.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => menu.fetchInitialData(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF15A24), foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final total = cart.calculateTotal(menu.itemsByCategory);
    final hasItems = total > 0;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: hasItems ? 180 : 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroSection(),
              if (menu.dailyDeals.isNotEmpty) DailyDeals(deals: menu.dailyDeals),

              PopularCategories(
                categories: menu.categories,
                selectedId: menu.selectedCategoryId,
                onSelected: (id) => menu.setSelectedCategory(id),
              ),
              if (menu.selectedCategoryId == 'meal')
                const LunchSection()
              else if (menu.selectedCategoryId != null)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (menu.selectedCategoryId == 'all')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildMeatSubcategoryRow(menu),
                    ),
                  CategoryOptionsSection(
                    key: ValueKey('cat_${menu.selectedCategoryId}_${menu.selectedMeatSubcategory}'),
                    categoryId: menu.selectedCategoryId == 'all' ? menu.selectedMeatSubcategory : menu.selectedCategoryId!,
                    allCategoryData: menu.itemsByCategory,
                    categoryCarts: cart.meatCart,
                    onToggleItem: (itemId, catId) => cart.toggleItem(itemId, catId),
                  ),
                ]),
              const Footer(),
            ],
          ),
        ),
        if (hasItems)
          Positioned(
            left: 0, right: 0, bottom: isDesktop ? 0 : 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))]),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showOrderSheet,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF15A24), foregroundColor: Colors.white,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.shopping_bag_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text('Confirm Order  \u2022  ₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeatSubcategoryRow(MenuProvider menu) {
    final subcats = [
      {'id': 'all', 'menu_title': 'All'},
      ...menu.categories,
    ];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subcats.length,
        itemBuilder: (context, index) {
          final cat = subcats[index];
          final isSelected = menu.selectedMeatSubcategory == cat['id'];
          return GestureDetector(
            onTap: () => menu.setSelectedMeatSubcategory(cat['id'].toString()),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF15A24) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isSelected ? const Color(0xFFF15A24) : Colors.grey.shade300),
              ),
              child: Text(
                cat['menu_title']?.toString() ?? '',
                style: TextStyle(color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}
