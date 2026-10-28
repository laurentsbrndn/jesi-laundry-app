import '../../../catalog/data/models/pricing_unit.dart';
import '../../../catalog/data/models/service_category.dart';

/// One line of a saved order, as computed by the server.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.pricingUnit,
    required this.quantity,
    required this.lengthM,
    required this.widthM,
    required this.billedQuantity,
    required this.unitPrice,
    required this.subtotal,
    required this.durationDays,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double? decimal(String key) => (json[key] as num?)?.toDouble();
    int whole(String key) => (json[key] as num?)?.toInt() ?? 0;
    final quantity = decimal('quantity') ?? 0;
    return OrderItem(
      id: json['id'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      category: ServiceCategory.fromValue(json['category'] as String?),
      pricingUnit: PricingUnit.fromValue(json['pricing_unit'] as String?),
      quantity: quantity,
      lengthM: decimal('length_m'),
      widthM: decimal('width_m'),
      billedQuantity: decimal('billed_quantity') ?? quantity,
      unitPrice: whole('unit_price'),
      subtotal: whole('subtotal'),
      durationDays: whole('duration_days'),
    );
  }

  final String id;
  final String serviceId;
  final String serviceName;
  final ServiceCategory category;
  final PricingUnit pricingUnit;

  /// kg, pcs or area in m².
  final double quantity;
  final double? lengthM;
  final double? widthM;

  /// Quantity charged after the service minimum.
  final double billedQuantity;
  final int unitPrice;
  final int subtotal;
  final int durationDays;
}
