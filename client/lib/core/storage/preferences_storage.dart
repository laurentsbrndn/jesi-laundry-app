import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language_preference.dart';
import '../theme/app_theme_preference.dart';

/// Overridden in `main.dart` with the instance created at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => PreferencesStorage(ref.watch(sharedPreferencesProvider)),
);

class PreferencesStorage {
  PreferencesStorage(this._prefs);

  static const _themeKey = 'theme_preference';
  static const _languageKey = 'language_preference';

  final SharedPreferences _prefs;

  AppThemePreference readTheme() =>
      AppThemePreference.fromValue(_prefs.getString(_themeKey));

  Future<void> writeTheme(AppThemePreference value) =>
      _prefs.setString(_themeKey, value.value);

  AppLanguagePreference readLanguage() =>
      AppLanguagePreference.fromValue(_prefs.getString(_languageKey));

  Future<void> writeLanguage(AppLanguagePreference value) =>
      _prefs.setString(_languageKey, value.value);
}
