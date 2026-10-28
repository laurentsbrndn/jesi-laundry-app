double _decimal(Object? value) => (value is num) ? value.toDouble() : 0;

class DashboardTotals {
  const DashboardTotals({
    required this.orders,
    required this.weightKg,
    required this.unitPieces,
    required this.areaSqm,
    required this.revenue,
    required this.revenuePaid,
    required this.revenueUnpaid,
  });

  factory DashboardTotals.fromJson(Map<String, dynamic> json) {
    int? money(String key) => (json[key] as num?)?.toInt();
    return DashboardTotals(
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      weightKg: _decimal(json['weight_kg']),
      unitPieces: _decimal(json['unit_pieces']),
      areaSqm: _decimal(json['area_sqm']),
      revenue: money('revenue'),
      revenuePaid: money('revenue_paid'),
      revenueUnpaid: money('revenue_unpaid'),
    );
  }

  final int orders;
  final double weightKg;
  final double unitPieces;
  final double areaSqm;

  /// Revenue fields are absent for staff, so they are null.
  final int? revenue;
  final int? revenuePaid;
  final int? revenueUnpaid;
}
