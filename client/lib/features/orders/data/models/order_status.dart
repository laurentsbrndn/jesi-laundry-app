import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

enum OrderStatus {
  received('received'),
  processing('processing'),
  done('done'),
  pickedUp('picked_up');

  const OrderStatus(this.value);

  final String value;

  /// The next stage, or null once picked up.
  OrderStatus? get next {
    final index = OrderStatus.values.indexOf(this);
    return index + 1 < OrderStatus.values.length
        ? OrderStatus.values[index + 1]
        : null;
  }

  /// Stages before this one, oldest first (targets for an owner's correction).
  List<OrderStatus> get previous =>
      OrderStatus.values.sublist(0, OrderStatus.values.indexOf(this));

  /// Done or picked up: no longer waiting for the laundry to finish.
  bool get isFinished => this == done || this == pickedUp;

  /// An unknown value is treated as [received].
  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.received,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      OrderStatus.received => l10n.orderStatusReceived,
      OrderStatus.processing => l10n.orderStatusProcessing,
      OrderStatus.done => l10n.orderStatusDone,
      OrderStatus.pickedUp => l10n.orderStatusPickedUp,
    };
  }
}
