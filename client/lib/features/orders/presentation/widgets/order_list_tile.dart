import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/relative_time.dart';
import '../../data/models/order_list_item.dart';
import 'order_status_chip.dart';
import 'payment_status_chip.dart';

class OrderListTile extends StatelessWidget {
  const OrderListTile({super.key, required this.order, required this.onTap});

  final OrderListItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final estimated = order.estimatedDoneAt;
    final overdue =
        estimated != null &&
        !order.status.isFinished &&
        estimated.isBefore(DateTime.now());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatCurrency(order.totalAmount),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              order.customerName,
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                OrderStatusChip(status: order.status),
                PaymentStatusChip(status: order.paymentStatus),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (estimated != null)
                  Expanded(
                    child: Text(
                      l10n.ordersEstimatedDone(
                        formatDateTime(estimated, locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  formatRelativeTime(order.createdAt, l10n, locale),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
