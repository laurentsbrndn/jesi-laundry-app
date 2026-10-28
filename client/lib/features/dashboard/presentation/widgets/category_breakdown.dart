import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../../catalog/data/models/service_category.dart';
import '../../data/models/category_stat.dart';
import '../../data/models/dashboard_summary.dart';

/// The four categories with order count, kg (per-kilo only), share of orders
/// and revenue (owner).
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.summary,
    required this.showRevenue,
  });

  final DashboardSummary summary;
  final bool showRevenue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final total = summary.totals.orders;

    CategoryStat statFor(ServiceCategory category) {
      return summary.byCategory
              .where((s) => s.category == category)
              .firstOrNull ??
          CategoryStat(
            category: category,
            orders: 0,
            quantity: 0,
            revenue: null,
          );
    }

    return Column(
      children: [
        for (final category in ServiceCategory.values)
          Builder(
            builder: (context) {
              final stat = statFor(category);
              // Share of all orders in the range; 0 when there are none.
              final share = total > 0
                  ? (stat.orders / total).clamp(0.0, 1.0)
                  : 0.0;
              final details = [
                l10n.dashboardOrdersCount(stat.orders),
                // The server adds pcs and m² for `unit`, so no quantity there.
                if (category.isKilo)
                  '${formatQuantity(stat.quantity, locale)} ${l10n.unitKg}',
                if (showRevenue && stat.revenue != null)
                  formatCurrency(stat.revenue!),
              ];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label(context),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: share,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
