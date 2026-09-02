import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import '../core/providers/api_provider.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _initUser();
  }

  Future<void> _initUser() async {
    if (AniApi.isLoggedIn) {
      try {
        _user = await AniApi.instance.api.users.me();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load user on init: $e');
      }
    }
  }

  User? get user => _user;
  bool get isLoggedIn => AniApi.isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await AniApi.instance.api.auth.login(
        identifier: email,
        password: password,
      );
      await AniApi.onLoginSuccess();
      if (res['user'] != null) {
        _user = User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      } else {
        _user = await AniApi.instance.api.users.me();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String pinCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await AniApi.instance.api.auth.register(
        email: email,
        phone: phone,
        name: name,
        password: password,
        role: 'customer',
      );
      await AniApi.onLoginSuccess();
      if (res['user'] != null) {
        _user = User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      } else {
        _user = await AniApi.instance.api.users.me();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await AniApi.onLogout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
