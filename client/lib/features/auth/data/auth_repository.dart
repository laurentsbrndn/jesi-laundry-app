import 'package:dio/dio.dart';

import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import 'models/app_user.dart';
import 'models/auth_session.dart';

/// Auth and profile endpoints. Returns models; failures are [ApiException].
class AuthRepository {
  /// [plainDio] has no auth interceptor; it is used for `/auth/refresh`.
  AuthRepository({required this._dio, required this._plainDio});

  final Dio _dio;
  final Dio _plainDio;

  /// `true` when an owner is already registered.
  Future<bool> setupStatus() {
    return _call(
      () => _dio.get<dynamic>('/auth/setup-status'),
      (data) => (data as Map<String, dynamic>)['owner_exists'] as bool,
    );
  }

  Future<AuthSession> registerOwner({
    required String name,
    required String email,
    required String password,
    required String outletName,
    required String outletCode,
    String? outletAddress,
    String? outletPhone,
  }) {
    final address = outletAddress?.trim() ?? '';
    final phone = outletPhone?.trim() ?? '';
    return _call(
      () => _dio.post<dynamic>(
        '/auth/register-owner',
        data: {
          'name': name.trim(),
          'email': _normalizeEmail(email),
          'password': password,
          'outlet_name': outletName.trim(),
          'outlet_code': outletCode.trim().toUpperCase(),
          if (address.isNotEmpty) 'outlet_address': address,
          if (phone.isNotEmpty) 'outlet_phone': phone,
        },
      ),
      _session,
    );
  }

  Future<AuthSession> login(String email, String password) {
    return _call(
      () => _dio.post<dynamic>(
        '/auth/login',
        data: {'email': _normalizeEmail(email), 'password': password},
      ),
      _session,
    );
  }

  Future<AuthSession> refresh(String refreshToken) {
    return _call(
      () => _plainDio.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      ),
      _session,
    );
  }

  Future<void> logout(String refreshToken) {
    return _call(
      () => _dio.post<dynamic>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
      ),
      (_) {},
    );
  }

  /// Always succeeds server-side; returns the cooldown before another request.
  Future<int> forgotPassword(String email) {
    return _call(
      () => _dio.post<dynamic>(
        '/auth/forgot-password',
        data: {'email': _normalizeEmail(email)},
      ),
      (data) {
        final seconds = data is Map<String, dynamic>
            ? data['retry_after_seconds']
            : null;
        return seconds is num ? seconds.toInt() : 60;
      },
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _call(
      () => _dio.post<dynamic>(
        '/auth/reset-password',
        data: {
          'email': _normalizeEmail(email),
          'otp': otp,
          'new_password': newPassword,
        },
      ),
      (_) {},
    );
  }

  Future<AppUser> me() {
    return _call(
      () => _dio.get<dynamic>('/me'),
      (data) => AppUser.fromJson(data as Map<String, dynamic>),
    );
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static AuthSession _session(dynamic data) =>
      AuthSession.fromJson(data as Map<String, dynamic>);

  /// Runs [request], maps transport failures to [ApiException], and parses the
  /// `data` field of the success envelope with [parse].
  Future<T> _call<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    try {
      final body = response.data;
      return parse(body is Map<String, dynamic> ? body['data'] : null);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        code: ApiErrorCode.invalidResponse,
        statusCode: response.statusCode,
      );
    }
  }
}
