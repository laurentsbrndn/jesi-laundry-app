import '../../../catalog/data/models/pricing_unit.dart';

class UnitServiceStat {
  const UnitServiceStat({
    required this.serviceId,
    required this.serviceName,
    required this.pricingUnit,
    required this.orders,
    required this.quantity,
    required this.revenue,
  });

  factory UnitServiceStat.fromJson(Map<String, dynamic> json) {
    return UnitServiceStat(
      serviceId: json['service_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      pricingUnit: PricingUnit.fromValue(json['pricing_unit'] as String?),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt(),
    );
  }

  final String serviceId;
  final String serviceName;
  final PricingUnit pricingUnit;
  final int orders;
  final double quantity;
  final int? revenue;
}
