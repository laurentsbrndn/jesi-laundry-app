import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

bool _isEnglish(Locale locale) => locale.languageCode == 'en';

/// `27 Okt 2026` / `Oct 27, 2026`.
String formatDate(DateTime value, Locale locale) {
  final tag = locale.languageCode;
  return DateFormat.yMMMd(tag).format(value);
}

/// `15.12` / `3:12 PM`.
String formatTime(DateTime value, Locale locale) {
  final tag = locale.languageCode;
  return _isEnglish(locale)
      ? DateFormat.jm(tag).format(value)
      : DateFormat('HH.mm', tag).format(value);
}

/// `27 Okt 2026 15.12` / `Oct 27, 2026 3:12 PM`.
String formatDateTime(DateTime value, Locale locale) {
  return '${formatDate(value, locale)} ${formatTime(value, locale)}';
}
