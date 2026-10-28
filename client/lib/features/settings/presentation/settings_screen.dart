import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_language_preference.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme_preference.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import 'widgets/choice_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  Future<void> _pickTheme() async {
    final l10n = context.l10n;
    final picked = await showChoiceSheet<AppThemePreference>(
      context,
      title: l10n.settingsTheme,
      options: AppThemePreference.values,
      selected: ref.read(themeModeControllerProvider),
      labelOf: (option) => option.label(context),
    );
    if (picked != null) {
      await ref
          .read(themeModeControllerProvider.notifier)
          .setPreference(picked);
    }
  }

  Future<void> _pickLanguage() async {
    final l10n = context.l10n;
    final picked = await showChoiceSheet<AppLanguagePreference>(
      context,
      title: l10n.settingsLanguage,
      options: AppLanguagePreference.values,
      selected: ref.read(localeControllerProvider),
      labelOf: (option) => option.label(context),
    );
    if (picked != null) {
      await ref.read(localeControllerProvider.notifier).setPreference(picked);
    }
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsLogoutConfirmTitle,
      message: l10n.settingsLogoutConfirmBody,
      confirmLabel: l10n.settingsLogout,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      // The router sends the user to the login screen once signed out.
      await ref.read(authControllerProvider.notifier).logout();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider).value;
    final user = auth is Authenticated ? auth.user : null;
    final theme = ref.watch(themeModeControllerProvider);
    final language = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: l10n.settingsSectionAccount,
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.settingsProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsProfile),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.settingsChangePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsChangePassword),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: l10n.settingsSectionAppearance,
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: Text(l10n.settingsTheme),
                  subtitle: Text(theme.label(context)),
                  onTap: _pickTheme,
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.settingsLanguage),
                  subtitle: Text(language.label(context)),
                  onTap: _pickLanguage,
                ),
              ],
            ),
          ),
          if (user != null && user.isOwner) ...[
            const SizedBox(height: 12),
            // F4 replaces these disabled entries with real navigation.
            SectionCard(
              title: l10n.settingsSectionManage,
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Column(
                children: [
                  _ComingSoonTile(
                    icon: Icons.local_laundry_service_outlined,
                    title: l10n.settingsManageServices,
                  ),
                  _ComingSoonTile(
                    icon: Icons.people_outline,
                    title: l10n.settingsManageCustomers,
                  ),
                  _ComingSoonTile(
                    icon: Icons.badge_outlined,
                    title: l10n.settingsManageStaff,
                  ),
                  _ComingSoonTile(
                    icon: Icons.store_outlined,
                    title: l10n.settingsManageOutlets,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              enabled: !_loggingOut,
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.settingsLogout,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              trailing: _loggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(context.l10n.settingsComingSoon),
      onTap: null,
    );
  }
}
