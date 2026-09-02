import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../vendor_theme.dart';
import '../../services/supabase_service.dart';

class DashboardTab extends StatefulWidget {
  final String vendorId;
  const DashboardTab({super.key, required this.vendorId});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'preparing', 'ready_for_pickup'
  double _todaySales = 0.0;
  int _todayOrders = 0;
  bool _isStoreOpen = true;
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 20), (_) => _loadStats());
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.getDashboardStats(widget.vendorId);
      if (mounted) {
        setState(() {
          _todaySales = stats['todaySales'] ?? 0.0;
          _todayOrders = stats['todayOrders'] ?? 0;
        });
      }
    } catch (_) {}
  }

  String _formatDateTime(String? raw) {
    if (raw == null) return 'Just now';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return 'Just now';
    final localDt = dt.isUtc ? dt.toLocal() : dt;
    final now = DateTime.now();
    final diff = now.difference(localDt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    
    final hour12 = localDt.hour == 0 ? 12 : (localDt.hour > 12 ? localDt.hour - 12 : localDt.hour);
    final amPm = localDt.hour >= 12 ? 'PM' : 'AM';
    final min = localDt.minute.toString().padLeft(2, '0');
    return '$hour12:$min $amPm';
  }

  Future<void> _handleOrderAction(Map<String, dynamic> order, String nextStatus) async {
    final orderId = order['id']?.toString() ?? '';
    if (orderId.isEmpty) return;

    if (nextStatus == 'ready_for_pickup') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Food Ready?',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
          content: Text(
            'Confirming will notify all nearby available riders to come pick up this order. Make sure food is packed securely.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Not Yet', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Yes, Call Riders!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await SupabaseService.updateOrderStatus(orderId, nextStatus);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(nextStatus == 'ready_for_pickup' ? Icons.delivery_dining : Icons.soup_kitchen_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nextStatus == 'ready_for_pickup'
                      ? '✅ Food marked ready! Available riders notified.'
                      : '👨‍🍳 Order accepted! Kitchen started preparing.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: nextStatus == 'ready_for_pickup' ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isStoreOpen ? const Color(0xFF16A34A) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AniLunch Kitchen',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _isStoreOpen ? 'Online • Accepting Orders' : 'Offline • Not Accepting',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isStoreOpen ? const Color(0xFF16A34A) : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                setState(() => _isStoreOpen = !_isStoreOpen);
                SupabaseService.toggleStoreStatus(widget.vendorId, _isStoreOpen);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isStoreOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isStoreOpen ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isStoreOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                      size: 15,
                      color: _isStoreOpen ? const Color(0xFF166534) : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isStoreOpen ? 'Open' : 'Closed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isStoreOpen ? const Color(0xFF166534) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.activeOrdersStream(widget.vendorId),
        builder: (context, snapshot) {
          final allActiveOrders = snapshot.data ?? [];
          final activeOrders = allActiveOrders.where((o) =>
              o['status'] != 'delivered' &&
              o['status'] != 'completed' &&
              o['status'] != 'cancelled').toList();
          final deliveredOrders = allActiveOrders.where((o) =>
              o['status'] == 'delivered' ||
              o['status'] == 'completed').toList();

          List<Map<String, dynamic>> displayedOrders;
          if (_selectedStatusFilter == 'delivered') {
            displayedOrders = deliveredOrders;
          } else {
            displayedOrders = activeOrders;
          }

          return RefreshIndicator(
            onRefresh: _loadStats,
            color: VendorTheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top Metrics Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: "TODAY'S SALES",
                            value: '₹${_todaySales.toStringAsFixed(0)}',
                            icon: Icons.payments_rounded,
                            iconColor: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFF0FDF4),
                            borderColor: const Color(0xFFBBF7D0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'ACTIVE ORDERS',
                            value: '${activeOrders.length}',
                            subtitle: '${activeOrders.where((o) => o['status'] == 'pending' || o['status'] == 'confirmed').length} New • $_todayOrders Today',
                            icon: Icons.soup_kitchen_rounded,
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            borderColor: const Color(0xFFBFDBFE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2-Tab Bar: All Active | Delivered History
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterTabButton('all', 'All Active', activeOrders.length, const Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFilterTabButton('delivered', 'Delivered History', deliveredOrders.length, const Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Order Cards List
                if (displayedOrders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyOrdersState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = displayedOrders[index];
                          return _buildKitchenOrderCard(order);
                        },
                        childCount: displayedOrders.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF64748B), letterSpacing: 0.5),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -0.5),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTabButton(String key, String label, int count, Color activeColor) {
    final isSelected = _selectedStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = key),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenOrderCard(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final customer = (order['ordered_by'] ?? 'Valued Customer').toString().split('@').first;
    final address = order['address']?.toString() ?? 'Shillong Delivery';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final formattedTime = _formatDateTime(order['order_time']?.toString());

    double itemsSubtotal = 0.0;
    for (var item in items) {
      final qty = (item['qty'] ?? item['quantity'] ?? 1) as num;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      itemsSubtotal += price * qty;
    }

    Color statusColor;
    String statusLabel;
    String? buttonText;
    String? nextStatus;
    Color buttonColor;
    IconData buttonIcon;

    switch (status) {
      case 'pending':
      case 'confirmed':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'NEW ORDER';
        buttonText = 'Accept & Cook';
        nextStatus = 'preparing';
        buttonColor = const Color(0xFF16A34A);
        buttonIcon = Icons.soup_kitchen_rounded;
        break;
      case 'preparing':
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'COOKING';
        buttonText = 'Food Ready • Assign Rider';
        nextStatus = 'ready_for_pickup';
        buttonColor = const Color(0xFF2563EB);
        buttonIcon = Icons.delivery_dining_rounded;
        break;
      case 'ready_for_pickup':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'FINDING RIDER';
        buttonText = 'Awaiting Rider Pickup...';
        nextStatus = null;
        buttonColor = const Color(0xFFD97706);
        buttonIcon = Icons.two_wheeler_rounded;
        break;
      case 'accepted':
      case 'assigned':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'RIDER ASSIGNED';
        buttonText = 'Rider Heading to Kitchen';
        nextStatus = null;
        buttonColor = const Color(0xFF7C3AED);
        buttonIcon = Icons.two_wheeler_rounded;
        break;
      case 'picked_up':
      case 'out_for_delivery':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'OUT FOR DELIVERY';
        buttonText = 'Rider Delivering Food';
        nextStatus = null;
        buttonColor = const Color(0xFF7C3AED);
        buttonIcon = Icons.delivery_dining_rounded;
        break;
      case 'delivered':
      case 'completed':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'DELIVERED';
        buttonText = 'Delivered Successfully';
        nextStatus = null;
        buttonColor = const Color(0xFF16A34A);
        buttonIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
        buttonText = status.toUpperCase();
        nextStatus = null;
        buttonColor = Colors.grey;
        buttonIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'pending'
              ? const Color(0xFFFDE68A)
              : (status == 'preparing' ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
          width: status == 'pending' || status == 'preparing' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showOrderDetailsSheet(order),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Order ID, Time, Status Pill & Tap Hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$shortId',
                          style: GoogleFonts.robotoMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• $formattedTime',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // Customer Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$customer • $address',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Ordered Items
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEDF2F7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isEmpty)
                        Row(
                          children: [
                            _buildDishThumbnail('Indian Thali', null, size: 30),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('1x Signature Lunch Box',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                            ),
                          ],
                        )
                      else
                        ...items.map((item) {
                          final qty = item['qty'] ?? item['quantity'] ?? 1;
                          final name = item['name'] ?? item['title'] ?? 'Lunch Item';
                          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                          final imageUrl = item['image']?.toString() ?? item['image_url']?.toString();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.5),
                            child: Row(
                              children: [
                                _buildDishThumbnail(name.toString(), imageUrl, size: 32),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF15A24).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${qty}x',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF15A24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (price > 0)
                                  Text(
                                    '₹${(price * qty).toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Footer: Food Total & Action Button or Status Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Food Total', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
                        Text(
                          '₹${(itemsSubtotal > 0 ? itemsSubtotal : total).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    if (nextStatus != null)
                      ElevatedButton.icon(
                        onPressed: () => _handleOrderAction(order, nextStatus!),
                        icon: Icon(buttonIcon, size: 15),
                        label: Text(
                          buttonText,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: buttonColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: buttonColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(buttonIcon, size: 14, color: buttonColor),
                            const SizedBox(width: 5),
                            Text(
                              buttonText,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: buttonColor,
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
        ),
      ),
    );
  }

  void _showOrderDetailsSheet(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
    final status = (order['status'] ?? 'pending').toString().toLowerCase();
    final customer = (order['ordered_by'] ?? 'Valued Customer').toString().split('@').first;
    final address = order['address']?.toString() ?? 'Shillong Delivery';
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final total = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final formattedTime = _formatDateTime(order['order_time']?.toString());

    double itemsSubtotal = 0.0;
    for (var item in items) {
      final qty = (item['qty'] ?? item['quantity'] ?? 1) as num;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      itemsSubtotal += price * qty;
    }

    Color statusColor;
    String statusLabel;
    String? nextStatus;
    String? actionButtonText;
    Color buttonColor;

    switch (status) {
      case 'pending':
      case 'confirmed':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'NEW ORDER';
        actionButtonText = 'Accept & Cook';
        nextStatus = 'preparing';
        buttonColor = const Color(0xFF16A34A);
        break;
      case 'preparing':
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'COOKING';
        actionButtonText = 'Food Ready • Assign Rider';
        nextStatus = 'ready_for_pickup';
        buttonColor = const Color(0xFF2563EB);
        break;
      case 'ready_for_pickup':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'FINDING RIDER';
        actionButtonText = null;
        nextStatus = null;
        buttonColor = const Color(0xFFD97706);
        break;
      case 'accepted':
      case 'assigned':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'RIDER ASSIGNED';
        actionButtonText = null;
        nextStatus = null;
        buttonColor = const Color(0xFF7C3AED);
        break;
      case 'picked_up':
      case 'out_for_delivery':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'OUT FOR DELIVERY';
        actionButtonText = null;
        nextStatus = null;
        buttonColor = const Color(0xFF7C3AED);
        break;
      case 'delivered':
      case 'completed':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'DELIVERED';
        actionButtonText = null;
        nextStatus = null;
        buttonColor = const Color(0xFF16A34A);
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
        actionButtonText = null;
        nextStatus = null;
        buttonColor = Colors.grey;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sheet Header: Order ID & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$shortId',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Placed: $formattedTime',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Customer Delivery Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, size: 20, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              address,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Section: Dish Customization & Portion Specifications
                Text(
                  '🍳 Food Preparation & Specifications',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                if (items.isEmpty)
                  _buildDetailedFoodSpecCard(
                    name: 'Khasi Thali',
                    qty: 1,
                    price: 200,
                    imageUrl: null,
                    customizations: {'Meat': 'Khasi Beef Curry (3 pcs)', 'Rice': 'Steamed Rice (1 portion)', 'Sides': 'Dal, Dohkhleh & Salad'},
                  )
                else
                  ...items.map((item) {
                    final qty = (item['qty'] ?? item['quantity'] ?? 1) as num;
                    final name = item['name'] ?? item['title'] ?? 'Lunch Item';
                    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                    final imageUrl = item['image']?.toString() ?? item['image_url']?.toString();
                    final rawCustom = item['customizations'];
                    Map<String, String> customMap = {};
                    if (rawCustom is Map) {
                      customMap = rawCustom.map((k, v) => MapEntry(k.toString(), v.toString()));
                    }
                    if (customMap.isEmpty) {
                      final lower = name.toString().toLowerCase();
                      if (lower.contains('khasi')) {
                        customMap = {
                          'Meat': 'Khasi Beef Curry (3 pcs)',
                          'Rice': 'Steamed White Rice (1 portion)',
                          'Sides': 'Tungrymbai, Salad & Spicy Chutney',
                        };
                      } else if (lower.contains('mizo')) {
                        customMap = {
                          'Meat': 'Smoked Pork with Bamboo Shoot (3 pcs)',
                          'Rice': 'Sticky Rice (1 portion)',
                          'Sides': 'Bai (Herbal Stew) & Mizo Chutney',
                        };
                      } else if (lower.contains('naga')) {
                        customMap = {
                          'Meat': 'Naga Style Chicken with King Chili (3 pcs)',
                          'Rice': 'Steamed Rice (1 portion)',
                          'Sides': 'Boiled Vegetables & Axone Chutney',
                        };
                      } else {
                        customMap = {
                          'Meat': 'Signature Curry (3 pcs)',
                          'Rice': 'Steamed Rice (1 portion)',
                          'Sides': 'Dal, Fresh Salad & Pickle',
                        };
                      }
                    }
                    return _buildDetailedFoodSpecCard(
                      name: name.toString(),
                      qty: qty.toInt(),
                      price: price,
                      imageUrl: imageUrl,
                      customizations: customMap,
                    );
                  }),

                const SizedBox(height: 16),

                // Bill Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDF2F7)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Food Subtotal', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          Text('₹${(itemsSubtotal > 0 ? itemsSubtotal : (total > 0 ? total : 200.0)).toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Food Amount', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                          Text('₹${(itemsSubtotal > 0 ? itemsSubtotal : (total > 0 ? total : 200.0)).toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action button inside modal
                if (actionButtonText != null && nextStatus != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetCtx);
                        _handleOrderAction(order, nextStatus!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        actionButtonText,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(bottomSheetCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text('Close Details', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedFoodSpecCard({
    required String name,
    required int qty,
    required double price,
    required String? imageUrl,
    required Map<String, String> customizations,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dish Title Header
          Row(
            children: [
              _buildDishThumbnail(name, imageUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF15A24).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${qty}x',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF15A24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (price > 0)
                      Text(
                        '₹${(price * qty).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Portion & Ingredient Specifications Grid
          Text(
            'PACKING & PORTIONS SPECIFICATIONS:',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          ...customizations.entries.map((entry) {
            IconData specIcon = Icons.fastfood_rounded;
            Color specColor = const Color(0xFFD97706);
            final k = entry.key.toLowerCase();
            if (k.contains('meat') || k.contains('beef') || k.contains('chicken') || k.contains('pork')) {
              specIcon = Icons.lunch_dining_rounded;
              specColor = const Color(0xFFDC2626);
            } else if (k.contains('rice')) {
              specIcon = Icons.rice_bowl_rounded;
              specColor = const Color(0xFF2563EB);
            } else if (k.contains('side') || k.contains('salad') || k.contains('chutney')) {
              specIcon = Icons.eco_rounded;
              specColor = const Color(0xFF16A34A);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEDF2F7)),
                ),
                child: Row(
                  children: [
                    Icon(specIcon, size: 15, color: specColor),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.soup_kitchen_outlined, size: 36, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders in this Status',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Incoming customer orders will appear here automatically in real time.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishThumbnail(String name, String? imageUrl, {double size = 36, int? price}) {
    final lower = name.toLowerCase();
    String assetPath = 'assets/images/bento.png';
    if (lower.contains('mizo')) {
      assetPath = 'assets/images/pork.png';
    } else if (lower.contains('naga')) {
      assetPath = 'assets/images/chicken.png';
    } else if (lower.contains('khasi')) {
      assetPath = 'assets/images/beef.png';
    } else if (lower.contains('indian') || lower.contains('thali')) {
      assetPath = 'assets/images/bento.png';
    } else if (lower.contains('salad') || lower.contains('veg')) {
      assetPath = 'assets/images/salad.png';
    } else if (lower.contains('chicken') || lower.contains('biryani')) {
      assetPath = 'assets/images/chicken.png';
    } else if (lower.contains('pork') || lower.contains('mutton')) {
      assetPath = 'assets/images/pork.png';
    } else if (lower.contains('beef') || lower.contains('meat')) {
      assetPath = 'assets/images/beef.png';
    }

    if (imageUrl != null && imageUrl.startsWith('assets/')) {
      assetPath = imageUrl;
    }

    Widget imgWidget;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      imgWidget = Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(assetPath, width: size, height: size, fit: BoxFit.cover),
      );
    } else {
      imgWidget = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant, size: 18, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showDishImagePreview(name, imageUrl, price: price),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgWidget,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF15A24),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _showDishImagePreview(String name, String? imageUrl, {int? price}) {
    final lower = name.toLowerCase();
    String assetPath = 'assets/images/bento.png';
    if (lower.contains('mizo')) {
      assetPath = 'assets/images/pork.png';
    } else if (lower.contains('naga')) {
      assetPath = 'assets/images/chicken.png';
    } else if (lower.contains('khasi')) {
      assetPath = 'assets/images/beef.png';
    } else if (lower.contains('indian') || lower.contains('thali')) {
      assetPath = 'assets/images/bento.png';
    } else if (lower.contains('salad') || lower.contains('veg')) {
      assetPath = 'assets/images/salad.png';
    } else if (lower.contains('chicken') || lower.contains('biryani')) {
      assetPath = 'assets/images/chicken.png';
    } else if (lower.contains('pork') || lower.contains('mutton')) {
      assetPath = 'assets/images/pork.png';
    } else if (lower.contains('beef') || lower.contains('meat')) {
      assetPath = 'assets/images/beef.png';
    }

    if (imageUrl != null && imageUrl.startsWith('assets/')) {
      assetPath = imageUrl;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu, color: Color(0xFFF15A24), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 340, maxWidth: 360),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.5,
                    child: (imageUrl != null && imageUrl.startsWith('http'))
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Image.asset(assetPath, fit: BoxFit.contain),
                          )
                        : Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (price != null) ...[
                      Text(
                        '₹$price',
                        style: GoogleFonts.outfit(color: const Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.zoom_in_rounded, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Text('Pinch to zoom • Tap to preview', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
