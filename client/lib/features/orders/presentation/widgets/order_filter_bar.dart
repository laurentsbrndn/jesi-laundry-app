import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../data/models/order_status.dart';
import '../../data/models/payment_status.dart';

/// Single-choice chips for order status and payment status. Null = all.
class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({
    super.key,
    required this.status,
    required this.payment,
    required this.onStatusChanged,
    required this.onPaymentChanged,
  });

  final OrderStatus? status;
  final PaymentStatus? payment;
  final ValueChanged<OrderStatus?> onStatusChanged;
  final ValueChanged<PaymentStatus?> onPaymentChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _ChipRow(
          children: [
            ChoiceChip(
              label: Text(l10n.ordersFilterAll),
              selected: status == null,
              onSelected: (_) => onStatusChanged(null),
            ),
            for (final value in OrderStatus.values)
              ChoiceChip(
                label: Text(value.label(context)),
                selected: status == value,
                onSelected: (_) => onStatusChanged(value),
              ),
          ],
        ),
        _ChipRow(
          children: [
            ChoiceChip(
              label: Text(l10n.ordersFilterAll),
              selected: payment == null,
              onSelected: (_) => onPaymentChanged(null),
            ),
            for (final value in PaymentStatus.values)
              ChoiceChip(
                label: Text(value.label(context)),
                selected: payment == value,
                onSelected: (_) => onPaymentChanged(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final chip in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }
}
