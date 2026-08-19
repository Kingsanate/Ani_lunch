import 'package:flutter/material.dart';
import '../../vendor_theme.dart';
import '../../services/supabase_service.dart';

class OrdersTab extends StatefulWidget {
  final String vendorId;
  const OrdersTab({super.key, required this.vendorId});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with TickerProviderStateMixin {
  bool _isActiveOrdersSelected = true;
  int? _previousActiveCount;
  late AnimationController _bellController;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour12 =
        dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour12:$minuteStr $amPm';
    if (isToday) return 'Today, $timeStr';
    return '${dt.day}/${dt.month}/${dt.year}, $timeStr';
  }

  // ── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'preparing':
        return const Color(0xFF2563EB);
      case 'ready_for_pickup':
        return const Color(0xFF16A34A);
      case 'assigned':
      case 'accepted':
        return const Color(0xFF7C3AED);
      case 'picked_up':
        return const Color(0xFF0891B2);
      default:
        return Colors.grey;
    }
  }

  Color _statusBg(String status) => _statusColor(status).withValues(alpha: 0.12);

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'preparing':
        return 'PREPARING';
      case 'ready_for_pickup':
        return 'READY FOR RIDER';
      case 'assigned':
        return 'RIDER ASSIGNED';
      case 'accepted':
        return 'RIDER ACCEPTED';
      case 'picked_up':
        return 'PICKED UP';
      default:
        return status.toUpperCase();
    }
  }

  // ── Button logic for active orders ─────────────────────────────────────────
  // pending → [Accept Order]
  // preparing → [🍽 Food Ready] (this is the "Finish" button)
  // ready_for_pickup / accepted / picked_up → no vendor action needed
  String? _getActionText(String status) {
    if (status == 'pending') return 'Accept Order';
    if (status == 'preparing') return '🍽  Food Ready';
    return null;
  }

  String? _getNextStatus(String status) {
    if (status == 'pending') return 'preparing';
    if (status == 'preparing') return 'ready_for_pickup';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: VendorTheme.textDark, size: 20),
          onPressed: () {},
        ),
        title: Text(
          'Orders',
          style:
              VendorTheme.headingSmall.copyWith(color: VendorTheme.primary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Segmented Control ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: VendorTheme.greyBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isActiveOrdersSelected = true),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isActiveOrdersSelected
                              ? VendorTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isActiveOrdersSelected
                              ? VendorTheme.softShadow
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Active Orders',
                          style: VendorTheme.bodyMedium.copyWith(
                            color: _isActiveOrdersSelected
                                ? Colors.white
                                : VendorTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isActiveOrdersSelected = false),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: !_isActiveOrdersSelected
                              ? VendorTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: !_isActiveOrdersSelected
                              ? VendorTheme.softShadow
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'History',
                          style: VendorTheme.bodyMedium.copyWith(
                            color: !_isActiveOrdersSelected
                                ? Colors.white
                                : VendorTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────────────────────
          Expanded(
            child: _isActiveOrdersSelected
                ? _buildActiveOrdersView()
                : _buildHistoryView(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Orders', style: VendorTheme.headingSmall),
                  const SizedBox(height: 4),
                  Text('Real-time incoming orders',
                      style: VendorTheme.bodySmall),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        size: 16, color: Colors.grey.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'FILTER',
                      style: VendorTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── Order status legend ────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _legendChip('PENDING', const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _legendChip('PREPARING', const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _legendChip('READY FOR RIDER', const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _legendChip('OUT FOR DELIVERY', const Color(0xFF7C3AED)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.activeOrdersStream(widget.vendorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: VendorTheme.primary));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: VendorTheme.bodyMedium));
              }

              final orders = snapshot.data ?? [];

              // New order notification
              if (_previousActiveCount != null &&
                  orders.length > _previousActiveCount!) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _bellController.forward(from: 0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.notifications_active,
                                color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('🔔 New order received!',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        backgroundColor: VendorTheme.primary,
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.only(
                            bottom: 20, left: 16, right: 16),
                      ),
                    );
                  }
                });
              }
              _previousActiveCount = orders.length;

              if (orders.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final created =
                      DateTime.tryParse(order['order_time'].toString());
                  String formattedTime = '';
                  if (created != null) {
                    formattedTime = _formatDateTime(created);
                  }

                  final status = order['status']?.toString() ?? 'pending';
                  final actionText = _getActionText(status);
                  final nextStatus = _getNextStatus(status);

                  return _buildOrderCard(
                    order: order,
                    time: formattedTime,
                    actionText: actionText,
                    onAction: actionText != null && nextStatus != null
                        ? () => _handleOrderAction(
                            order, nextStatus, actionText)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legendChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: VendorTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.receipt_long,
                color: VendorTheme.primary, size: 34),
          ),
          const SizedBox(height: 14),
          Text('No Active Orders',
              style: VendorTheme.headingSmall
                  .copyWith(color: VendorTheme.textDark)),
          const SizedBox(height: 6),
          Text('New orders will appear here in real-time',
              style: VendorTheme.bodySmall),
        ],
      ),
    );
  }

  // ── Handle vendor action with confirmation for "Food Ready" ────────────────
  Future<void> _handleOrderAction(
      Map<String, dynamic> order, String nextStatus, String actionText) async {
    if (nextStatus == 'ready_for_pickup') {
      // Show confirmation dialog before broadcasting to riders
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Text('🍽️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text('Food Ready?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Confirming will notify all available riders immediately. Make sure the food is packed and ready for pickup.',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Yet',
                  style: TextStyle(color: Color(0xFF666666))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Yes, Notify Riders!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await SupabaseService.updateOrderStatus(order['id'], nextStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delivery_dining, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ Riders are being notified!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          ),
        );
      }
    } else {
      // Accept order — no confirmation needed
      await SupabaseService.updateOrderStatus(order['id'], nextStatus);
    }
  }

  Widget _buildOrderCard({
    required Map<String, dynamic> order,
    required String time,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final id = '#${order['id'].toString().substring(0, 5).toUpperCase()}';
    final customer =
        order['ordered_by']?.toString().split('@').first ?? 'Customer';
    final itemsRaw = order['items'];
    List<dynamic> itemsList = [];
    if (itemsRaw is List) itemsList = itemsRaw;

    final status = order['status']?.toString() ?? 'pending';
    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);
    final statusLabel = _statusLabel(status);

    // For history cards (no actionText), set status colors from history logic
    Color historyStatusBgColor = VendorTheme.greyBg;
    Color historyStatusTextColor = VendorTheme.textMuted;
    if (actionText == null) {
      switch (status.toUpperCase()) {
        case 'COMPLETED':
        case 'DELIVERED':
          historyStatusBgColor = VendorTheme.success;
          historyStatusTextColor = VendorTheme.successText;
          break;
        case 'CANCELLED':
          historyStatusBgColor = VendorTheme.danger;
          historyStatusTextColor = VendorTheme.dangerText;
          break;
        case 'REFUNDED':
          historyStatusBgColor = VendorTheme.warning;
          historyStatusTextColor = VendorTheme.warningText;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: VendorTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetailsSheet(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$id • $customer',
                        style: VendorTheme.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status chip (always shown for active orders)
                    if (actionText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: historyStatusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: historyStatusTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: VendorTheme.bodySmall
                      .copyWith(color: VendorTheme.textMuted),
                ),
                const SizedBox(height: 12),

                // ── Items list ────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: itemsList.isEmpty
                      ? [
                          Text('No items found',
                              style: VendorTheme.bodyMedium)
                        ]
                      : itemsList.map((item) {
                          final qty =
                              item['qty'] ?? item['quantity'] ?? 1;
                          final name =
                              item['name'] ?? item['title'] ?? 'Item';
                          String customStr = '';
                          if (item['customizations'] != null &&
                              item['customizations'] is Map) {
                            final custom = item['customizations'] as Map;
                            if (custom.isNotEmpty) {
                              customStr = '\n' +
                                  custom.entries
                                      .map((e) =>
                                          '• ${e.key}: ${e.value}')
                                      .join('\n');
                            }
                          }
                          final imageUrl = item['image']?.toString();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: VendorTheme.greyBg,
                                    child: (imageUrl != null &&
                                            imageUrl.isNotEmpty)
                                        ? Image.network(
                                            imageUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(Icons.fastfood,
                                                    color: Colors.grey,
                                                    size: 20),
                                          )
                                        : const Icon(Icons.fastfood,
                                            color: Colors.grey, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${qty}x $name$customStr',
                                    style: VendorTheme.bodyMedium
                                        .copyWith(
                                      height: 1.4,
                                      color: VendorTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 12),

                // ── Footer: total + action button ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                      style: VendorTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: VendorTheme.textDark),
                    ),
                    if (actionText != null && onAction != null)
                      _buildActionButton(actionText, onAction, status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String actionText, VoidCallback onAction, String currentStatus) {
    final isFinishButton = currentStatus == 'preparing';
    final bgColor = isFinishButton
        ? const Color(0xFF16A34A)
        : VendorTheme.primary;
    final icon =
        isFinishButton ? Icons.check_circle_outline : Icons.thumb_up_alt;

    return InkWell(
      onTap: onAction,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              actionText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailsSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final id = '#${order['id'].toString().substring(0, 5).toUpperCase()}';
        final itemsRaw = order['items'];
        List<dynamic> itemsList = [];
        if (itemsRaw is List) itemsList = itemsRaw;

        final status = order['status']?.toString() ?? 'pending';
        final statusColor = _statusColor(status);
        final statusLabel = _statusLabel(status);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Details $id',
                      style: VendorTheme.headingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Items',
                  style: VendorTheme.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...itemsList.map((item) {
                final qty = item['qty'] ?? item['quantity'] ?? 1;
                final name = item['name'] ?? item['title'] ?? 'Item';
                final price = (item['price'] ?? 0).toDouble();
                String customStr = '';
                if (item['customizations'] != null &&
                    item['customizations'] is Map) {
                  final custom = item['customizations'] as Map;
                  if (custom.isNotEmpty) {
                    customStr = '\n' +
                        custom.entries
                            .map((e) => '   - ${e.key}: ${e.value}')
                            .join('\n');
                  }
                }
                final imageUrl = item['image']?.toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 50,
                          height: 50,
                          color: VendorTheme.greyBg,
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error,
                                          stackTrace) =>
                                      const Icon(Icons.fastfood,
                                          color: Colors.grey, size: 24),
                                )
                              : const Icon(Icons.fastfood,
                                  color: Colors.grey, size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '${qty}x $name$customStr',
                          style: VendorTheme.bodyMedium
                              .copyWith(height: 1.4),
                        ),
                      ),
                      Text(
                        '₹${(price * qty).toStringAsFixed(2)}',
                        style: VendorTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: VendorTheme.primary),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount',
                      style: VendorTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '₹${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                    style: VendorTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: VendorTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text('Delivery Address',
                  style: VendorTheme.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                order['address']?.toString() ?? 'No address provided',
                style: VendorTheme.bodyMedium,
              ),
              const SizedBox(height: 30),

              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VendorTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close Details',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0),
            decoration: VendorTheme.cardDecoration(),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: VendorTheme.textMuted),
                const SizedBox(width: 12),
                Text(
                  'Current Month',
                  style: VendorTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down,
                    size: 20, color: VendorTheme.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: SupabaseService.historyOrdersStream(widget.vendorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: VendorTheme.primary));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: VendorTheme.bodyMedium));
              }

              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Center(
                    child: Text('No past orders found.',
                        style: VendorTheme.bodyMedium));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final created =
                      DateTime.tryParse(order['order_time'].toString());
                  String formattedTime = '';
                  if (created != null) {
                    formattedTime = _formatDateTime(created);
                  }
                  return _buildOrderCard(order: order, time: formattedTime);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
