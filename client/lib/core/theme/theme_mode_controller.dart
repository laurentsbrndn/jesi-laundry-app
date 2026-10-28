import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_storage.dart';
import 'app_theme_preference.dart';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, AppThemePreference>(
      ThemeModeController.new,
    );

class ThemeModeController extends Notifier<AppThemePreference> {
  @override
  AppThemePreference build() =>
      ref.watch(preferencesStorageProvider).readTheme();

  Future<void> setPreference(AppThemePreference value) async {
    state = value;
    await ref.read(preferencesStorageProvider).writeTheme(value);
  }
}
