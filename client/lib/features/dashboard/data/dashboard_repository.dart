import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import 'models/dashboard_range.dart';
import 'models/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  /// [outletId] is for owners only; callers pass null for staff, whose outlet
  /// the server enforces.
  Future<DashboardSummary> get(DashboardRange range, {String? outletId}) {
    return apiCall(
      () => _dio.get<dynamic>(
        '/dashboard',
        queryParameters: {'range': range.value, 'outlet_id': ?outletId},
      ),
      (body) => DashboardSummary.fromJson(envelopeObject(body)),
    );
  }
}
