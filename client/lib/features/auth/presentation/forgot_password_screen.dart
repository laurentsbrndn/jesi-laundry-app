import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import 'auth_providers.dart';
import 'reset_password_args.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _serverErrors = ServerFieldErrors();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final retryAfter = await ref
          .read(authRepositoryProvider)
          .forgotPassword(_email.text);
      if (!mounted) return;
      context.push(
        AppRoutes.resetPassword,
        extra: ResetPasswordArgs(
          email: _email.text.trim().toLowerCase(),
          retryAfterSeconds: retryAfter,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _serverErrors.replace(fieldErrorMessages(context, e));
      _formKey.currentState!.validate();
      showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.forgotPasswordBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _email,
                        enabled: !_submitting,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        onFieldSubmitted: (_) => _submit(),
                        validator: _serverErrors.wrap(
                          'email',
                          FormValidators.email(l10n),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.authEmailLabel,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        onPressed: _submit,
                        isLoading: _submitting,
                        child: Text(l10n.forgotPasswordSubmit),
                      ),
                    ],
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
