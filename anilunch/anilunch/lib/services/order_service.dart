import 'dart:async';
import '../core/providers/api_provider.dart';

class OrderService {
  Future<List<Map<String, dynamic>>> fetchUserOrders(String userId) async {
    try {
      final orders = await AniApi.instance.api.orders.list();
      return orders.map((o) => {
        'id': o.id,
        'user_id': o.userId,
        'order_type': o.orderType,
        'status': o.status,
        'subtotal': o.subtotal.paise ~/ 100,
        'total_amount': o.totalAmount.paise ~/ 100,
        'payment_method': o.paymentMethod,
        'created_at': o.createdAt.toIso8601String(),
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await AniApi.instance.api.orders.cancel(orderId);
  }

  StreamSubscription? subscribeToOrderUpdates(
      String userId, void Function() callback) {
    try {
      return AniApi.instance.realtime.events.listen((_) => callback());
    } catch (_) {
      return null;
    }
  }
}
