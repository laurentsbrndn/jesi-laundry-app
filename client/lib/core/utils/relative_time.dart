import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import 'date_format.dart';

/// `Baru saja`, `5 menit lalu`, `3 hari lalu`; older than a week falls back to a date.
String formatRelativeTime(
  DateTime value,
  AppLocalizations l10n,
  Locale locale, {
  DateTime? now,
}) {
  final difference = (now ?? DateTime.now()).difference(value);
  if (difference.inMinutes < 1) return l10n.timeAgoJustNow;
  if (difference.inMinutes < 60) {
    return l10n.timeAgoMinutes(difference.inMinutes);
  }
  if (difference.inHours < 24) return l10n.timeAgoHours(difference.inHours);
  if (difference.inDays < 7) return l10n.timeAgoDays(difference.inDays);
  return formatDate(value, locale);
}
