import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import '../../../core/network/paginated.dart';
import '../../auth/data/models/app_user.dart';

/// Staff management (`/users`, owner only). Reuses [AppUser].
class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<Paginated<AppUser>> list({
    required int page,
    required int limit,
    String? search,
    String? outletId,
  }) {
    return apiCall(
      () => _dio.get<dynamic>(
        '/users',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          'outlet_id': ?outletId,
        },
      ),
      (body) => parsePage(body, AppUser.fromJson, page: page, limit: limit),
    );
  }

  Future<AppUser> get(String id) {
    return apiCall(
      () => _dio.get<dynamic>('/users/$id'),
      (body) => AppUser.fromJson(envelopeObject(body)),
    );
  }

  Future<AppUser> create({
    required String name,
    required String email,
    required String password,
    required String outletId,
  }) {
    return apiCall(
      () => _dio.post<dynamic>(
        '/users',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'outlet_id': outletId,
        },
      ),
      (body) => AppUser.fromJson(envelopeObject(body)),
    );
  }

  /// [changes] holds only changed fields (`name`, `outlet_id`, `is_active`).
  Future<AppUser> update(String id, Map<String, Object?> changes) {
    return apiCall(
      () => _dio.patch<dynamic>('/users/$id', data: changes),
      (body) => AppUser.fromJson(envelopeObject(body)),
    );
  }

  Future<void> resetPassword(String id, String newPassword) {
    return apiCall(
      () => _dio.post<dynamic>(
        '/users/$id/reset-password',
        data: {'new_password': newPassword},
      ),
      (_) {},
    );
  }
}
