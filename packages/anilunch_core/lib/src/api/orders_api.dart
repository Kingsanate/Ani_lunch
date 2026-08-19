import '../models/order.dart';
import 'api_client.dart';

/// Order lifecycle: create (idempotent, server-priced), fetch, cancel,
/// transition. All mutations are validated against the server state machine.
class OrdersApi {
  final ApiClient _client;

  OrdersApi(this._client);

  Future<Order> create(CreateOrderRequest request) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/orders/',
      body: request.toJson(),
    );
    return Order.fromJson(data);
  }

  Future<List<Order>> list({
    String? orderType,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/orders/',
      query: {
        if (orderType != null) 'order_type': orderType,
        'limit': limit,
        'offset': offset,
      },
    );
    return data
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> get(String orderId) async {
    final data = await _client
        .get<Map<String, dynamic>>('/api/v1/orders/$orderId');
    return Order.fromJson(data);
  }

  Future<Order> transition(String orderId, String status) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/transition',
      body: {'status': status},
    );
    return Order.fromJson(data);
  }

  Future<String> cancel(String orderId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/cancel',
    );
    return (data['order_id'] as String?) ?? orderId;
  }
}
