import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/session_events.dart';
import '../../../core/storage/token_storage.dart';
import '../data/models/app_user.dart';
import '../data/models/auth_session.dart';
import 'auth_providers.dart';
import 'auth_state.dart';
import 'session_expired_notice.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
  // A network failure at startup is shown on the splash screen with a manual
  // retry button, not retried silently.
  retry: (_, _) => null,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final subscription = ref
        .read(sessionEventsProvider)
        .expired
        .listen((_) => _onSessionExpired());
    ref.onDispose(subscription.cancel);

    final storage = ref.read(tokenStorageProvider);
    if (await storage.read() == null) return const Unauthenticated();

    try {
      final user = await ref.read(authRepositoryProvider).me();
      return Authenticated(user);
    } on ApiException catch (e) {
      if (_isAuthFailure(e)) {
        await storage.clear();
        ref.read(sessionExpiredNoticeProvider.notifier).raise();
        return const Unauthenticated();
      }
      // Network or server trouble: keep the tokens and let the splash retry.
      rethrow;
    }
  }

  /// 401/403 mean the server rejected the session; anything else (no network,
  /// timeout, 5xx) does not say anything about the tokens.
  static bool _isAuthFailure(ApiException e) =>
      e.statusCode == 401 || e.statusCode == 403;

  Future<void> login(String email, String password) async {
    final session = await ref
        .read(authRepositoryProvider)
        .login(email, password);
    await _startSession(session);
  }

  Future<void> registerOwner({
    required String name,
    required String email,
    required String password,
    required String outletName,
    required String outletCode,
    String? outletAddress,
    String? outletPhone,
  }) async {
    final session = await ref
        .read(authRepositoryProvider)
        .registerOwner(
          name: name,
          email: email,
          password: password,
          outletName: outletName,
          outletCode: outletCode,
          outletAddress: outletAddress,
          outletPhone: outletPhone,
        );
    await _startSession(session);
  }

  /// Calls `/auth/logout`, then clears the tokens even if the request failed.
  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    final tokens = await storage.read();
    if (tokens != null) {
      try {
        await ref.read(authRepositoryProvider).logout(tokens.refreshToken);
      } on ApiException {
        // Ignored on purpose: the local session is dropped regardless.
      }
    }
    await storage.clear();
    state = const AsyncData(Unauthenticated());
  }

  /// Replaces the signed-in user, e.g. after a profile edit.
  void updateUser(AppUser user) {
    if (state.value is Authenticated) state = AsyncData(Authenticated(user));
  }

  Future<void> _startSession(AuthSession session) async {
    await ref.read(tokenStorageProvider).save(session);
    state = AsyncData(Authenticated(session.user));
  }

  void _onSessionExpired() {
    // While build() is running it handles the failure itself.
    if (state.value is! Authenticated) return;
    ref.read(sessionExpiredNoticeProvider.notifier).raise();
    state = const AsyncData(Unauthenticated());
  }
}
