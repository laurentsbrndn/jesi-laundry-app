import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/config_error_app.dart';
import 'core/storage/preferences_storage.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (!AppConfig.isUsable) {
    runApp(ConfigErrorApp(insecure: AppConfig.isConfigured));
    return;
  }

  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(const FlutterSecureStorage(), prefs);
  // Must finish before the auth controller reads tokens (see TokenStorage).
  await tokenStorage.resetOnFreshInstall();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const JesiLaundryApp(),
    ),
  );
}
