import '../../../auth/data/models/outlet_ref.dart';
import 'order_customer.dart';
import 'order_item.dart';
import 'order_status.dart';
import 'payment_status.dart';
import 'service_speed.dart';

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.outlet,
    required this.customer,
    required this.speed,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.estimatedDoneAt,
    required this.processingAt,
    required this.doneAt,
    required this.pickedUpAt,
    required this.paidAt,
    required this.notes,
    required this.items,
    required this.createdByName,
    required this.createdAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
    }

    final outlet = json['outlet'];
    final customer = json['customer'];
    final createdBy = json['created_by'];
    final items = json['items'];
    final notes = json['notes'] as String?;
    return OrderDetail(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      outlet: outlet is Map<String, dynamic>
          ? OutletRef.fromJson(outlet)
          : null,
      customer: customer is Map<String, dynamic>
          ? OrderCustomer.fromJson(customer)
          : const OrderCustomer(id: '', name: '', phone: null),
      speed: ServiceSpeed.fromValue(json['speed'] as String?),
      status: OrderStatus.fromValue(json['status'] as String?),
      paymentStatus: PaymentStatus.fromValue(json['payment_status'] as String?),
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      estimatedDoneAt: time('estimated_done_at'),
      processingAt: time('processing_at'),
      doneAt: time('done_at'),
      pickedUpAt: time('picked_up_at'),
      paidAt: time('paid_at'),
      notes: notes != null && notes.trim().isNotEmpty ? notes : null,
      items: items is List
          ? items
                .whereType<Map>()
                .map((m) => OrderItem.fromJson(Map<String, dynamic>.from(m)))
                .toList()
          : const [],
      createdByName: createdBy is Map ? createdBy['name'] as String? : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  final String id;
  final String orderNumber;
  final OutletRef? outlet;
  final OrderCustomer customer;
  final ServiceSpeed speed;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final int totalAmount;
  final DateTime? estimatedDoneAt;
  final DateTime? processingAt;
  final DateTime? doneAt;
  final DateTime? pickedUpAt;
  final DateTime? paidAt;
  final String? notes;
  final List<OrderItem> items;
  final String? createdByName;
  final DateTime createdAt;

  /// Editable by an owner only while unpaid and not picked up.
  bool get isEditable =>
      status != OrderStatus.pickedUp && !paymentStatus.isPaid;

  /// When [stage] was reached, if it has been.
  DateTime? timeOf(OrderStatus stage) => switch (stage) {
    OrderStatus.received => createdAt,
    OrderStatus.processing => processingAt,
    OrderStatus.done => doneAt,
    OrderStatus.pickedUp => pickedUpAt,
  };
}
