import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'errors.dart';
import 'token_manager.dart';

/// Typed REST client for the AniLunch Go API.
///
/// - Unwraps the `{success, data, error}` envelope.
/// - Attaches the Go-issued Bearer token from [tokens].
/// - Auto-refreshes once on 401 and retries the request.
/// - Treats 429 as a rate-limit [ApiException].
class ApiClient {
  final String baseUrl;
  final TokenManager tokens;
  final Dio _dio;

  ApiClient({
    required this.baseUrl,
    required this.tokens,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: connectTimeout,
              receiveTimeout: receiveTimeout,
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final resp = error.response;
        final isAuthFailure = resp?.statusCode == 401 ||
            resp?.statusCode == 403 ||
            resp?.statusCode == 429;
        if (isAuthFailure && resp?.statusCode != 429) {
          final refreshed = await _tryRefresh();
          if (refreshed && error.requestOptions.extra['_retried'] != true) {
            error.requestOptions.extra['_retried'] = true;
            error.requestOptions.headers['Authorization'] =
                'Bearer ${tokens.accessToken}';
            try {
              final response =
                  await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              // fall through to error mapping below
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Exchanges a Supabase session JWT for Go short-lived tokens.
  Future<TokenManager> exchangeSupabaseToken(String supabaseToken) async {
    final json = await _postRaw<Map<String, dynamic>>(
      '/api/v1/auth/exchange',
      {'supabase_token': supabaseToken},
      authenticated: false,
    );
    final userId = _userIdFromToken(json['access_token'] as String);
    await tokens.update(
      access: json['access_token'] as String,
      refresh: json['refresh_token'] as String,
      user: userId,
    );
    return tokens;
  }

  /// Rotates the refresh token; returns true when a new access token is set.
  Future<bool> refresh() => _tryRefresh();

  Future<bool> _tryRefresh() async {
    final refresh = tokens.refreshToken;
    final userId = tokens.userId;
    if (refresh == null || refresh.isEmpty || userId == null) return false;
    try {
      final json = await _postRaw<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        {'user_id': userId, 'refresh_token': refresh},
        authenticated: false,
      );
      final newUserId = _userIdFromToken(json['access_token'] as String);
      await tokens.update(
        access: json['access_token'] as String,
        refresh: json['refresh_token'] as String,
        user: newUserId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout({String? refreshToken, bool allSessions = false}) async {
    await post('/api/v1/auth/logout', body: {
      'refresh_token': refreshToken ?? tokens.refreshToken,
      'all_sessions': allSessions,
    });
    await tokens.clear();
  }

  // ---------------------------------------------------------------- verbs

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Object? data)? transform,
  }) =>
      _request('GET', path, query: query, transform: transform);

  Future<T> post<T>(
    String path, {
    Object? body,
    T Function(Object? data)? transform,
  }) =>
      _request('POST', path, body: body, transform: transform);

  Future<T> put<T>(
    String path, {
    Object? body,
    T Function(Object? data)? transform,
  }) =>
      _request('PUT', path, body: body, transform: transform);

  Future<T> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    T Function(Object? data)? transform,
  }) =>
      _request('DELETE', path, body: body, query: query, transform: transform);

  // ------------------------------------------------------------- internals

  Future<T> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    T Function(Object? data)? transform,
  }) async {
    final json = await _send(method, path, body: body, query: query);
    if (transform != null) {
      return transform(json);
    }
    if (json == null) {
      throw const ApiParseException('empty data payload');
    }
    try {
      return json as T;
    } on TypeError {
      throw ApiParseException(
          'payload type mismatch: expected $T, got ${json.runtimeType}');
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    if (authenticated && (tokens.accessToken == null)) {
      throw const ApiException(
          statusCode: 401, code: 'UNAUTHORIZED', message: 'not authenticated');
    }
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      return _parseEnvelope(response.statusCode ?? 200, response.data);
    } on DioException catch (e) {
      final resp = e.response;
      if (resp != null) {
        final code = resp.statusCode ?? 500;
        final mapped = _mapError(code, resp.data);
        if (mapped != null) throw mapped;
        throw ApiException(
            statusCode: code, code: 'HTTP_$code', message: e.message ?? '');
      }
      throw ApiNetworkException(e.message ?? 'network error');
    }
  }

  Future<T> _postRaw<T>(
    String path,
    Object body, {
    bool authenticated = false,
  }) async {
    final data = await _send('POST', path, body: body, authenticated: authenticated);
    if (data is T) return data;
    throw ApiParseException(
        'payload type mismatch: expected $T, got ${data.runtimeType}');
  }

  Object? _parseEnvelope(int statusCode, Object? raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        throw ApiParseException('non-JSON response');
      }
    }
    if (raw is! Map<String, dynamic>) {
      throw ApiParseException('unexpected response shape: ${raw.runtimeType}');
    }
    final success = raw['success'] == true;
    if (success) {
      return raw['data'];
    }
    final err = raw['error'];
    if (err is Map<String, dynamic>) {
      throw ApiException(
        statusCode: statusCode,
        code: (err['code'] ?? 'UNKNOWN').toString(),
        message: (err['message'] ?? 'request failed').toString(),
        detail: (err['detail'] ?? '').toString(),
      );
    }
    throw ApiException(
      statusCode: statusCode,
      code: 'UNKNOWN',
      message: 'request failed',
    );
  }

  ApiException? _mapError(int statusCode, Object? raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is Map<String, dynamic>) {
      final err = raw['error'];
      if (err is Map<String, dynamic>) {
        return ApiException(
          statusCode: statusCode,
          code: (err['code'] ?? 'HTTP_$statusCode').toString(),
          message: (err['message'] ?? 'request failed').toString(),
          detail: (err['detail'] ?? '').toString(),
        );
      }
    }
    if (statusCode == 429) {
      return const ApiException(
          statusCode: 429, code: 'RATE_LIMITED', message: 'too many requests');
    }
    return null;
  }

  String _userIdFromToken(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return '';
      final payload = jsonDecode(utf8.decode(base64Url.decode(
        base64Url.normalize(parts[1]),
      )));
      if (payload is Map<String, dynamic>) {
        return (payload['sub'] ?? payload['user_id'] ?? '').toString();
      }
    } catch (_) {
      // fall through
    }
    return '';
  }
}
