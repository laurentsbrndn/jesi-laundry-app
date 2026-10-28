import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../data/models/unit_service_stat.dart';

/// Per unit service: quantity with unit, order count and revenue (owner).
class UnitServiceBreakdown extends StatelessWidget {
  const UnitServiceBreakdown({
    super.key,
    required this.stats,
    required this.showRevenue,
  });

  final List<UnitServiceStat> stats;
  final bool showRevenue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    return Column(
      children: [
        for (final stat in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.serviceName, style: theme.textTheme.bodyLarge),
                      Text(
                        '${formatQuantity(stat.quantity, locale)} ${stat.pricingUnit.label(context)} · ${l10n.dashboardOrdersCount(stat.orders)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showRevenue && stat.revenue != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    formatCurrency(stat.revenue!),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
