import 'package:dio/dio.dart';

import 'api_error_code.dart';
import 'api_exception.dart';
import 'paginated.dart';

/// Runs [request], maps transport failures to [ApiException] and hands the
/// decoded response body to [parse]. A body that [parse] cannot read becomes
/// [ApiErrorCode.invalidResponse].
Future<T> apiCall<T>(
  Future<Response<dynamic>> Function() request,
  T Function(dynamic body) parse,
) async {
  final Response<dynamic> response;
  try {
    response = await request();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
  try {
    return parse(response.data);
  } on ApiException {
    rethrow;
  } catch (_) {
    throw ApiException(
      code: ApiErrorCode.invalidResponse,
      statusCode: response.statusCode,
    );
  }
}

/// The `data` field of a success envelope, or null.
dynamic envelopeData(dynamic body) => body is Map ? body['data'] : null;

/// `data` as a JSON object.
Map<String, dynamic> envelopeObject(dynamic body) =>
    Map<String, dynamic>.from(envelopeData(body) as Map);

/// `data` as a list of JSON objects.
List<Map<String, dynamic>> envelopeList(dynamic body) {
  return (envelopeData(body) as List)
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
}

/// Parses a paginated list. When `meta` is missing, [Paginated.hasMore] falls
/// back to "the page was full".
Paginated<T> parsePage<T>(
  dynamic body,
  T Function(Map<String, dynamic>) fromItem, {
  required int page,
  required int limit,
}) {
  final items = envelopeList(body).map(fromItem).toList();
  final meta = body is Map ? body['meta'] : null;
  num? read(String key) =>
      meta is Map && meta[key] is num ? meta[key] as num : null;
  final responsePage = read('page')?.toInt() ?? page;
  final responseLimit = read('limit')?.toInt() ?? limit;
  final total =
      read('total')?.toInt() ??
      (items.length >= limit
          ? responsePage * responseLimit + 1
          : (responsePage - 1) * responseLimit + items.length);
  return Paginated(
    items: items,
    page: responsePage,
    limit: responseLimit,
    total: total,
  );
}
