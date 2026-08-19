import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/smart_image.dart';
import '../views/review_bottom_sheet.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return const Color(0xFF8CC63F);
      case 'cancelled': return Colors.red;
      case 'accepted': return const Color(0xFFFF9100);
      case 'picked_up': return const Color(0xFF2196F3);
      case 'out_for_delivery': return const Color(0xFF2196F3);
      default: return const Color(0xFFF15A24);
    }
  }

  Color get _primaryColor => const Color(0xFFF15A24);
  Color get _textColor => const Color(0xFF2C1A0E);
  Color get _bgColor => const Color(0xFFF9F6F3);

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'accepted': return Icons.delivery_dining_rounded;
      case 'picked_up': return Icons.local_shipping_rounded;
      case 'out_for_delivery': return Icons.local_shipping_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'pending_payment': return 'Awaiting Payment';
      case 'accepted': return 'Rider Assigned';
      case 'picked_up': return 'Out for Delivery';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status.replaceAll('_', ' ');
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    DateTime orderDate;
    try {
      final rawDate = order['order_time'] ?? order['created_at'] ?? order['date'];
      if (rawDate is DateTime) {
        orderDate = rawDate;
      } else if (rawDate is String) {
        orderDate = DateTime.parse(rawDate);
      } else {
        orderDate = DateTime.now();
      }
    } catch (e) {
      orderDate = DateTime.now();
    }

    final status = (order['status'] ?? 'Pending').toString();
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return InkWell(
      onTap: () => _showOrderDetails(context, order, items, orderDate, status, statusColor, statusLabel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (() {
              final firstItem = items.isNotEmpty ? items.first : null;
              final imageUrl = firstItem?['image']?.toString();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return Container(
                  width: 56, height: 56, margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: SmartImage(imageUrl, width: 56, height: 56, fit: BoxFit.contain)),
                );
              } else {
                return Container(
                  width: 56, height: 56, margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.receipt_long_rounded, color: _primaryColor, size: 28),
                );
              }
            })(),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Order #${order['id']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${_formatDate(orderDate)}  \u2022  ${items.length} item${items.length != 1 ? 's' : ''}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 10),
                Text('View Details', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(height: 14),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Total: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('₹${order['total_amount'] ?? order['total'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textColor)),
              ]),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;
    final todayOrders = orderProvider.todayOrders;
    final pastOrders = orderProvider.pastOrders;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textColor)),
                const SizedBox(height: 2),
                Text(orders.isEmpty ? 'No orders yet' : '${orders.length} order${orders.length != 1 ? 's' : ''} placed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ]),
            ),
            Expanded(
              child: orders.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      children: [
                        if (todayOrders.isNotEmpty) ...[
                          Padding(padding: const EdgeInsets.only(bottom: 12, left: 4),
                            child: Text("Today's Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor))),
                          ...todayOrders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildOrderCard(order, context))),
                        ],
                        if (pastOrders.isNotEmpty) ...[
                          if (todayOrders.isNotEmpty) const SizedBox(height: 16),
                          Padding(padding: const EdgeInsets.only(bottom: 12, left: 4),
                            child: Text("Past Orders", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor))),
                          ...pastOrders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildOrderCard(order, context))),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined, size: 48, color: _primaryColor),
          ),
          const SizedBox(height: 24),
          Text('No orders yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor)),
          const SizedBox(height: 8),
          Text('Your confirmed orders will appear here.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]}  $h:$m $ampm';
  }

  void _showReviewDialog(BuildContext ctx, Map<String, dynamic> item) {
    showDialog(context: ctx, builder: (context) => Dialog(
      backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(20),
      child: ReviewBottomSheet(item: item),
    ));
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, List<Map<String, dynamic>> items, DateTime orderDate, String status, Color statusColor, String statusLabel) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Order Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textColor)),
                  Container(decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(Icons.close_rounded, size: 20), color: _textColor,
                      onPressed: () => Navigator.pop(ctx), constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero)),
                ]),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(_formatDate(orderDate), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon(status), color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ])),
                  if (status.toLowerCase() == 'delivered' && items.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showReviewDialog(context, items.first), behavior: HitTestBehavior.opaque,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded, color: _primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text('Write a Review', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 24),
                Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.location_on_outlined, color: _primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order['address']?.toString() ?? 'No address provided', style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4))),
                ]),
                const SizedBox(height: 24),
                Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textColor)),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: items.map((item) {
                        final qty = (item['quantity'] ?? item['qty'] ?? 1) as int;
                        final price = (item['price'] ?? 0) as int;
                        final imageUrl = item['image']?.toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: SmartImage(imageUrl, width: 44, height: 44, fit: BoxFit.contain))
                                : const Icon(Icons.receipt_long_rounded, color: Colors.grey, size: 20)),
                            const SizedBox(width: 14),
                            Padding(padding: const EdgeInsets.only(top: 2), child: Text('\u00d7$qty', style: TextStyle(fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 14))),
                            const SizedBox(width: 14),
                            Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title']?.toString() ?? item['name']?.toString() ?? 'Unknown Item', style: TextStyle(fontWeight: FontWeight.w600, color: _textColor, fontSize: 15)),
                                if (item['customizations'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text('Rice: ${item['customizations']['Rice'] ?? 'None'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('Meat: ${item['customizations']['Meat'] ?? 'None'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ))),
                            Text('₹${price * qty}', style: TextStyle(fontWeight: FontWeight.bold, color: _textColor, fontSize: 15)),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 32, color: Color(0xFFE0E0E0)),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Payment Method', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14)),
                  Row(children: [
                    Icon(order['payment_method'] == 'Online' ? Icons.credit_card_rounded : Icons.money_rounded, size: 16, color: _textColor),
                    const SizedBox(width: 6),
                    Text((order['payment_method']?.toString().toUpperCase() ?? 'COD'), style: TextStyle(fontWeight: FontWeight.bold, color: _textColor, fontSize: 14)),
                  ]),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Delivery Fee', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14)),
                  Text('₹${order['delivery_fee'] ?? 30}', style: TextStyle(fontWeight: FontWeight.bold, color: _textColor, fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textColor)),
                  Text('₹${order['total_amount'] ?? order['total'] ?? 0}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryColor)),
                ]),
                if (status.toLowerCase() != 'delivered' && status.toLowerCase() != 'cancelled') ...[
                  const SizedBox(height: 28),
                  SizedBox(width: double.infinity, child: OutlinedButton(
                    onPressed: () => _cancelOrder(context, order['id'].toString(), ctx, order),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder(BuildContext context, String orderId, BuildContext dialogContext, Map<String, dynamic> orderRef) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Order'), content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirm == true) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (!context.mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (c) => Center(child: CircularProgressIndicator(color: _primaryColor)));
      try {
        await context.read<OrderProvider>().cancelOrder(orderId);
        if (context.mounted) {
          Navigator.pop(context);
          context.read<OrderProvider>().fetchOrders(Supabase.instance.client.auth.currentUser!.id, isLunchMode: true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}
