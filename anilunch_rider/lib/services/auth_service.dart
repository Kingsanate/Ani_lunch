import 'package:anilunch_core/anilunch_core.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';
import '../models/rider.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Bridge Supabase auth to Go-issued API tokens.
    await AniApi.exchangeForSession();

    final user = res.user;
    if (user != null) {
      // Ensure they have a rider profile. If they are a normal user logging into the rider app
      // for the first time, this creates their isolated rider profile.
      final data = await _supabase.from('riders').select().eq('id', user.id).maybeSingle();
      if (data == null) {
        await _supabase.from('riders').insert({
          'id': user.id,
          'name': email.split('@')[0], // placeholder
          'phone': '',
          'email': email,
          'is_online': false,
          'is_approved': false,
          'approval_status': 'pending',
        });
      }
    }
    return res;
  }

  /// Sign up with email + password, then create rider profile
  static Future<RiderModel?> signUpRider({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    User? user;
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      user = res.user;
    } on AuthException catch (e) {
      // If user already exists in Supabase (e.g., they use the normal app),
      // we log them in instead so they can become a rider seamlessly.
      if (e.message.toLowerCase().contains('already registered') || 
          e.message.toLowerCase().contains('already exists')) {
        final res = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        user = res.user;
      } else {
        rethrow;
      }
    }

    if (user == null) return null;

    // Bridge Supabase auth to Go-issued API tokens.
    await AniApi.exchangeForSession();

    // Check if rider profile already exists
    final data = await _supabase.from('riders').select().eq('id', user.id).maybeSingle();
    
    if (data == null) {
      // Insert into riders table — new riders start as PENDING (unapproved)
      await _supabase.from('riders').insert({
        'id': user.id,
        'name': name,
        'phone': phone,
        'email': email,
        'is_online': false,
        'is_approved': false,
        'approval_status': 'pending',
      });
    } else {
      // If they existed, update their rider profile with the newly provided name/phone
      // Do NOT change approval status on re-login
      await _supabase.from('riders').update({
        'name': name,
        'phone': phone,
      }).eq('id', user.id);
    }

    return RiderModel(
      id: user.id,
      name: name,
      phone: phone,
      email: email,
      isOnline: false,
    );
  }

  /// Load rider profile from DB (Go API first, Supabase fallback)
  static Future<RiderModel?> loadRiderProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    try {
      final rider = await AniApi.instance.api.riders.me();
      return RiderModel(
        id: rider.id,
        name: rider.name,
        phone: rider.phone,
        email: rider.email,
        isOnline: rider.isOnline,
        isApproved: rider.isApproved,
        approvalStatus: rider.approvalStatus,
        rejectionReason: rider.rejectionReason,
        createdAt: rider.createdAt,
        latitude: rider.latitude,
        longitude: rider.longitude,
      );
    } catch (e) {
      debugPrint('loadRiderProfile via API error: $e');
    }

    try {
      final data = await _supabase.from('riders').select().eq('id', uid).single();
      return RiderModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await AniApi.exchangeForSession(supabaseToken: '');
    await _supabase.auth.signOut();
  }
}
