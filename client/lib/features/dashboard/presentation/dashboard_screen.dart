import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';

// PLACEHOLDER (F2/F3): temporary marker of the signed-in user. Replaced by the
// real dashboard in F6. Sign out lives in Settings.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ],
          ),
        ),
      ),
    );
  }
}
