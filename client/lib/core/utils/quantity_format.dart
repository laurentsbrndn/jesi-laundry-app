import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Up to 2 decimals, no trailing zeros: `3`, `2,5` (id) / `2.5` (en).
String formatQuantity(num value, Locale locale) {
  return NumberFormat('#,##0.##', locale.languageCode).format(value);
}

/// `2,5 kg`. [unitLabel] comes from the localized unit strings.
String formatQuantityWithUnit(num value, String unitLabel, Locale locale) {
  return '${formatQuantity(value, locale)} $unitLabel';
}
