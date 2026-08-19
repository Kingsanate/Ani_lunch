import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  AuthState? _authState;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    Supabase.instance.client.auth.onAuthStateChange.listen((AuthState state) {
      _user = state.session?.user;
      _authState = state;
      // Bridge Supabase auth to Go-issued API tokens on every state change.
      AniApi.exchangeForSession();
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone_number': phone,
          'address': address,
        },
      );

      if (res.user != null) {
        await Supabase.instance.client.from('users').insert({
          'id': res.user!.id,
          'user_id': res.user!.id,
          'name': name,
          'email': email,
          'phone_number': phone,
          'address': address,
          'pin_code': pinCode,
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
