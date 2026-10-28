import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import 'models/laundry_service.dart';
import 'models/pricing_unit.dart';

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  /// Owners must always send [outletId]. Not paginated; ordered by the server.
  Future<List<LaundryService>> list({
    required String outletId,
    required bool includeInactive,
  }) {
    return apiCall(
      () => _dio.get<dynamic>(
        '/services',
        queryParameters: {
          'outlet_id': outletId,
          'include_inactive': includeInactive,
        },
      ),
      (body) => envelopeList(body).map(LaundryService.fromJson).toList(),
    );
  }

  /// Creates a unit service (`piece` or `sqm`). The server sets category,
  /// system flag, order and active state.
  Future<LaundryService> createUnitService({
    required String outletId,
    required String name,
    required PricingUnit pricingUnit,
    required int regularPrice,
    required int expressPrice,
    required int regularDurationDays,
    required int expressDurationDays,
  }) {
    return apiCall(
      () => _dio.post<dynamic>(
        '/services',
        data: {
          'outlet_id': outletId,
          'name': name.trim(),
          'pricing_unit': pricingUnit.value,
          'regular_price': regularPrice,
          'express_price': expressPrice,
          'regular_duration_days': regularDurationDays,
          'express_duration_days': expressDurationDays,
        },
      ),
      (body) => LaundryService.fromJson(envelopeObject(body)),
    );
  }

  /// [changes] holds only changed fields; zero and `false` are valid values.
  /// Never send `category` or `pricing_unit`.
  Future<LaundryService> update(String id, Map<String, Object?> changes) {
    return apiCall(
      () => _dio.patch<dynamic>('/services/$id', data: changes),
      (body) => LaundryService.fromJson(envelopeObject(body)),
    );
  }

  Future<void> delete(String id) {
    return apiCall(() => _dio.delete<dynamic>('/services/$id'), (_) {});
  }
}
