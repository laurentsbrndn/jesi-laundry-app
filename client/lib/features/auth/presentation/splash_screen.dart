import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/error_view.dart';
import 'auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _slowAfter = Duration(seconds: 6);

  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _startSlowTimer();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  void _startSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = Timer(_slowAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  void _retry() {
    setState(() => _slow = false);
    _startSlowTimer();
    ref.invalidate(authControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    if (auth.hasError && !auth.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: ErrorView(error: auth.error!, onRetry: _retry),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_laundry_service,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(context.l10n.appName, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              if (_slow) ...[
                const SizedBox(height: 24),
                Text(
                  context.l10n.splashSlowHint,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
