import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/widgets/password_form_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _serverErrors = ServerFieldErrors();
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      // The server revoked every old refresh token; keep the new session or the
      // next refresh would fail and sign the user out.
      await ref.read(authControllerProvider.notifier).applySession(session);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = context.l10n.changePasswordSuccess;
      context.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleError(Object error) {
    if (error is ApiException &&
        error.code == ApiErrorCode.invalidCredentials) {
      // Wrong current password: a field error, not a session problem.
      _serverErrors.replace({
        normalizeFieldName('current_password'):
            context.l10n.changePasswordCurrentWrong,
      });
      _formKey.currentState!.validate();
      return;
    }
    _serverErrors.replace(fieldErrorMessages(context, error));
    _formKey.currentState!.validate();
    showAppSnackBar(context, errorMessage(context, error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.changePasswordTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PasswordFormField(
                    controller: _current,
                    label: l10n.changePasswordCurrentLabel,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    validator: _serverErrors.wrap(
                      'current_password',
                      FormValidators.required(l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PasswordFormField(
                    controller: _new,
                    label: l10n.authNewPasswordLabel,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _serverErrors.wrap(
                      'new_password',
                      FormValidators.password(l10n),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PasswordFormField(
                    controller: _confirm,
                    label: l10n.authConfirmPasswordLabel,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: FormValidators.confirmPassword(
                      l10n,
                      () => _new.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoadingButton(
                    onPressed: _submit,
                    isLoading: _submitting,
                    child: Text(l10n.changePasswordSubmit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
