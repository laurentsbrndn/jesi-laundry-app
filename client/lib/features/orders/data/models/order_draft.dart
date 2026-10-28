import 'order_draft_item.dart';
import 'service_speed.dart';

/// State of the order form.
class OrderDraft {
  const OrderDraft({
    this.outletId,
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.speed = ServiceSpeed.regular,
    this.items = const [],
    this.notes = '',
    this.isPaid = false,
  });

  final String? outletId;

  /// Set when an existing customer was picked; then only the id is sent.
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final ServiceSpeed speed;
  final List<OrderDraftItem> items;
  final String notes;
  final bool isPaid;

  OrderDraft copyWith({
    String? outletId,
    bool clearOutlet = false,
    String? customerId,
    bool clearCustomerId = false,
    String? customerName,
    String? customerPhone,
    ServiceSpeed? speed,
    List<OrderDraftItem>? items,
    String? notes,
    bool? isPaid,
  }) {
    return OrderDraft(
      outletId: clearOutlet ? null : outletId ?? this.outletId,
      customerId: clearCustomerId ? null : customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      speed: speed ?? this.speed,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
