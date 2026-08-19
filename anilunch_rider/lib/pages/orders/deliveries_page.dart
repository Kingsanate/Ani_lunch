import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../core/cache/order_cache.dart';
import 'active_order_page.dart';

class DeliveriesPage extends StatefulWidget {
  const DeliveriesPage({super.key});
  @override
  State<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<OrderModel> _allOrders = [];
  bool _loading = true;
  RealtimeChannel? _myOrdersChannel;
  StreamSubscription<List<OrderModel>>? _cacheSub;

  String get _riderId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Cache-first: render whatever is in the local cache instantly, then
    // refresh from the network in the background.
    _cacheSub = OrderCache.instance.watchMyOrders(_riderId).listen(_onCacheUpdate);
    _load();
    _listenToMyOrders();
  }

  void _onCacheUpdate(List<OrderModel> orders) {
    if (!mounted) return;
    setState(() {
      _allOrders = orders;
      if (orders.isNotEmpty) _loading = false;
    });
  }

  void _listenToMyOrders() {
    if (_riderId.isEmpty) return;
    _myOrdersChannel = Supabase.instance.client
        .channel('my_deliveries_$_riderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'rider_id',
            value: _riderId,
          ),
          callback: (payload) {
            _load(); // Reload orders when there's any change
          },
        )
        .subscribe();
  }

Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await OrderService.fetchMyOrders(_riderId);
    await OrderCache.instance.cacheOrders(orders);
    if (mounted) setState(() { _allOrders = orders; _loading = false; });
  }

  List<OrderModel> get _active => _allOrders.where((o) => ['accepted', 'picked_up'].contains(o.status)).toList();
  List<OrderModel> get _history => _allOrders.where((o) => o.status == 'delivered').toList();

  // ── Stats helpers ──────────────────────────────────────────────────────────
  List<OrderModel> _filterByPeriod(List<OrderModel> orders, String period) {
    final now = DateTime.now();
    return orders.where((o) {
      if (o.createdAt == null) return false;
      final d = o.createdAt!;
      switch (period) {
        case 'today': return d.year == now.year && d.month == now.month && d.day == now.day;
        case 'week': return now.difference(d).inDays < 7;
        case 'month': return d.year == now.year && d.month == now.month;
        default: return true;
      }
    }).toList();
  }

@override
  void dispose() { 
    _tabCtrl.dispose(); 
    _cacheSub?.cancel();
    _myOrdersChannel?.unsubscribe();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loading) _buildQuickStats(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9100)))
                  : RefreshIndicator(
                      color: const Color(0xFFFF9100),
                      backgroundColor: const Color(0xFF1A1A1A),
                      onRefresh: _load,
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildList(_active, isActive: true),
                          _buildHistoryTab(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MY DELIVERIES', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text('Activity Tracker', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
              child: const Icon(LucideIcons.refreshCw, color: Colors.white54, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final todayDeliveries = _filterByPeriod(_history, 'today');
    final weekDeliveries = _filterByPeriod(_history, 'week');
    final monthDeliveries = _filterByPeriod(_history, 'month');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _miniStatCard('TODAY', '${todayDeliveries.length}', LucideIcons.sun, const Color(0xFFFF9100)),
          const SizedBox(width: 10),
          _miniStatCard('THIS WEEK', '${weekDeliveries.length}', LucideIcons.calendarDays, const Color(0xFF2196F3)),
          const SizedBox(width: 10),
          _miniStatCard('THIS MONTH', '${monthDeliveries.length}', LucideIcons.calendarRange, const Color(0xFF9C27B0)),
          const SizedBox(width: 10),
          _miniStatCard('ACTIVE', '${_active.length}', LucideIcons.bike, const Color(0xFF00C853)),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: GoogleFonts.inter(color: color.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6000)]), borderRadius: BorderRadius.circular(12)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'ACTIVE  ${_active.isNotEmpty ? "(${_active.length})" : ""}'),
          Tab(text: 'HISTORY  ${_history.isNotEmpty ? "(${_history.length})" : ""}'),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) return _buildEmptyState(false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildPeriodSection('Today', _filterByPeriod(_history, 'today')),
        _buildPeriodSection('This Week', _filterByPeriod(_history, 'week').where((o) => !_filterByPeriod(_history, 'today').contains(o)).toList()),
        _buildPeriodSection('This Month', _filterByPeriod(_history, 'month').where((o) => !_filterByPeriod(_history, 'week').contains(o)).toList()),
        _buildPeriodSection('Older', _history.where((o) => !_filterByPeriod(_history, 'month').contains(o)).toList()),
      ],
    );
  }

  Widget _buildPeriodSection(String title, List<OrderModel> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();
    final sectionEarnings = orders.fold(0.0, (sum, o) => sum + (o.totalAmount ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                child: Text('${orders.length}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('₹${sectionEarnings.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        ...orders.map((o) => _buildCard(o, isActive: false)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildList(List<OrderModel> orders, {required bool isActive}) {
    if (orders.isEmpty) return _buildEmptyState(isActive);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildCard(orders[i], isActive: isActive),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
            child: Icon(isActive ? LucideIcons.bike : LucideIcons.clipboardList, color: Colors.white24, size: 32),
          ),
          const SizedBox(height: 20),
          Text(isActive ? 'No Active Deliveries' : 'No Delivery History', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(isActive ? 'Accept an order to see it here' : 'Completed deliveries appear here', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(OrderModel order, {required bool isActive}) {
    final statusColor = isActive ? const Color(0xFF2196F3) : const Color(0xFF4CAF50);
    final statusLabel = isActive ? (order.status == 'picked_up' ? 'DELIVERING' : 'TO PICKUP') : 'DELIVERED';

    String timeLabel = '';
    if (order.createdAt != null) {
      final diff = DateTime.now().difference(order.createdAt!);
      if (diff.inDays == 0) {
        timeLabel = DateFormat('hh:mm a').format(order.createdAt!.toLocal());
      } else if (diff.inDays == 1) {
        timeLabel = 'Yesterday ${DateFormat('hh:mm a').format(order.createdAt!.toLocal())}';
      } else {
        timeLabel = DateFormat('dd MMM, hh:mm a').format(order.createdAt!.toLocal());
      }
    }

    return GestureDetector(
      onTap: isActive ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveOrderPage(order: order))) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? statusColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              if (isActive) Container(height: 2, color: statusColor.withValues(alpha: 0.8)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(isActive ? LucideIcons.bike : LucideIcons.checkCircle2, color: statusColor, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.customerName ?? 'Customer', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                              Text(order.customerAddress ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
                              child: Text(statusLabel, style: GoogleFonts.inter(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ),
                            const SizedBox(height: 4),
                            if (order.totalAmount != null)
                              Text('₹${order.totalAmount!.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(LucideIcons.hash, size: 11, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text(order.shortId, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                        const SizedBox(width: 14),
                        Icon(LucideIcons.shoppingBag, size: 11, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text('${order.items.length} items', style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                        const Spacer(),
                        Icon(LucideIcons.clock, size: 11, color: Colors.white24),
                        const SizedBox(width: 4),
                        Text(timeLabel, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveOrderPage(order: order))),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.8)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.arrowRight, size: 15, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('VIEW & UPDATE STATUS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

