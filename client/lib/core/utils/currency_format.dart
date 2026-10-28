import 'package:intl/intl.dart';

final NumberFormat _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// Rupiah amount as `Rp 12.000`, regardless of the app language.
String formatCurrency(int amount) => _currency.format(amount);
