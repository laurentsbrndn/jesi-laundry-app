class OperationalStat {
  const OperationalStat({
    required this.inProgress,
    required this.readyForPickup,
    required this.unpaidOrders,
    required this.unpaidAmount,
  });

  factory OperationalStat.fromJson(Map<String, dynamic> json) {
    return OperationalStat(
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      readyForPickup: (json['ready_for_pickup'] as num?)?.toInt() ?? 0,
      unpaidOrders: (json['unpaid_orders'] as num?)?.toInt() ?? 0,
      unpaidAmount: (json['unpaid_amount'] as num?)?.toInt(),
    );
  }

  /// Current state, not limited by the selected range.
  final int inProgress;
  final int readyForPickup;
  final int unpaidOrders;

  /// Absent for staff.
  final int? unpaidAmount;
}
