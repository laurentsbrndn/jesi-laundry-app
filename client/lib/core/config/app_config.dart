class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Build-time configuration. The API base URL comes only from
/// `--dart-define=API_BASE_URL=...`; there is deliberately no default.
abstract final class AppConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl =>
      _rawApiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  static bool get isConfigured => apiBaseUrl.isNotEmpty;

  /// Base URL of the versioned API, e.g. `http://localhost:8080/api/v1`.
  static String get apiUrl {
    if (!isConfigured) {
      throw const AppConfigException(
        'API_BASE_URL is not set. Run with --dart-define=API_BASE_URL=<server address>.',
      );
    }
    return '$apiBaseUrl/api/v1';
  }
}
