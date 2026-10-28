import 'package:dio/dio.dart';

import '../../../core/network/api_call.dart';
import '../../../core/network/paginated.dart';
import 'models/order_detail.dart';
import 'models/order_draft.dart';
import 'models/order_filter.dart';
import 'models/order_list_item.dart';
import 'models/order_status.dart';
import 'models/payment_status.dart';

/// Order endpoints. Mutations are not idempotent, so nothing here retries.
class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<Paginated<OrderListItem>> list(
    OrderFilter filter, {
    required int page,
    required int limit,
  }) {
    final search = filter.search.trim();
    return apiCall(
      () => _dio.get<dynamic>(
        '/orders',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (filter.status != null) 'status': filter.status!.value,
          if (filter.paymentStatus != null)
            'payment_status': filter.paymentStatus!.value,
          if (search.isNotEmpty) 'search': search,
          'outlet_id': ?filter.outletId,
        },
      ),
      (body) =>
          parsePage(body, OrderListItem.fromJson, page: page, limit: limit),
    );
  }

  Future<OrderDetail> get(String id) {
    return apiCall(
      () => _dio.get<dynamic>('/orders/$id'),
      (body) => OrderDetail.fromJson(envelopeObject(body)),
    );
  }

  /// [includeOutletId] is true for owners; staff must not send `outlet_id`.
  Future<OrderDetail> create(
    OrderDraft draft, {
    required bool includeOutletId,
  }) {
    final notes = draft.notes.trim();
    return apiCall(
      () => _dio.post<dynamic>(
        '/orders',
        data: {
          if (includeOutletId) 'outlet_id': draft.outletId,
          ..._commonBody(draft),
          'payment_status':
              (draft.isPaid ? PaymentStatus.paid : PaymentStatus.unpaid).value,
          if (notes.isNotEmpty) 'notes': notes,
        },
      ),
      (body) => OrderDetail.fromJson(envelopeObject(body)),
    );
  }

  /// Owner only. No `outlet_id` or `payment_status`; empty notes clear them.
  Future<OrderDetail> update(String id, OrderDraft draft) {
    return apiCall(
      () => _dio.put<dynamic>(
        '/orders/$id',
        data: {..._commonBody(draft), 'notes': draft.notes.trim()},
      ),
      (body) => OrderDetail.fromJson(envelopeObject(body)),
    );
  }

  Future<OrderDetail> changeStatus(String id, OrderStatus status) {
    return apiCall(
      () => _dio.patch<dynamic>(
        '/orders/$id/status',
        data: {'status': status.value},
      ),
      (body) => OrderDetail.fromJson(envelopeObject(body)),
    );
  }

  Future<OrderDetail> changePayment(String id, PaymentStatus status) {
    return apiCall(
      () => _dio.patch<dynamic>(
        '/orders/$id/payment',
        data: {'payment_status': status.value},
      ),
      (body) => OrderDetail.fromJson(envelopeObject(body)),
    );
  }

  Future<void> delete(String id) {
    return apiCall(() => _dio.delete<dynamic>('/orders/$id'), (_) {});
  }

  /// Existing customers send only their id; new ones send name and phone.
  Map<String, Object?> _commonBody(OrderDraft draft) {
    final phone = draft.customerPhone.trim();
    return {
      'customer': draft.customerId != null
          ? {'id': draft.customerId}
          : {
              'name': draft.customerName.trim(),
              if (phone.isNotEmpty) 'phone': phone,
            },
      'speed': draft.speed.value,
      'items': [for (final item in draft.items) item.toJson()],
    };
  }
}
