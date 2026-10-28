import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/quantity_format.dart';
import '../../../orders/data/models/order_status.dart';
import '../../../orders/presentation/widgets/order_status_chip.dart';
import '../../data/models/status_stat.dart';

/// Order count per current status, all four always shown.
class StatusBreakdown extends StatelessWidget {
  const StatusBreakdown({super.key, required this.stats});

  final List<StatusStat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    int countFor(OrderStatus status) =>
        stats.where((s) => s.status == status).firstOrNull?.orders ?? 0;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        for (final status in OrderStatus.values)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              OrderStatusChip(status: status),
              const SizedBox(height: 4),
              Text(
                formatQuantity(countFor(status), locale),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
      ],
    );
  }
}
