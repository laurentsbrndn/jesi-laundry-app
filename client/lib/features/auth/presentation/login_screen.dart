import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import 'auth_controller.dart';
import 'session_expired_notice.dart';
import 'setup_status_provider.dart';
import 'widgets/password_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showExpiredNotice());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showExpiredNotice() {
    if (!mounted || !ref.read(sessionExpiredNoticeProvider)) return;
    ref.read(sessionExpiredNoticeProvider.notifier).consume();
    showAppSnackBar(context, context.l10n.loginSessionExpired);
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text, _password.text);
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    ref.listen(sessionExpiredNoticeProvider, (_, raised) {
      if (raised) _showExpiredNotice();
    });
    // The register button needs a confirmed `owner_exists = false`; on failure
    // it stays hidden and login is not blocked.
    final canRegister = ref.watch(setupStatusProvider).value == false;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.local_laundry_service,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.appName,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _email,
                          enabled: !_submitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          validator: FormValidators.email(l10n),
                          decoration: InputDecoration(
                            labelText: l10n.authEmailLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PasswordFormField(
                          controller: _password,
                          label: l10n.authPasswordLabel,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          validator: FormValidators.required(l10n),
                        ),
                        const SizedBox(height: 24),
                        LoadingButton(
                          onPressed: _submit,
                          isLoading: _submitting,
                          child: Text(l10n.loginSubmit),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          child: Text(l10n.loginForgotPassword),
                        ),
                        if (canRegister)
                          OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => context.push(AppRoutes.registerOwner),
                            child: Text(l10n.loginRegisterOwner),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
