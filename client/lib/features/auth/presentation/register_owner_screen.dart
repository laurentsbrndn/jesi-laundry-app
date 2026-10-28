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
import '../../../core/utils/upper_case_formatter.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import 'auth_controller.dart';
import 'setup_status_provider.dart';
import 'widgets/password_form_field.dart';

class RegisterOwnerScreen extends ConsumerStatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  ConsumerState<RegisterOwnerScreen> createState() =>
      _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends ConsumerState<RegisterOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _outletName = TextEditingController();
  final _outletCode = TextEditingController(text: 'JL');
  final _outletAddress = TextEditingController();
  final _outletPhone = TextEditingController();
  final _serverErrors = ServerFieldErrors();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _outletName.dispose();
    _outletCode.dispose();
    _outletAddress.dispose();
    _outletPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .registerOwner(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            outletName: _outletName.text,
            outletCode: _outletCode.text,
            outletAddress: _outletAddress.text,
            outletPhone: _outletPhone.text,
          );
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleError(Object error) {
    final l10n = context.l10n;
    final code = error is ApiException ? error.code : null;
    switch (code) {
      case ApiErrorCode.ownerAlreadyExists:
        ref.invalidate(setupStatusProvider);
        showAppSnackBar(context, l10n.errorOwnerAlreadyExists);
        context.go(AppRoutes.login);
        return;
      case ApiErrorCode.emailTaken:
        _serverErrors.replace({
          normalizeFieldName('email'): l10n.errorEmailTaken,
        });
        _formKey.currentState!.validate();
      case ApiErrorCode.outletCodeTaken:
        _serverErrors.replace({
          normalizeFieldName('outlet_code'): l10n.errorOutletCodeTaken,
        });
        _formKey.currentState!.validate();
      case ApiErrorCode.validationError:
        _serverErrors.replace(fieldErrorMessages(context, error));
        _formKey.currentState!.validate();
        showAppSnackBar(context, errorMessage(context, error));
      default:
        showAppSnackBar(context, errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(setupStatusProvider, (_, next) {
      if (next.value == true) context.go(AppRoutes.login);
    });

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.registerOwnerTitle)),
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
                        Text(
                          l10n.registerOwnerAccountSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _name,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          validator: _serverErrors.wrap(
                            'name',
                            FormValidators.all([
                              FormValidators.required(l10n),
                              FormValidators.maxLength(l10n, 100),
                            ]),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.authNameLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          enabled: !_submitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          validator: _serverErrors.wrap(
                            'email',
                            FormValidators.email(l10n),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.authEmailLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PasswordFormField(
                          controller: _password,
                          label: l10n.authPasswordLabel,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: _serverErrors.wrap(
                            'password',
                            FormValidators.password(l10n),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PasswordFormField(
                          controller: _confirmPassword,
                          label: l10n.authConfirmPasswordLabel,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.confirmPassword(
                            l10n,
                            () => _password.text,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l10n.registerOwnerOutletSection,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _outletName,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: _serverErrors.wrap(
                            'outlet_name',
                            FormValidators.all([
                              FormValidators.required(l10n),
                              FormValidators.maxLength(l10n, 100),
                            ]),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.registerOwnerOutletNameLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _outletCode,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp('[A-Za-z0-9]'),
                            ),
                            const UpperCaseTextFormatter(),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          validator: _serverErrors.wrap(
                            'outlet_code',
                            FormValidators.outletCode(l10n),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.registerOwnerOutletCodeLabel,
                            helperText: l10n.registerOwnerOutletCodeHelper,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _outletAddress,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          validator: _serverErrors.wrap(
                            'outlet_address',
                            FormValidators.maxLength(l10n, 255),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.registerOwnerOutletAddressLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _outletPhone,
                          enabled: !_submitting,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: _serverErrors.wrap(
                            'outlet_phone',
                            FormValidators.maxLength(l10n, 20),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.registerOwnerOutletPhoneLabel,
                          ),
                        ),
                        const SizedBox(height: 24),
                        LoadingButton(
                          onPressed: _submit,
                          isLoading: _submitting,
                          child: Text(l10n.registerOwnerSubmit),
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
