import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order_detail.dart';
import 'orders_providers.dart';

/// One order. Mutation responses replace the state through [setDetail], so the
/// screen updates without another GET.
final orderDetailProvider = AsyncNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetail, String>(
      OrderDetailNotifier.new,
      retry: (_, _) => null,
    );

class OrderDetailNotifier extends AsyncNotifier<OrderDetail> {
  OrderDetailNotifier(this.orderId);

  final String orderId;

  @override
  Future<OrderDetail> build() => ref.read(orderRepositoryProvider).get(orderId);

  void setDetail(OrderDetail detail) => state = AsyncData(detail);
}
