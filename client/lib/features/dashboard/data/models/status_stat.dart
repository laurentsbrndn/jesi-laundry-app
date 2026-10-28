import '../../../orders/data/models/order_status.dart';

class StatusStat {
  const StatusStat({required this.status, required this.orders});

  factory StatusStat.fromJson(Map<String, dynamic> json) {
    return StatusStat(
      status: OrderStatus.fromValue(json['status'] as String?),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );
  }

  final OrderStatus status;
  final int orders;
}
