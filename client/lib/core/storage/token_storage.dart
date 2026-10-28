import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/auth_session.dart';
import 'auth_tokens.dart';

/// Overridden in `main.dart` with the instance prepared at startup.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => throw UnimplementedError('tokenStorageProvider must be overridden'),
);

/// Access and refresh tokens in the platform secure store.
///
/// Never logs token values. Reads are cached in memory so the auth
/// interceptor does not hit the keychain on every request.
class TokenStorage {
  TokenStorage(this._secure, this._prefs);

  static const _installMarkerKey = 'secure_storage_initialized';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _accessExpiresKey = 'access_token_expires_at';
  static const _refreshExpiresKey = 'refresh_token_expires_at';

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  bool _loaded = false;
  AuthTokens? _cache;

  /// The iOS Keychain survives app uninstall. On the first launch of a fresh
  /// install (marker absent in SharedPreferences, which is wiped on uninstall)
  /// drop everything left in secure storage. Call before anything reads tokens.
  Future<void> resetOnFreshInstall() async {
    if (_prefs.getBool(_installMarkerKey) ?? false) return;
    try {
      await _secure.deleteAll();
    } catch (_) {
      // Leave the marker unset so the wipe is attempted again next launch.
      return;
    }
    await _prefs.setBool(_installMarkerKey, true);
  }

  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    try {
      final values = await _secure.readAll();
      final access = values[_accessTokenKey];
      final refresh = values[_refreshTokenKey];
      _cache =
          (access == null ||
              refresh == null ||
              access.isEmpty ||
              refresh.isEmpty)
          ? null
          : AuthTokens(
              accessToken: access,
              refreshToken: refresh,
              accessTokenExpiresAt: _parseTime(values[_accessExpiresKey]),
              refreshTokenExpiresAt: _parseTime(values[_refreshExpiresKey]),
            );
    } catch (_) {
      // Unreadable store (e.g. the Android key was lost): behave as logged out.
      _cache = null;
    }
    _loaded = true;
    return _cache;
  }

  Future<void> save(AuthSession session) async {
    final tokens = session.tokens;
    await _secure.write(key: _accessTokenKey, value: tokens.accessToken);
    await _secure.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _writeTime(_accessExpiresKey, tokens.accessTokenExpiresAt);
    await _writeTime(_refreshExpiresKey, tokens.refreshTokenExpiresAt);
    _cache = tokens;
    _loaded = true;
  }

  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    try {
      await _secure.deleteAll();
    } catch (_) {
      // Nothing more to do; the in-memory copy is already gone.
    }
  }

  Future<void> _writeTime(String key, DateTime? value) {
    return _secure.write(key: key, value: value?.toUtc().toIso8601String());
  }

  static DateTime? _parseTime(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
