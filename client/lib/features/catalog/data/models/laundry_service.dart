import 'pricing_unit.dart';
import 'service_category.dart';

class LaundryService {
  const LaundryService({
    required this.id,
    required this.outletId,
    required this.category,
    required this.name,
    required this.pricingUnit,
    required this.regularPrice,
    required this.expressPrice,
    required this.regularDurationDays,
    required this.expressDurationDays,
    required this.minQuantity,
    required this.isSystem,
    required this.isActive,
    required this.sortOrder,
  });

  factory LaundryService.fromJson(Map<String, dynamic> json) {
    int intOf(String key) => (json[key] as num?)?.toInt() ?? 0;
    return LaundryService(
      id: json['id'] as String,
      outletId: json['outlet_id'] as String? ?? '',
      category: ServiceCategory.fromValue(json['category'] as String?),
      name: json['name'] as String? ?? '',
      pricingUnit: PricingUnit.fromValue(json['pricing_unit'] as String?),
      regularPrice: intOf('regular_price'),
      expressPrice: intOf('express_price'),
      regularDurationDays: intOf('regular_duration_days'),
      expressDurationDays: intOf('express_duration_days'),
      minQuantity: (json['min_quantity'] as num?)?.toDouble() ?? 0,
      isSystem: json['is_system'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: intOf('sort_order'),
    );
  }

  final String id;
  final String outletId;
  final ServiceCategory category;
  final String name;
  final PricingUnit pricingUnit;
  final int regularPrice;
  final int expressPrice;
  final int regularDurationDays;
  final int expressDurationDays;

  /// 0 means no minimum.
  final double minQuantity;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;
}
