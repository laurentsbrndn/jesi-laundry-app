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

/// Parses `2,5` / `2.5` into hundredths (250) without floating point. Returns
/// null for empty or malformed input or more than 2 decimals.
int? parseHundredths(String input) {
  final match = RegExp(r'^(\d+)(?:[.,](\d{0,2}))?$').firstMatch(input.trim());
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

/// Hundredths back to an input string: 250 -> `2.5`, 300 -> `3`.
String hundredthsToInput(int value100) {
  final whole = value100 ~/ 100;
  final fraction = value100 % 100;
  if (fraction == 0) return '$whole';
  final text = fraction
      .toString()
      .padLeft(2, '0')
      .replaceFirst(RegExp(r'0$'), '');
  return '$whole.$text';
}
