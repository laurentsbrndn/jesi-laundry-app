import 'package:material_ui/material_ui.dart';

import '../l10n/l10n_extension.dart';

enum AppThemePreference {
  system('system', ThemeMode.system),
  light('light', ThemeMode.light),
  dark('dark', ThemeMode.dark);

  const AppThemePreference(this.value, this.themeMode);

  final String value;
  final ThemeMode themeMode;

  static AppThemePreference fromValue(String? value) {
    return AppThemePreference.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppThemePreference.system,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AppThemePreference.system => l10n.themeSystem,
      AppThemePreference.light => l10n.themeLight,
      AppThemePreference.dark => l10n.themeDark,
    };
  }
}
