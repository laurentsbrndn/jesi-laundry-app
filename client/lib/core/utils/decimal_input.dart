import 'package:flutter/services.dart';

/// Parses user input such as `2,5` or `2.5`. Returns null when not a valid number.
double? parseDecimal(String input) {
  final text = input.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

/// Accepts digits and one `,` or `.` separator, with at most 2 decimals.
class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter();

  static final RegExp _pattern = RegExp(r'^\d*([.,]\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
