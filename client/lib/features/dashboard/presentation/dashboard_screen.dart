import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/loading_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';

// PLACEHOLDER (F2): temporary screen so a signed-in user has somewhere to land
// and a way to sign out. Replaced by the real dashboard in F3/F6.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.dashboardPlaceholderLogoutConfirmTitle,
      message: l10n.dashboardPlaceholderLogoutConfirmBody,
      confirmLabel: l10n.dashboardPlaceholderLogout,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider).value;
    final user = auth is Authenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardPlaceholderTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                Text(user.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(user.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(
                  '${l10n.dashboardPlaceholderRoleLabel}: ${user.role.label(context)}',
                ),
                if (user.outlet != null)
                  Text(
                    '${l10n.dashboardPlaceholderOutletLabel}: ${user.outlet!.code} · ${user.outlet!.name}',
                  ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.dashboardPlaceholderNotice,
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              LoadingButton(
                onPressed: _logout,
                isLoading: _loggingOut,
                child: Text(l10n.dashboardPlaceholderLogout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
