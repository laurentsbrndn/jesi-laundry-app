import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_theme.dart';

/// Shown instead of the app when `API_BASE_URL` was not provided at build time.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, this.insecure = false});

  /// The address is set but is not HTTPS in a release build.
  final bool insecure;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: _ConfigErrorScreen(insecure: insecure),
    );
  }
}

class _ConfigErrorScreen extends StatelessWidget {
  const _ConfigErrorScreen({required this.insecure});

  final bool insecure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_suggest_outlined,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.configErrorTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  insecure
                      ? context.l10n.configErrorHttpsBody
                      : context.l10n.configErrorBody,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
