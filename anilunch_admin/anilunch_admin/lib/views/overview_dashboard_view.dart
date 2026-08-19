import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_theme.dart';
import '../core/cache/admin_cache.dart';
import '../core/providers/api_provider.dart';
import '../services/api_client.dart';

class OverviewDashboardView extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const OverviewDashboardView({super.key, this.onSwitchTab});

  @override
  State<OverviewDashboardView> createState() => _OverviewDashboardViewState();
}

class _OverviewDashboardViewState extends State<OverviewDashboardView> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<WsEvent>? _orderChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToData();
  }

  void _fetchOrders() async {
    try {
      final data = await AdminCache.instance.fetchCacheFirst(
        entityType: 'orders',
        fetcher: () async => ApiClient.fetchOrders(),
      );
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data);
          _orders.sort((a, b) {
            final tA = DateTime.tryParse(a['order_time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB = DateTime.tryParse(b['order_time']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });
          _applySearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) {
      _filteredOrders = List.from(_orders);
    } else {
      _filteredOrders = _orders.where((o) {
        final customer = (o['ordered_by'] ?? o['user_name'] ?? '').toString().toLowerCase();
        final id = o['id'].toString().toLowerCase();
        return customer.contains(q) || id.contains(q);
      }).toList();
    }
  }

  void _subscribeToData() {
    _fetchOrders();
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;
    realtime.join('admin');
    _orderChannel = realtime.events.listen((event) {
      if (event.orderEvent != null) _fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _orderChannel?.cancel();
    super.dispose();
  }

  double get _totalRevenue {
    return _orders.fold(0.0, (sum, item) {
      final subtotal = (num.tryParse(item['subtotal']?.toString() ?? '0') ?? 0).toDouble();
      final deliveryFee = (num.tryParse(item['delivery_fee']?.toString() ?? '0') ?? 0).toDouble();
      final totalAmount = (num.tryParse(item['total_amount']?.toString() ?? '0') ?? 0).toDouble();
      return sum + (subtotal + deliveryFee > 0 ? subtotal + deliveryFee : totalAmount);
    });
  }

  int get _todayOrdersCount {
    final now = DateTime.now();
    return _orders.where((o) {
      final t = DateTime.tryParse(o['order_time']?.toString() ?? '');
      if (t == null) return false;
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AdminTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AdminTheme.primary, strokeWidth: 2)),
      );
    }

    final pendingCount   = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final deliveredCount = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'delivered').length;
    final acceptedCount  = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'accepted').length;
    final preparingCount = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'preparing').length;
    final readyCount     = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'ready_for_pickup').length;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' : now.hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: AdminTheme.bg,
      body: Column(
        children: [
          _buildHeader(context, greeting),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatGrid(pendingCount, deliveredCount, acceptedCount, preparingCount, readyCount),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Orders', style: AdminTheme.sectionTitle),
                      Text('${_orders.length} total', style: AdminTheme.body),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 10),
                  _buildRecentOrdersList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String greeting) {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]}';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 10,
        left: 4,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: AdminTheme.surface,
        border: Border(bottom: BorderSide(color: AdminTheme.border, width: 0.8)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AdminTheme.dark, size: 20),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted, fontWeight: FontWeight.w500)),
                const Text('Dashboard', style: AdminTheme.pageTitle),
              ],
            ),
          ),
          Text(dateStr, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AdminTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: AdminTheme.primary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(int pendingCount, int deliveredCount, int acceptedCount, int preparingCount, int readyCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Total Orders', _orders.length.toString(), Icons.shopping_bag_outlined, const Color(0xFF6366F1), 'All time')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Revenue', '₹${_totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, AdminTheme.primary, 'Total', highlight: true)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard("Today's", _todayOrdersCount.toString(), Icons.today_outlined, const Color(0xFF0EA5E9), 'Orders today')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Delivered', deliveredCount.toString(), Icons.check_circle_outline_rounded, AdminTheme.success, 'Completed')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Pending', pendingCount.toString(), Icons.hourglass_top_rounded, AdminTheme.warning, 'Awaiting')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Preparing', preparingCount.toString(), Icons.restaurant_rounded, const Color(0xFF2563EB), 'In kitchen')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Ready', readyCount.toString(), Icons.check_box_outlined, const Color(0xFF16A34A), 'Awaiting rider')),
            const SizedBox(width: 10),
            Expanded(child: _statCard('On the Way', acceptedCount.toString(), Icons.delivery_dining_rounded, const Color(0xFF7C3AED), 'Out for delivery')),
          ],
        ),
      ],
    );
  }


  Widget _statCard(String title, String value, IconData icon, Color color, String subtitle, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AdminTheme.dark : AdminTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlight ? Colors.transparent : AdminTheme.border, width: 0.8),
        boxShadow: [BoxShadow(color: color.withValues(alpha: highlight ? 0.2 : 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: highlight ? Colors.white.withValues(alpha: 0.12) : color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: highlight ? Colors.white : color, size: 14),
              ),
              Text(subtitle, style: TextStyle(fontSize: 9, color: highlight ? Colors.white38 : AdminTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: highlight ? Colors.white : AdminTheme.dark, height: 1)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: highlight ? Colors.white60 : AdminTheme.textBody)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AdminTheme.sectionTitle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _quickAction(Icons.add_circle_outline_rounded, 'Add Item', const Color(0xFF6366F1), () => widget.onSwitchTab?.call(1))),
            const SizedBox(width: 8),
            Expanded(child: _quickAction(Icons.receipt_long_rounded, 'Orders', AdminTheme.primary, () => widget.onSwitchTab?.call(2))),
            const SizedBox(width: 8),
            Expanded(child: _quickAction(Icons.delivery_dining_rounded, 'Riders', AdminTheme.success, () => widget.onSwitchTab?.call(5))),
            const SizedBox(width: 8),
            Expanded(child: _quickAction(Icons.local_offer_rounded, 'Deals', const Color(0xFF0EA5E9), () => widget.onSwitchTab?.call(3))),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: AdminTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AdminTheme.border, width: 0.8)),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _applySearch()),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search orders…',
          hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded, color: AdminTheme.textMuted, size: 16),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 14, color: AdminTheme.textMuted), onPressed: () => setState(() { _searchController.clear(); _applySearch(); }))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList() {
    final recentOrders = _filteredOrders.take(5).toList();
    return Container(
      decoration: AdminTheme.cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: const [
                Expanded(child: Text('CUSTOMER', style: AdminTheme.label)),
                Expanded(child: Text('ITEMS', style: AdminTheme.label)),
                Text('STATUS', style: AdminTheme.label),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminTheme.border),
          if (recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No orders found', style: AdminTheme.body),
            )
          else
            ...recentOrders.map((order) {
              final status = (order['status'] ?? 'pending').toString().toLowerCase();
              final color = AdminTheme.statusColor(status);
              String name = order['ordered_by'] ?? order['user_name'] ?? 'Anonymous';
              if (name.contains('@')) name = name.split('@').first;
              String meal = 'Order';
              final rawItems = order['items'];
              if (rawItems is List && rawItems.isNotEmpty) {
                final itemName = rawItems.first['name'] ?? rawItems.first['item_title'] ?? '';
                meal = rawItems.length > 1 ? '$itemName +${rawItems.length - 1}' : itemName.toString();
              } else if (order['meal_name'] != null) {
                meal = order['meal_name'];
              }
              return _orderRow(name, meal, status, color);
            }),
        ],
      ),
    );
  }

  Widget _orderRow(String name, String meal, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  radius: 12,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: AdminTheme.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(child: Text(meal, style: AdminTheme.body, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: AdminTheme.statusBg(status), borderRadius: BorderRadius.circular(5)),
            child: Text(status.toUpperCase(), style: AdminTheme.micro.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
