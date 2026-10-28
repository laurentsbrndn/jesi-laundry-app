/// Size of one chart bar. [value] is the API `bucket`.
enum DashboardBucket {
  fiveMinutes('5m'),
  hour('hour'),
  day('day'),
  month('month'),
  year('year');

  const DashboardBucket(this.value);

  final String value;

  /// An unknown value is treated as [day].
  static DashboardBucket fromValue(String? value) {
    return DashboardBucket.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DashboardBucket.day,
    );
  }
}
