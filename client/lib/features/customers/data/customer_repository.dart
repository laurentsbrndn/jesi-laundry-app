import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import '../../../core/network/paginated.dart';
import 'models/customer.dart';

class CustomerRepository {
  CustomerRepository(this._dio);

  final Dio _dio;

  Future<Paginated<Customer>> list({
    required int page,
    required int limit,
    String? search,
  }) {
    return apiCall(
      () => _dio.get<dynamic>(
        '/customers',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ),
      (body) => parsePage(body, Customer.fromJson, page: page, limit: limit),
    );
  }

  Future<Customer> get(String id) {
    return apiCall(
      () => _dio.get<dynamic>('/customers/$id'),
      (body) => Customer.fromJson(envelopeObject(body)),
    );
  }

  /// [changes] holds only changed fields (`name`, `phone`). An empty `phone`
  /// clears the number.
  Future<Customer> update(String id, Map<String, Object?> changes) {
    return apiCall(
      () => _dio.patch<dynamic>('/customers/$id', data: changes),
      (body) => Customer.fromJson(envelopeObject(body)),
    );
  }
}
