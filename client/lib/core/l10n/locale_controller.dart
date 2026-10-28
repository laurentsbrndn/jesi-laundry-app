import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../storage/preferences_storage.dart';
import 'app_language_preference.dart';

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLanguagePreference>(
      LocaleController.new,
    );

/// Picks `id` or `en` for [locale]; anything else falls back to `id`.
Locale resolveAppLocale(Locale? locale, Iterable<Locale> supported) {
  for (final candidate in supported) {
    if (candidate.languageCode == locale?.languageCode) return candidate;
  }
  return const Locale('id');
}

class LocaleController extends Notifier<AppLanguagePreference> {
  @override
  AppLanguagePreference build() =>
      ref.watch(preferencesStorageProvider).readLanguage();

  Future<void> setPreference(AppLanguagePreference value) async {
    state = value;
    await ref.read(preferencesStorageProvider).writeLanguage(value);
  }

  /// `id` or `en`, as sent in `Accept-Language`.
  String get resolvedLanguageCode {
    final explicit = state.locale;
    if (explicit != null) return explicit.languageCode;
    return PlatformDispatcher.instance.locale.languageCode == 'en'
        ? 'en'
        : 'id';
  }
}
