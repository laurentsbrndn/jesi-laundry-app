import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../../catalog/data/models/pricing_unit.dart';
import '../../data/models/order_detail.dart';
import '../../data/models/order_item.dart';

/// `2,5 kg · ditagih 3 kg`, `2 × 2,5 m = 5 m²`, `1 pcs`.
String describeOrderItemQuantity(
  OrderItem item,
  AppLocalizations l10n,
  Locale locale,
) {
  String number(num value) => formatQuantity(value, locale);
  final unit = switch (item.pricingUnit) {
    PricingUnit.kg => l10n.unitKg,
    PricingUnit.piece => l10n.unitPcs,
    PricingUnit.sqm => l10n.unitSqm,
  };
  final base =
      item.pricingUnit == PricingUnit.sqm &&
          item.lengthM != null &&
          item.widthM != null
      ? l10n.orderItemDimensions(
          number(item.lengthM!),
          number(item.widthM!),
          number(item.quantity),
        )
      : '${number(item.quantity)} $unit';
  if ((item.billedQuantity - item.quantity).abs() < 0.005) return base;
  return '$base · ${l10n.orderItemBilled(number(item.billedQuantity), unit)}';
}

/// Order lines with unit price and subtotal, and the total at the bottom.
class OrderItemsTable extends StatelessWidget {
  const OrderItemsTable({super.key, required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      children: [
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.serviceName, style: theme.textTheme.bodyLarge),
                      Text(
                        describeOrderItemQuantity(item, l10n, locale),
                        style: muted,
                      ),
                      Text(
                        '${formatCurrency(item.unitPrice)} / ${switch (item.pricingUnit) {
                          PricingUnit.kg => l10n.unitKg,
                          PricingUnit.piece => l10n.unitPcs,
                          PricingUnit.sqm => l10n.unitSqm,
                        }}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatCurrency(item.subtotal),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.orderDetailTotal,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              formatCurrency(order.totalAmount),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
