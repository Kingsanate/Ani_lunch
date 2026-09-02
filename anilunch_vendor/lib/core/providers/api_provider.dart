import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bootstraps the Go API client, token manager and realtime gateway for the
/// vendor app.
class AniApi {
  static const _kAccess = 'ani_api_access_token';
  static const _kRefresh = 'ani_api_refresh_token';
  static const _kUser = 'ani_api_user_id';

  static AniApi? _instance;

  final AnilunchApi api;
  final RealtimeClient realtime;
  final TokenManager tokens;

  AniApi._({required this.api, required this.realtime, required this.tokens});

  static AniApi get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
          'AniApi not initialized. Call AniApi.ensureInitialized() first.');
    }
    return i;
  }

  static bool get isInitialized => _instance != null;
  static bool get isLoggedIn => isInitialized && instance.tokens.accessToken != null;
  static String? get currentUserId => isInitialized ? instance.tokens.userId : null;

  static Future<AniApi> ensureInitialized({String? baseUrl}) async {
    final existing = _instance;
    if (existing != null) return existing;

    final tokens = TokenManager(onPersist: (access, refresh, userId) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccess, access);
      await prefs.setString(_kRefresh, refresh);
      await prefs.setString(_kUser, userId);
    });
    await tokens.restore(() async {
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString(_kAccess);
      final refresh = prefs.getString(_kRefresh);
      final userId = prefs.getString(_kUser);
      if (access == null || refresh == null || userId == null) return null;
      return (access: access, refresh: refresh, userId: userId);
    });

    final resolvedBase =
        baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
    final client = ApiClient(baseUrl: resolvedBase, tokens: tokens);
    final api = AnilunchApi(client: client, tokens: tokens);
    final realtime = RealtimeClient(
      baseUrl: resolvedBase,
      tokenProvider: () async => tokens.accessToken,
    );

    final instance = AniApi._(api: api, realtime: realtime, tokens: tokens);
    _instance = instance;

    if (tokens.accessToken != null) {
      try {
        await realtime.connect();
      } catch (e) {
        debugPrint('Vendor realtime connect notice: $e');
      }
    }

    return instance;
  }

  static Future<void> onLoginSuccess() async {
    final instance = _instance;
    if (instance == null) return;
    try {
      await instance.realtime.connect();
    } catch (e) {
      debugPrint('Realtime connect failed: $e');
    }
  }

  static Future<void> onLogout() async {
    final instance = _instance;
    if (instance == null) return;
    try {
      instance.realtime.disconnect();
      await instance.tokens.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccess);
      await prefs.remove(_kRefresh);
      await prefs.remove(_kUser);
    } catch (e) {
      debugPrint('Vendor onLogout error: $e');
    }
  }
}