import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import 'models/outlet.dart';

class OutletRepository {
  OutletRepository(this._dio);

  final Dio _dio;

  /// Every outlet, including inactive ones. Not paginated.
  Future<List<Outlet>> list() {
    return apiCall(
      () => _dio.get<dynamic>('/outlets'),
      (body) => envelopeList(body).map(Outlet.fromJson).toList(),
    );
  }

  /// The server also creates the default service catalog for the new outlet.
  Future<Outlet> create({
    required String code,
    required String name,
    String? address,
    String? phone,
  }) {
    final trimmedAddress = address?.trim() ?? '';
    final trimmedPhone = phone?.trim() ?? '';
    return apiCall(
      () => _dio.post<dynamic>(
        '/outlets',
        data: {
          'code': code.trim().toUpperCase(),
          'name': name.trim(),
          if (trimmedAddress.isNotEmpty) 'address': trimmedAddress,
          if (trimmedPhone.isNotEmpty) 'phone': trimmedPhone,
        },
      ),
      (body) => Outlet.fromJson(envelopeObject(body)),
    );
  }

  /// [changes] holds only the changed fields (`name`, `address`, `phone`,
  /// `is_active`). `code` cannot be changed.
  Future<Outlet> update(String id, Map<String, Object?> changes) {
    return apiCall(
      () => _dio.patch<dynamic>('/outlets/$id', data: changes),
      (body) => Outlet.fromJson(envelopeObject(body)),
    );
  }
}
