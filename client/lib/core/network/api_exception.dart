import 'package:dio/dio.dart';

import 'api_error_code.dart';
import 'field_error.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    this.message = '',
    this.statusCode,
    this.details = const [],
  });

  /// Maps a [DioException] to an [ApiException] using the server error envelope
  /// (`{"error": {"code", "message", "details"}}`). Timeouts and connection
  /// failures become [ApiErrorCode.networkError].
  factory ApiException.fromDio(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final error = data['error'] as Map<String, dynamic>;
      final rawDetails = error['details'];
      return ApiException(
        code: error['code'] as String? ?? ApiErrorCode.internalError,
        message: error['message'] as String? ?? '',
        statusCode: statusCode,
        details: rawDetails is List
            ? rawDetails
                  .whereType<Map<String, dynamic>>()
                  .map(FieldError.fromJson)
                  .toList()
            : const [],
      );
    }
    if (e.response == null) {
      return ApiException(
        code: ApiErrorCode.networkError,
        message: e.message ?? '',
      );
    }
    return ApiException(
      code: statusCode != null && statusCode >= 500
          ? ApiErrorCode.internalError
          : ApiErrorCode.badRequest,
      statusCode: statusCode,
    );
  }

  final String code;

  /// Server message, for debugging only. Never show it to the user.
  final String message;
  final int? statusCode;
  final List<FieldError> details;

  @override
  String toString() =>
      'ApiException($code, status: $statusCode, message: $message)';
}
