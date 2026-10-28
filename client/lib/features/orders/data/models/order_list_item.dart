import '../../../auth/data/models/outlet_ref.dart';
import 'order_status.dart';
import 'payment_status.dart';
import 'service_speed.dart';

class OrderListItem {
  const OrderListItem({
    required this.id,
    required this.orderNumber,
    required this.outlet,
    required this.customerName,
    required this.customerPhone,
    required this.speed,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.itemsCount,
    required this.estimatedDoneAt,
    required this.createdAt,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    final outlet = json['outlet'];
    return OrderListItem(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      outlet: outlet is Map<String, dynamic>
          ? OutletRef.fromJson(outlet)
          : null,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      speed: ServiceSpeed.fromValue(json['speed'] as String?),
      status: OrderStatus.fromValue(json['status'] as String?),
      paymentStatus: PaymentStatus.fromValue(json['payment_status'] as String?),
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      estimatedDoneAt: _time(json['estimated_done_at']),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  final String id;
  final String orderNumber;
  final OutletRef? outlet;
  final String customerName;
  final String? customerPhone;
  final ServiceSpeed speed;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final int totalAmount;
  final int itemsCount;
  final DateTime? estimatedDoneAt;
  final DateTime createdAt;

  static DateTime? _time(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}
