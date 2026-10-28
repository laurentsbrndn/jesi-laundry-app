import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../data/models/dashboard_summary.dart';
import 'stat_card.dart';

/// Totals for the selected range, plus the regular/express split.
class SummaryCards extends StatelessWidget {
  const SummaryCards({
    super.key,
    required this.summary,
    required this.showRevenue,
  });

  final DashboardSummary summary;

  /// Owners only. When false nothing about revenue is built.
  final bool showRevenue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final totals = summary.totals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboardSummary, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        StatGrid(
          children: [
            StatCard(
              label: l10n.dashboardTotalOrders,
              value: formatQuantity(totals.orders, locale),
            ),
            StatCard(
              label: l10n.dashboardTotalKg,
              value:
                  '${formatQuantity(totals.weightKg, locale)} ${l10n.unitKg}',
            ),
            StatCard(
              label: l10n.dashboardTotalPcs,
              value:
                  '${formatQuantity(totals.unitPieces, locale)} ${l10n.unitPcs}',
            ),
            StatCard(
              label: l10n.dashboardTotalSqm,
              value:
                  '${formatQuantity(totals.areaSqm, locale)} ${l10n.unitSqm}',
            ),
          ],
        ),
        if (showRevenue && totals.revenue != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: StatCard(
              label: l10n.dashboardRevenue,
              value: formatCurrency(totals.revenue!),
              details: [
                if (totals.revenuePaid != null)
                  '${l10n.dashboardRevenuePaid}: ${formatCurrency(totals.revenuePaid!)}',
                if (totals.revenueUnpaid != null)
                  '${l10n.dashboardRevenueUnpaid}: ${formatCurrency(totals.revenueUnpaid!)}',
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (final stat in summary.bySpeed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              [
                '${stat.speed.label(context)}: ${l10n.dashboardOrdersCount(stat.orders)}',
                if (showRevenue && stat.revenue != null)
                  formatCurrency(stat.revenue!),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
