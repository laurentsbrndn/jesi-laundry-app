/// One chart bar.
class SeriesPoint {
  const SeriesPoint({
    required this.wallClock,
    required this.orders,
    required this.weightKg,
    required this.revenue,
  });

  factory SeriesPoint.fromJson(Map<String, dynamic> json) {
    return SeriesPoint(
      wallClock: parseWallClock(json['bucket_start'] as String? ?? ''),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
      revenue: (json['revenue'] as num?)?.toInt(),
    );
  }

  /// The bucket start as written by the server in the business time zone
  /// (e.g. `2026-10-21T00:00:00+07:00` -> 21 Oct 00:00). Only its fields are
  /// meaningful; it is not an instant, so never convert it with `toLocal()`.
  final DateTime wallClock;
  final int orders;
  final double weightKg;
  final int? revenue;
}

/// Reads year, month, day, hour and minute straight from an RFC 3339 string,
/// ignoring the UTC offset, so the label shows the business-zone time.
DateTime parseWallClock(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?')
      .firstMatch(value);
  if (match == null) return DateTime.fromMillisecondsSinceEpoch(0);
  int part(int group) => int.tryParse(match.group(group) ?? '') ?? 0;
  return DateTime(part(1), part(2), part(3), part(4), part(5));
}
