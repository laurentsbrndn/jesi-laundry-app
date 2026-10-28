import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

enum ServiceSpeed {
  regular('regular'),
  express('express');

  const ServiceSpeed(this.value);

  final String value;

  static ServiceSpeed fromValue(String? value) {
    return ServiceSpeed.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceSpeed.regular,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ServiceSpeed.regular => l10n.serviceSpeedRegular,
      ServiceSpeed.express => l10n.serviceSpeedExpress,
    };
  }
}
