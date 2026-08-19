import '../models/user.dart';
import '../models/vendor.dart';
import 'api_client.dart';

class VendorsApi {
  final ApiClient _client;

  VendorsApi(this._client);

  Future<Vendor> me() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/vendors/me');
    return Vendor.fromJson(data);
  }

  Future<Vendor> updateProfile({
    String? name,
    String? address,
    String? phone,
    double? locationLat,
    double? locationLng,
    bool? isOpen,
  }) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/vendors/me',
      body: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (locationLat != null) 'location_lat': locationLat,
        if (locationLng != null) 'location_lng': locationLng,
        if (isOpen != null) 'is_open': isOpen,
      },
    );
    return Vendor.fromJson(data);
  }

  Future<List<VendorOrder>> orders() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/vendors/me/orders');
    return data
        .map((e) => VendorOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VendorStats> stats() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/vendors/me/stats');
    return VendorStats.fromJson(data);
  }
}

class PaymentsApi {
  final ApiClient _client;

  PaymentsApi(this._client);

  Future<PaymentIntent> createIntent(String orderId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/payments/create-intent',
      body: {'order_id': orderId},
    );
    return PaymentIntent.fromJson(data);
  }
}
