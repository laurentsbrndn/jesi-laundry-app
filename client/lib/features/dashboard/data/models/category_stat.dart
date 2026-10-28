import '../../../catalog/data/models/service_category.dart';

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.orders,
    required this.quantity,
    required this.revenue,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: ServiceCategory.fromValue(json['category'] as String?),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt(),
    );
  }

  final ServiceCategory category;
  final int orders;

  /// kg for the per-kilo categories. For `unit` the server adds pcs and m²
  /// into one number, so it must not be shown.
  final double quantity;
  final int? revenue;
}
