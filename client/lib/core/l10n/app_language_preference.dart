import 'package:material_ui/material_ui.dart';

import 'l10n_extension.dart';

enum AppLanguagePreference {
  system('system', null),
  id('id', Locale('id')),
  en('en', Locale('en'));

  const AppLanguagePreference(this.value, this.locale);

  final String value;

  /// `null` means follow the device language.
  final Locale? locale;

  static AppLanguagePreference fromValue(String? value) {
    return AppLanguagePreference.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppLanguagePreference.system,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AppLanguagePreference.system => l10n.languageSystem,
      AppLanguagePreference.id => l10n.languageIndonesian,
      AppLanguagePreference.en => l10n.languageEnglish,
    };
  }
}
