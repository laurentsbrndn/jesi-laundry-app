import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/l10n/l10n_extension.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'l10n/gen/app_localizations.dart';

class JesiLaundryApp extends ConsumerWidget {
  const JesiLaundryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(themeModeControllerProvider);
    final languagePreference = ref.watch(localeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themePreference.themeMode,
      locale: languagePreference.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      localeResolutionCallback: resolveAppLocale,
      routerConfig: router,
      builder: (context, child) {
        // Some dependencies (e.g. go_router) still use the SDK's legacy Material.
        // ignore: deprecated_member_use
        return MaterialUiCompatibilityBridge(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
