import 'api_client.dart';

/// Native authentication operations.
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// Registers a new user and sets session tokens.
  Future<Map<String, dynamic>> register({
    String? email,
    String? phone,
    required String name,
    required String password,
    String role = 'customer',
  }) {
    return _client.register(
      email: email,
      phone: phone,
      name: name,
      password: password,
      role: role,
    );
  }

  /// Logs in by email/phone + password and sets session tokens.
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) {
    return _client.login(identifier: identifier, password: password);
  }

  /// Returns current authenticated user profile.
  Future<Map<String, dynamic>> me() {
    return _client.get('/api/v1/auth/me');
  }

  /// Logs out and clears session tokens.
  Future<void> logout({bool allSessions = false}) {
    return _client.logout(allSessions: allSessions);
  }
}
