import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/api_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/hero_section.dart';
import '../widgets/daily_deals.dart';
import '../widgets/popular_categories.dart';
import '../widgets/category_options_section.dart';
import '../widgets/footer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/lunch_section.dart';
import '../models/smart_image.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _profileImageUrl;
  Timer? _catalogRefreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initUserAndOrders();
    _catalogRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        context.read<MenuProvider>().fetchInitialData();
      }
    });
  }

  Future<void> _initUserAndOrders() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id ?? AniApi.currentUserId ?? 'usr-1';
    final order = context.read<OrderProvider>();
    order.fetchOrders(userId, isLunchMode: true);
    order.subscribeToUpdates(userId, isLunchMode: true);

    if (auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty) {
      setState(() {
        _profileImageUrl = auth.user!.avatarUrl;
      });
    }
  }

  @override
  void dispose() {
    _catalogRefreshTimer?.cancel();
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
                          _navButton('Orders', 2),
                          const SizedBox(width: 4),
                          _navButton('Profile', 3),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
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
