import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/models/auth_session.dart';
import '../storage/token_storage.dart';
import 'api_error_code.dart';
import 'api_exception.dart';
import 'session_events.dart';

/// Attaches the Bearer token and transparently refreshes it on `TOKEN_EXPIRED`.
///
/// Depends only on [TokenStorage], [SessionEvents] and a refresh callback, never
/// on the auth controller; the controller listens to [SessionEvents.expired].
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._storage,
    required this._events,
    required this._refresh,
    required this._retryDio,
  });

  /// Endpoints that never carry a Bearer token and never trigger a refresh.
  static const _publicPaths = {
    '/auth/setup-status',
    '/auth/register-owner',
    '/auth/login',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/logout',
  };

  static const _retriedKey = 'auth_retried';

  final TokenStorage _storage;
  final SessionEvents _events;
  final Future<AuthSession> Function(String refreshToken) _refresh;

  /// Dio without this interceptor, used to repeat the original request. Using
  /// the main Dio here would queue the retry behind the error being handled.
  final Dio _retryDio;

  Future<_RefreshResult>? _inFlight;

  static bool _isPublic(String path) => _publicPaths.contains(path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final tokens = await _storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (_isPublic(options.path) || options.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    final error = ApiException.fromDio(err);
    if (error.code == ApiErrorCode.tokenExpired) {
      await _handleExpired(err, handler);
      return;
    }
    if (_endsSession(error)) await _expire();
    handler.next(err);
  }

  Future<void> _handleExpired(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    // A queued request that failed with the old token while another request was
    // refreshing: the new token is already stored, so just repeat it.
    final current = await _storage.read();
    final sentHeader = options.headers['Authorization'];
    if (current != null && sentHeader != 'Bearer ${current.accessToken}') {
      await _retry(err, handler, current.accessToken);
      return;
    }

    final result = await (_inFlight ??= _runRefresh().whenComplete(
      () => _inFlight = null,
    ));

    switch (result.outcome) {
      case _RefreshOutcome.refreshed:
        await _retry(err, handler, result.accessToken!);
      case _RefreshOutcome.sessionEnded:
        handler.next(err);
      case _RefreshOutcome.failed:
        // Network or server trouble: keep the tokens and surface that error.
        handler.next(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: result.error,
          ),
        );
    }
  }

  Future<_RefreshResult> _runRefresh() async {
    final tokens = await _storage.read();
    if (tokens == null) {
      await _expire();
      return const _RefreshResult(_RefreshOutcome.sessionEnded);
    }
    try {
      final session = await _refresh(tokens.refreshToken);
      await _storage.save(session);
      return _RefreshResult(
        _RefreshOutcome.refreshed,
        accessToken: session.accessToken,
      );
    } on ApiException catch (e) {
      if (_refreshRejected(e)) {
        await _expire();
        return const _RefreshResult(_RefreshOutcome.sessionEnded);
      }
      return _RefreshResult(_RefreshOutcome.failed, error: e);
    }
  }

  Future<void> _retry(
    DioException err,
    ErrorInterceptorHandler handler,
    String accessToken,
  ) async {
    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..extra[_retriedKey] = true;
    try {
      handler.resolve(await _retryDio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      if (_endsSession(ApiException.fromDio(retryError))) await _expire();
      handler.next(retryError);
    }
  }

  /// The refresh endpoint rejected the refresh token or the account.
  static bool _refreshRejected(ApiException e) {
    return e.code == ApiErrorCode.invalidRefreshToken ||
        e.code == ApiErrorCode.accountInactive ||
        e.statusCode == 401 ||
        e.statusCode == 403;
  }

  /// Auth failures on a request that was sent with credentials. Wrong
  /// credentials (`INVALID_CREDENTIALS`, e.g. change-password) are not one.
  static bool _endsSession(ApiException e) {
    return e.code == ApiErrorCode.unauthorized ||
        e.code == ApiErrorCode.invalidRefreshToken ||
        e.code == ApiErrorCode.accountInactive ||
        e.code == ApiErrorCode.tokenExpired;
  }

  Future<void> _expire() async {
    await _storage.clear();
    _events.notifyExpired();
  }
}

enum _RefreshOutcome { refreshed, sessionEnded, failed }

class _RefreshResult {
  const _RefreshResult(this.outcome, {this.accessToken, this.error});

  final _RefreshOutcome outcome;
  final String? accessToken;
  final ApiException? error;
}
