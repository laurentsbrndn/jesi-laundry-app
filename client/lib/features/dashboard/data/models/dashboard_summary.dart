import 'category_stat.dart';
import 'dashboard_bucket.dart';
import 'dashboard_range.dart';
import 'dashboard_totals.dart';
import 'operational_stat.dart';
import 'series_point.dart';
import 'speed_stat.dart';
import 'status_stat.dart';
import 'unit_service_stat.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.range,
    required this.bucket,
    required this.from,
    required this.to,
    required this.totals,
    required this.byCategory,
    required this.byUnitService,
    required this.bySpeed,
    required this.byStatus,
    required this.series,
    required this.operational,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => parse(Map<String, dynamic>.from(m)))
          .toList();
    }

    Map<String, dynamic> object(String key) {
      final raw = json[key];
      return raw is Map ? Map<String, dynamic>.from(raw) : const {};
    }

    DateTime time(String key) {
      final raw = json[key];
      return (raw is String ? DateTime.tryParse(raw) : null)?.toLocal() ??
          DateTime.now();
    }

    return DashboardSummary(
      range: DashboardRange.fromValue(json['range'] as String?),
      bucket: DashboardBucket.fromValue(json['bucket'] as String?),
      from: time('from'),
      to: time('to'),
      totals: DashboardTotals.fromJson(object('totals')),
      byCategory: list('by_category', CategoryStat.fromJson),
      byUnitService: list('by_unit_service', UnitServiceStat.fromJson),
      bySpeed: list('by_speed', SpeedStat.fromJson),
      byStatus: list('by_status', StatusStat.fromJson),
      series: list('series', SeriesPoint.fromJson),
      operational: OperationalStat.fromJson(object('operational')),
    );
  }

  final DashboardRange range;
  final DashboardBucket bucket;

  /// Period boundaries as instants in the device's time zone.
  final DateTime from;
  final DateTime to;
  final DashboardTotals totals;
  final List<CategoryStat> byCategory;
  final List<UnitServiceStat> byUnitService;
  final List<SpeedStat> bySpeed;
  final List<StatusStat> byStatus;
  final List<SeriesPoint> series;
  final OperationalStat operational;

  /// The server only sends revenue to owners.
  bool get hasRevenue => totals.revenue != null;
}
