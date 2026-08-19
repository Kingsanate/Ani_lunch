/// TokenManager holds the Go-issued short-lived access token + refresh token.
///
/// Persistence is delegated to the app via [onPersist] / [restore]. The
/// access token lives 15 minutes; the refresh token 7 days and is rotated
/// on every refresh.
class TokenManager {
  String? accessToken;
  String? refreshToken;
  String? userId;

  final Future<void> Function(
      String accessToken, String refreshToken, String userId)? onPersist;

  TokenManager({this.onPersist});

  /// Restores previously persisted tokens (e.g. from SharedPreferences).
  Future<void> restore(
      Future<({String access, String refresh, String userId})?>
          Function() loader) async {
    final stored = await loader();
    if (stored != null) {
      accessToken = stored.access;
      refreshToken = stored.refresh;
      userId = stored.userId;
    }
  }

  Future<void> update(
      {required String access,
      required String refresh,
      required String user}) async {
    accessToken = access;
    refreshToken = refresh;
    userId = user;
    await onPersist?.call(access, refresh, user);
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}