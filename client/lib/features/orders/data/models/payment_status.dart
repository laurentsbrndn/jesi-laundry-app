import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

enum PaymentStatus {
  unpaid('unpaid'),
  paid('paid');

  const PaymentStatus(this.value);

  final String value;

  bool get isPaid => this == paid;

  /// An unknown value is treated as [unpaid].
  static PaymentStatus fromValue(String? value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      PaymentStatus.unpaid => l10n.paymentStatusUnpaid,
      PaymentStatus.paid => l10n.paymentStatusPaid,
    };
  }
}
