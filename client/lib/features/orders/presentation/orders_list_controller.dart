import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/paginated.dart';
import '../../../core/state/paged_list_notifier.dart';
import '../../../core/state/paged_list_state.dart';
import '../data/models/order_filter.dart';
import '../data/models/order_list_item.dart';
import '../data/models/order_status.dart';
import '../data/models/payment_status.dart';
import 'orders_providers.dart';

final ordersListControllerProvider =
    AsyncNotifierProvider.autoDispose<
      OrdersListController,
      PagedListState<OrderListItem>
    >(OrdersListController.new, retry: (_, _) => null);

class OrdersListController extends PagedListNotifier<OrderListItem> {
  OrderStatus? _status;
  PaymentStatus? _payment;

  void setStatus(OrderStatus? status) {
    if (status == _status) return;
    _status = status;
    reload();
  }

  void setPayment(PaymentStatus? payment) {
    if (payment == _payment) return;
    _payment = payment;
    reload();
  }

  @override
  Future<Paginated<OrderListItem>> fetchPage(
    int page, {
    required String search,
    String? outletId,
  }) {
    return ref
        .read(orderRepositoryProvider)
        .list(
          OrderFilter(
            status: _status,
            paymentStatus: _payment,
            search: search,
            outletId: outletId,
          ),
          page: page,
          limit: PagedListNotifier.pageSize,
        );
  }
}
