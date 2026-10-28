import '../../../../core/storage/auth_tokens.dart';
import 'app_user.dart';

/// Response of register-owner, login, refresh and change-password.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['access_token_expires_at'] as String,
      ).toLocal(),
      refreshToken: json['refresh_token'] as String,
      refreshTokenExpiresAt: DateTime.parse(
        json['refresh_token_expires_at'] as String,
      ).toLocal(),
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final AppUser user;

  AuthTokens get tokens => AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAt: accessTokenExpiresAt,
    refreshTokenExpiresAt: refreshTokenExpiresAt,
  );
}
