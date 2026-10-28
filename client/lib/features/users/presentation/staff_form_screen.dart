import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/utils/form_error_handler.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_button.dart';
import '../../auth/data/models/app_user.dart';
import '../../auth/presentation/widgets/password_form_field.dart';
import '../../outlets/presentation/outlets_provider.dart';
import '../../outlets/presentation/widgets/outlet_picker_field.dart';
import 'staff_list_controller.dart';

/// Add ([userId] null) or edit a staff member.
class StaffFormScreen extends ConsumerWidget {
  const StaffFormScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = userId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staffFormAddTitle)),
        body: const _StaffForm(user: null),
      );
    }

    final detail = ref.watch(staffDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffFormEditTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(staffDetailProvider(id)),
        ),
        data: (user) => _StaffForm(user: user),
      ),
    );
  }
}

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({required this.user});

  final AppUser? user;

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _serverErrors = ServerFieldErrors();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  String? _outletId;
  late bool _isActive;
  bool _saving = false;

  AppUser? get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _user?.name ?? '');
    _email = TextEditingController(text: _user?.email ?? '');
    _outletId = _user?.outlet?.id;
    _isActive = _user?.isActive ?? true;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _outletChanged => _user != null && _outletId != _user!.outlet?.id;

  /// Edit mode: only changed fields; `outlet_id` only when it changed.
  Map<String, Object?> _changes() {
    final user = _user!;
    return {
      if (_name.text.trim() != user.name) 'name': _name.text.trim(),
      if (_outletChanged) 'outlet_id': _outletId,
      if (_isActive != user.isActive) 'is_active': _isActive,
    };
  }

  bool get _hasChanges => _user == null || _changes().isNotEmpty;

  Future<void> _save() async {
    if (_saving) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final user = _user;

    if (user != null && ((user.isActive && !_isActive) || _outletChanged)) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.staffSessionEndsTitle,
        message: l10n.staffSessionEndsBody,
        confirmLabel: l10n.commonContinue,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(userRepositoryProvider);
      if (user == null) {
        await repository.create(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          outletId: _outletId!,
        );
      } else {
        await repository.update(user.id, _changes());
        ref.invalidate(staffDetailProvider(user.id));
      }
      ref.invalidate(staffListControllerProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = user == null
          ? l10n.staffFormCreated
          : l10n.staffFormSaved;
      context.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) {
        showFormError(
          context,
          e,
          serverErrors: _serverErrors,
          formKey: _formKey,
          codeFields: {ApiErrorCode.emailTaken: 'email'},
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final user = _user!;
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _ResetPasswordDialog(),
    );
    if (password == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).resetPassword(user.id, password);
      if (mounted) {
        showAppSnackBar(context, context.l10n.staffResetPasswordDone);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = _user != null;
    // Make sure outlets are loaded for the picker.
    ref.watch(outletsProvider);

    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: _serverErrors.wrap(
                    'name',
                    FormValidators.all([
                      FormValidators.required(l10n),
                      FormValidators.maxLength(l10n, 100),
                    ]),
                  ),
                  decoration: InputDecoration(labelText: l10n.authNameLabel),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  enabled: !_saving && !isEdit,
                  readOnly: isEdit,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: isEdit
                      ? null
                      : _serverErrors.wrap('email', FormValidators.email(l10n)),
                  decoration: InputDecoration(labelText: l10n.authEmailLabel),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 16),
                  PasswordFormField(
                    controller: _password,
                    label: l10n.authPasswordLabel,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    validator: _serverErrors.wrap(
                      'password',
                      FormValidators.password(l10n),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutletPickerField(
                  value: _outletId,
                  currentOutletId: _user?.outlet?.id,
                  enabled: !_saving,
                  onChanged: (id) => setState(() => _outletId = id),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.commonActive),
                    value: _isActive,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _isActive = value),
                  ),
                ],
                const SizedBox(height: 16),
                LoadingButton(
                  onPressed: _hasChanges ? _save : null,
                  isLoading: _saving,
                  child: Text(l10n.commonSave),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _resetPassword,
                    icon: const Icon(Icons.lock_reset),
                    label: Text(l10n.staffResetPassword),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks the owner for a new password and returns it, or null if cancelled.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog();

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.staffResetPasswordTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.staffResetPasswordBody),
              const SizedBox(height: 16),
              PasswordFormField(
                controller: _password,
                label: l10n.authNewPasswordLabel,
                textInputAction: TextInputAction.next,
                validator: FormValidators.password(l10n),
              ),
              const SizedBox(height: 16),
              PasswordFormField(
                controller: _confirm,
                label: l10n.authConfirmPasswordLabel,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: FormValidators.confirmPassword(
                  l10n,
                  () => _password.text,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.staffResetPassword)),
      ],
    );
  }
}
