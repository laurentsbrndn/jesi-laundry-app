import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

/// Rolling window of the dashboard. [value] is the API `range` parameter.
enum DashboardRange {
  hour1('1h'),
  hours24('24h'),
  days7('7d'),
  days30('30d'),
  year1('1y'),
  all('all');

  const DashboardRange(this.value);

  final String value;

  static DashboardRange fromValue(String? value) {
    return DashboardRange.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DashboardRange.hours24,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      DashboardRange.hour1 => l10n.dashboardRange1h,
      DashboardRange.hours24 => l10n.dashboardRange24h,
      DashboardRange.days7 => l10n.dashboardRange7d,
      DashboardRange.days30 => l10n.dashboardRange30d,
      DashboardRange.year1 => l10n.dashboardRange1y,
      DashboardRange.all => l10n.dashboardRangeAll,
    };
  }
}
