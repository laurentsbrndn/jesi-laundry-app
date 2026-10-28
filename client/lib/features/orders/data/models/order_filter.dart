import 'order_status.dart';
import 'payment_status.dart';

/// Query of the order list. Null means "no filter".
class OrderFilter {
  const OrderFilter({
    this.status,
    this.paymentStatus,
    this.search = '',
    this.outletId,
  });

  final OrderStatus? status;
  final PaymentStatus? paymentStatus;
  final String search;
  final String? outletId;
}
