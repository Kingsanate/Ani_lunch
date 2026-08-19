import 'package:flutter/material.dart';
import '../../vendor_theme.dart';
import '../../services/supabase_service.dart';
import '../../core/cache/vendor_cache.dart';

class DashboardTab extends StatefulWidget {
  final String vendorId;
  const DashboardTab({super.key, required this.vendorId});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoading = true;
  double _todaySales = 0.0;
  int _todayOrders = 0;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Cache-first: render the cached snapshot instantly (no spinner when warm).
    final cachedStats = await VendorCache.instance.getStats(widget.vendorId);
    final cachedProducts = await VendorCache.instance.getProducts();
    if (mounted && (cachedStats != null || cachedProducts.isNotEmpty)) {
      setState(() {
        if (cachedStats != null) {
          _todaySales = cachedStats['todaySales'];
          _todayOrders = cachedStats['todayOrders'];
        }
        _products = cachedProducts;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = true);
    }

    // Background refresh with authoritative data, then re-cache.
    final stats = await SupabaseService.getDashboardStats(widget.vendorId);
    final products = await SupabaseService.getVendorProducts(widget.vendorId);
    await SupabaseService.cacheDashboardStats(
      widget.vendorId,
      todaySales: stats['todaySales'],
      todayOrders: stats['todayOrders'],
    );
    await VendorCache.instance.cacheProducts(products.cast<Map<String, dynamic>>());

    if (mounted) {
      setState(() {
        _todaySales = stats['todaySales'];
        _todayOrders = stats['todayOrders'];
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.restaurant, color: VendorTheme.primary),
        title: Text(
          'Daily Performance Dashboard',
          style: VendorTheme.headingSmall.copyWith(color: VendorTheme.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: VendorTheme.greyBg,
              radius: 18,
              child: const Icon(Icons.person, color: VendorTheme.primary),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: VendorTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: VendorTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Overview',
                      style: VendorTheme.headingMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverviewCard(
                            icon: Icons.payments_outlined,
                            title: 'Today\'s Sales',
                            value: '₹${_todaySales.toStringAsFixed(2)}',
                            color: VendorTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildOverviewCard(
                            icon: Icons.shopping_cart_outlined,
                            title: 'Today\'s Orders',
                            value: '$_todayOrders',
                            color: VendorTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Menu Overview',
                      style: VendorTheme.headingMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: VendorTheme.cardDecoration(),
                      child: _products.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'No menu items found.\n(Backend connection active)',
                                  textAlign: TextAlign.center,
                                  style: VendorTheme.bodyMedium,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _products.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: VendorTheme.greyBg,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return _buildMenuItem(
                                  product['name'] ?? 'Unknown Item',
                                  '₹${(product['price'] ?? 0).toStringAsFixed(2)}',
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: VendorTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: VendorTheme.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: VendorTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            price,
            style: VendorTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
