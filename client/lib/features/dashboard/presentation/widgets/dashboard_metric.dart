import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

/// What the bar chart plots.
enum DashboardMetric {
  orders,
  weight,
  revenue;

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      DashboardMetric.orders => l10n.dashboardMetricOrders,
      DashboardMetric.weight => l10n.dashboardMetricWeight,
      DashboardMetric.revenue => l10n.dashboardMetricRevenue,
    };
  }
}
