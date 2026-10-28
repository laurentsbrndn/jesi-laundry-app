import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

enum ServiceCategory {
  washIron('wash_iron'),
  ironOnly('iron_only'),
  washFold('wash_fold'),
  unit('unit');

  const ServiceCategory(this.value);

  final String value;

  /// The three per-kilo categories.
  bool get isKilo => this != ServiceCategory.unit;

  /// An unknown value is treated as a unit service.
  static ServiceCategory fromValue(String? value) {
    return ServiceCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceCategory.unit,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      ServiceCategory.washIron => l10n.serviceCategoryWashIron,
      ServiceCategory.ironOnly => l10n.serviceCategoryIronOnly,
      ServiceCategory.washFold => l10n.serviceCategoryWashFold,
      ServiceCategory.unit => l10n.serviceCategoryUnit,
    };
  }
}
