import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import 'auth_providers.dart';
import 'reset_password_args.dart';
import 'widgets/password_form_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.args});

  final ResetPasswordArgs args;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _serverErrors = ServerFieldErrors();
  Timer? _timer;
  late int _secondsLeft = widget.args.retryAfterSeconds;
  bool _submitting = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    if (_secondsLeft <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resending || _submitting || _secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      final retryAfter = await ref
          .read(authRepositoryProvider)
          .forgotPassword(widget.args.email);
      if (!mounted) return;
      _secondsLeft = retryAfter;
      _startCountdown();
      showAppSnackBar(context, context.l10n.resetPasswordResent);
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: widget.args.email,
            otp: _otp.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = context.l10n.resetPasswordSuccess;
      context.go(AppRoutes.login);
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
    final code = error is ApiException ? error.code : null;
    if (code == ApiErrorCode.otpInvalid ||
        code == ApiErrorCode.otpExpired ||
        code == ApiErrorCode.otpTooManyAttempts) {
      _serverErrors.replace({
        normalizeFieldName('otp'): errorMessage(context, error),
      });
      _formKey.currentState!.validate();
      return;
    }
    if (code == ApiErrorCode.validationError) {
      _serverErrors.replace(fieldErrorMessages(context, error));
      _formKey.currentState!.validate();
    }
    showAppSnackBar(context, errorMessage(context, error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = _submitting || _resending;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
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
                        l10n.resetPasswordBody(widget.args.email),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _otp,
                        enabled: !_submitting,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: _serverErrors.wrap(
                          'otp',
                          FormValidators.otp(l10n),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.resetPasswordOtpLabel,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: busy || _secondsLeft > 0 ? null : _resend,
                          child: Text(
                            _secondsLeft > 0
                                ? l10n.resetPasswordResendIn(_secondsLeft)
                                : l10n.resetPasswordResend,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PasswordFormField(
                        controller: _password,
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
                        controller: _confirmPassword,
                        label: l10n.authConfirmPasswordLabel,
                        enabled: !_submitting,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: FormValidators.confirmPassword(
                          l10n,
                          () => _password.text,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        onPressed: _submit,
                        isLoading: _submitting,
                        child: Text(l10n.resetPasswordSubmit),
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
