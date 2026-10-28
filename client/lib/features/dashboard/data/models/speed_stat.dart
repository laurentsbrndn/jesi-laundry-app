import '../../../orders/data/models/service_speed.dart';

class SpeedStat {
  const SpeedStat({
    required this.speed,
    required this.orders,
    required this.revenue,
  });

  factory SpeedStat.fromJson(Map<String, dynamic> json) {
    return SpeedStat(
      speed: ServiceSpeed.fromValue(json['speed'] as String?),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt(),
    );
  }

  final ServiceSpeed speed;
  final int orders;
  final int? revenue;
}
