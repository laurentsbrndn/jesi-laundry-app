import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/models/order_detail.dart';
import '../../data/models/order_status.dart';

/// The four order stages with the time each was reached, plus the estimate.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final currentRank = OrderStatus.values.indexOf(order.status);
    final estimated = order.estimatedDoneAt;
    final overdue =
        estimated != null &&
        !order.status.isFinished &&
        estimated.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in OrderStatus.values)
          _StageRow(
            label: stage.label(context),
            time: order.timeOf(stage),
            reached: OrderStatus.values.indexOf(stage) <= currentRank,
            isCurrent: stage == order.status,
            isLast: stage == OrderStatus.values.last,
            locale: locale,
          ),
        if (estimated != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.ordersEstimatedDone(formatDateTime(estimated, locale)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: overdue ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.time,
    required this.reached,
    required this.isCurrent,
    required this.isLast,
    required this.locale,
  });

  final String label;
  final DateTime? time;
  final bool reached;
  final bool isCurrent;
  final bool isLast;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = reached ? scheme.primary : scheme.outlineVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  reached ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: color,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : null,
                    ),
                  ),
                  if (time != null)
                    Text(
                      formatDateTime(time!, locale),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
