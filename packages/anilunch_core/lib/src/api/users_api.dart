import '../models/user.dart';
import 'api_client.dart';

class UsersApi {
  final ApiClient _client;

  UsersApi(this._client);

  Future<User> me() async {
    final data =
        await _client.get<Map<String, dynamic>>('/api/v1/users/me');
    return User.fromJson(data);
  }

  Future<User> updateProfile(UpdateProfileRequest request) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/users/me',
      body: request.toJson(),
    );
    return User.fromJson(data);
  }

  Future<List<Notification>> notifications({int limit = 50}) async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/users/me/notifications',
      query: {'limit': limit},
    );
    return data
        .map((e) => Notification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationsRead() async {
    await _client.post('/api/v1/users/me/notifications/read');
  }
}
