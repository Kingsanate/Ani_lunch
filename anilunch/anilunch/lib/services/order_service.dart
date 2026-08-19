import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchUserOrders(String userId) async {
    final data = await _client
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('order_time', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    final data =
        await _client.from('orders').insert(orderData).select().single();
    return data;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  RealtimeChannel subscribeToOrderUpdates(
      String userId, void Function() callback) {
    return _client
        .channel('public:user_orders_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => callback(),
        )
        .subscribe();
  }
}
