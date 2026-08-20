import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.order,
    required this.items,
    this.onViewDetails,
    this.onCancel,
  });

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return const Color(0xFF8CC63F);
      case 'cancelled': return Colors.red;
      case 'accepted': return const Color(0xFFFF9100);
      case 'picked_up': return const Color(0xFF2196F3);
      case 'out_for_delivery': return const Color(0xFF2196F3);
      default: return const Color(0xFFF15A24);
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'accepted': return Icons.delivery_dining_rounded;
      case 'picked_up': return Icons.local_shipping_rounded;
      case 'out_for_delivery': return Icons.local_shipping_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  static String _statusLabel(String status) {
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

  static String _formatDate(DateTime date) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]}  $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
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
      onTap: onViewDetails,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (() {
              final firstItem = items.isNotEmpty ? items.first : null;
              final imageUrl = firstItem?['image']?.toString();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImage(imageUrl),
                  ),
                );
              } else {
                return Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF15A24).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF15A24), size: 28),
                );
              }
            })(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C1A0E)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(orderDate)}  •  ${items.length} item${items.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  const Text('View Details', style: TextStyle(color: Color(0xFFF15A24), fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '₹${order['total_amount'] ?? order['total'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C1A0E)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: 56,
        height: 56,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(width: 56, height: 56, color: Colors.grey[100]),
        errorWidget: (context, url, error) => Container(width: 56, height: 56, color: Colors.grey[200], child: const Icon(Icons.error_outline, size: 20)),
      );
    }
    return Image.asset(imagePath, width: 56, height: 56, fit: BoxFit.contain);
  }
}
