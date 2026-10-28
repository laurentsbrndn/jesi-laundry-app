import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../data/models/operational_stat.dart';
import 'stat_card.dart';

/// Current state of the outlet; not affected by the selected range.
class OperationalCards extends StatelessWidget {
  const OperationalCards({
    super.key,
    required this.stat,
    required this.showAmount,
  });

  final OperationalStat stat;

  /// Owners only: also show the unpaid amount.
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final amount = stat.unpaidAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboardOperationalNow, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        StatGrid(
          children: [
            StatCard(
              label: l10n.dashboardInProgress,
              value: formatQuantity(stat.inProgress, locale),
            ),
            StatCard(
              label: l10n.dashboardReadyForPickup,
              value: formatQuantity(stat.readyForPickup, locale),
            ),
            StatCard(
              label: l10n.dashboardUnpaid,
              value: formatQuantity(stat.unpaidOrders, locale),
              details: [
                if (showAmount && amount != null) formatCurrency(amount),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
