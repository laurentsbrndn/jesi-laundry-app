import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/order_status.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StatusColors>()!;
    final pair = switch (status) {
      OrderStatus.received => colors.received,
      OrderStatus.processing => colors.processing,
      OrderStatus.done => colors.done,
      OrderStatus.pickedUp => colors.pickedUp,
    };
    return StatusPill(label: status.label(context), colors: pair);
  }
}

/// Small rounded label in a status color pair.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.colors});

  final String label;
  final StatusColorPair colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colors.foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
