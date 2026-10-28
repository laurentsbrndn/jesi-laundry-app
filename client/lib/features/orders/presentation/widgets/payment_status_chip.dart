import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/payment_status.dart';
import 'order_status_chip.dart';

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<StatusColors>()!;
    return StatusPill(
      label: status.label(context),
      colors: status.isPaid ? colors.paid : colors.unpaid,
    );
  }
}
