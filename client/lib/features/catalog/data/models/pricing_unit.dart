import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

enum PricingUnit {
  kg('kg'),
  piece('piece'),
  sqm('sqm');

  const PricingUnit(this.value);

  final String value;

  static PricingUnit fromValue(String? value) {
    return PricingUnit.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PricingUnit.kg,
    );
  }

  /// `kg`, `pcs` or `m²`.
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      PricingUnit.kg => l10n.unitKg,
      PricingUnit.piece => l10n.unitPcs,
      PricingUnit.sqm => l10n.unitSqm,
    };
  }
}
