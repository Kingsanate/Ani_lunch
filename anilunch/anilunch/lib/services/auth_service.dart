import '../core/providers/api_provider.dart';

class AuthService {
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String pinCode,
  }) async {
    final res = await AniApi.instance.api.auth.register(
      email: email,
      phone: phone,
      name: name,
      password: password,
      role: 'customer',
    );
    await AniApi.onLoginSuccess();
    return res;
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await AniApi.instance.api.auth.login(
      identifier: email,
      password: password,
    );
    await AniApi.onLoginSuccess();
    return res;
  }

  Future<void> signOut() async {
    await AniApi.onLogout();
  }

  bool get isLoggedIn => AniApi.isLoggedIn;
  String? get currentUserId => AniApi.currentUserId;
}
