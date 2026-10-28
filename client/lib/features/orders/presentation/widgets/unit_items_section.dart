import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../../catalog/data/models/laundry_service.dart';
import '../../../catalog/data/models/pricing_unit.dart';
import '../../data/models/order_draft_item.dart';
import '../order_pricing_preview.dart';

/// The unit (pcs / m²) lines of the form, with add, edit and remove.
class UnitItemsSection extends StatelessWidget {
  const UnitItemsSection({
    super.key,
    required this.items,
    required this.servicesById,
    required this.preview,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    this.enabled = true,
  });

  final List<OrderDraftItem> items;
  final Map<String, LaundryService> servicesById;
  final OrderPreview preview;
  final VoidCallback onAdd;
  final void Function(OrderDraftItem item) onEdit;
  final void Function(OrderDraftItem item) onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    String describe(OrderDraftItem item) {
      String number(int value100) => formatQuantity(value100 / 100, locale);
      if (item.unit == PricingUnit.sqm) {
        final length = item.length100 ?? 0;
        final width = item.width100 ?? 0;
        return l10n.orderItemDimensions(
          number(length),
          number(width),
          number(areaHundredths(length, width)),
        );
      }
      return '${number(item.quantity100 ?? 0)} ${l10n.unitPcs}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.serviceName),
              subtitle: Text(describe(item)),
              onTap: enabled && servicesById[item.serviceId] != null
                  ? () => onEdit(item)
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview.lines[item.uid]?.isValid ?? false)
                    Text(
                      formatCurrency(preview.lines[item.uid]!.subtotal),
                      style: theme.textTheme.bodyMedium,
                    ),
                  IconButton(
                    tooltip: l10n.orderFormRemoveItem,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: enabled ? () => onRemove(item) : null,
                  ),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: enabled ? onAdd : null,
          icon: const Icon(Icons.add),
          label: Text(l10n.orderFormAddUnitItem),
        ),
      ],
    );
  }
}
