import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../data/models/order_detail.dart';
import '../../data/models/order_status.dart';

/// Bottom bar of the order detail: next-stage button, "mark paid", and the
/// owner-only overflow menu.
class OrderActionsBar extends StatelessWidget {
  const OrderActionsBar({
    super.key,
    required this.order,
    required this.isOwner,
    required this.busy,
    required this.onAdvance,
    required this.onMarkPaid,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onUnpay,
    required this.onDelete,
  });

  final OrderDetail order;
  final bool isOwner;

  /// A request is running; every action is disabled.
  final bool busy;
  final VoidCallback onAdvance;
  final VoidCallback onMarkPaid;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onUnpay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final next = order.status.next;
    final nextLabel = switch (next) {
      OrderStatus.processing => l10n.orderActionStart,
      OrderStatus.done => l10n.orderActionFinish,
      OrderStatus.pickedUp => l10n.orderActionPickUp,
      _ => null,
    };
    final canUnpay =
        order.paymentStatus.isPaid && order.status != OrderStatus.pickedUp;

    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              if (!order.paymentStatus.isPaid)
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onMarkPaid,
                    child: Text(l10n.orderActionMarkPaid),
                  ),
                ),
              if (!order.paymentStatus.isPaid && nextLabel != null)
                const SizedBox(width: 8),
              if (nextLabel != null)
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onAdvance,
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(nextLabel),
                  ),
                ),
              if (nextLabel == null && order.paymentStatus.isPaid)
                const Spacer(),
              if (isOwner)
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: l10n.orderActionsMenu,
                  onSelected: (value) => switch (value) {
                    'edit' => onEdit(),
                    'status' => onChangeStatus(),
                    'unpay' => onUnpay(),
                    _ => onDelete(),
                  },
                  itemBuilder: (context) => [
                    if (order.isEditable)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.orderActionEdit),
                      ),
                    if (order.status.previous.isNotEmpty)
                      PopupMenuItem(
                        value: 'status',
                        child: Text(l10n.orderActionChangeStatus),
                      ),
                    if (canUnpay)
                      PopupMenuItem(
                        value: 'unpay',
                        child: Text(l10n.orderActionUnpay),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.orderActionDelete),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
