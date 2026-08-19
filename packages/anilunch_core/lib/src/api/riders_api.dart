import '../models/rider.dart';
import 'api_client.dart';

class RidersApi {
  final ApiClient _client;

  RidersApi(this._client);

  Future<Rider> me() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/riders/me');
    return Rider.fromJson(data);
  }

  Future<Rider> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/riders/me',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      },
    );
    return Rider.fromJson(data);
  }

  Future<Rider> setAvailability(bool isOnline) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/riders/me/availability',
      body: {'is_online': isOnline},
    );
    return Rider.fromJson(data);
  }

  Future<Rider> updateLocation(double latitude, double longitude) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/riders/me/location',
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return Rider.fromJson(data);
  }

  Future<List<RiderOrder>> availableOrders() async {
    final data = await _client
        .get<List<dynamic>>('/api/v1/riders/orders/available');
    return data
        .map((e) => RiderOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RiderOrder>> myOrders() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/riders/orders/mine');
    return data
        .map((e) => RiderOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RiderOrder> acceptOrder(String orderId) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/riders/orders/$orderId/accept',
    );
    return RiderOrder.fromJson(data);
  }
}
