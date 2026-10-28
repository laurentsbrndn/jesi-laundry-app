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
  /// (`{"error": {"code", "message", "details"}}`).
  ///
  /// - No response (timeout, no connection, DNS) -> [ApiErrorCode.networkError].
  /// - Response that is not JSON or has no envelope -> [ApiErrorCode.internalError]
  ///   for 5xx, otherwise [ApiErrorCode.unknown]; the status code is kept.
  /// - A DioException that already wraps an [ApiException] returns it unchanged.
  factory ApiException.fromDio(DioException e) {
    final inner = e.error;
    if (inner is ApiException) return inner;

    final response = e.response;
    if (response == null) {
      return ApiException(
        code: ApiErrorCode.networkError,
        message: e.message ?? '',
      );
    }

    final statusCode = response.statusCode;
    final isServerError = statusCode != null && statusCode >= 500;
    final data = response.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final rawCode = error['code'];
      final rawMessage = error['message'];
      final rawDetails = error['details'];
      return ApiException(
        code: rawCode is String && rawCode.isNotEmpty
            ? rawCode
            : (isServerError
                  ? ApiErrorCode.internalError
                  : ApiErrorCode.unknown),
        message: rawMessage is String ? rawMessage : '',
        statusCode: statusCode,
        details: rawDetails is List
            ? rawDetails
                  .whereType<Map>()
                  .map((m) => FieldError.fromJson(Map<String, dynamic>.from(m)))
                  .toList()
            : const [],
      );
    }
    return ApiException(
      code: isServerError ? ApiErrorCode.internalError : ApiErrorCode.unknown,
      statusCode: statusCode,
    );
  }

  final String code;

  /// Server message, for debugging only. Never show it to the user.
  final String message;
  final int? statusCode;
  final List<FieldError> details;

  bool get isNetworkError => code == ApiErrorCode.networkError;

  @override
  String toString() =>
      'ApiException($code, status: $statusCode, message: $message)';
}
