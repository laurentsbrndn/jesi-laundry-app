import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/models/order_detail.dart';
import '../data/order_repository.dart';
import 'order_detail_provider.dart';
import 'orders_list_controller.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(dioProvider)),
);

/// Refreshes everything that shows order data after a mutation. Every order
/// mutation goes through here.
///
/// [updated] is the server's response for the changed order; when given, the
/// open detail screen takes it directly instead of fetching again.
///
/// F6 adds the dashboard provider invalidation here.
void invalidateOrderData(WidgetRef ref, {OrderDetail? updated}) {
  ref.invalidate(ordersListControllerProvider);
  if (updated != null) {
    ref.read(orderDetailProvider(updated.id).notifier).setDetail(updated);
  } else {
    ref.invalidate(orderDetailProvider);
  }
}
