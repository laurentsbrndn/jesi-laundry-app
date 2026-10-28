import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/form_error_handler.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/utils/upper_case_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_button.dart';
import '../data/models/outlet.dart';
import 'outlets_provider.dart';

/// Add ([outletId] null) or edit an outlet.
class OutletFormScreen extends ConsumerWidget {
  const OutletFormScreen({super.key, this.outletId});

  final String? outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = outletId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.outletFormAddTitle)),
        body: const _OutletForm(outlet: null),
      );
    }

    final outlets = ref.watch(outletsProvider);
    final outlet = outlets.value?.where((o) => o.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.outletFormEditTitle)),
      body: outlet != null
          ? _OutletForm(outlet: outlet)
          : outlets.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(outletsProvider),
              ),
              data: (_) => ErrorView(
                error: const ApiException(code: ApiErrorCode.notFound),
                onRetry: () => context.pop(),
              ),
            ),
    );
  }
}

class _OutletForm extends ConsumerStatefulWidget {
  const _OutletForm({required this.outlet});

  final Outlet? outlet;

  @override
  ConsumerState<_OutletForm> createState() => _OutletFormState();
}

class _OutletFormState extends ConsumerState<_OutletForm> {
  final _formKey = GlobalKey<FormState>();
  final _serverErrors = ServerFieldErrors();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late bool _isActive;
  bool _saving = false;

  Outlet? get _outlet => widget.outlet;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: _outlet?.code ?? '');
    _name = TextEditingController(text: _outlet?.name ?? '');
    _address = TextEditingController(text: _outlet?.address ?? '');
    _phone = TextEditingController(text: _outlet?.phone ?? '');
    _isActive = _outlet?.isActive ?? true;
    for (final c in [_code, _name, _address, _phone]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Edit mode: only the fields that differ from the loaded outlet.
  Map<String, Object?> _changes() {
    final outlet = _outlet!;
    return {
      if (_name.text.trim() != outlet.name) 'name': _name.text.trim(),
      if (_address.text.trim() != (outlet.address ?? ''))
        'address': _address.text.trim(),
      if (_phone.text.trim() != (outlet.phone ?? ''))
        'phone': _phone.text.trim(),
      if (_isActive != outlet.isActive) 'is_active': _isActive,
    };
  }

  bool get _hasChanges => _outlet == null || _changes().isNotEmpty;

  Future<void> _save() async {
    if (_saving) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final outlet = _outlet;

    if (outlet != null && outlet.isActive && !_isActive) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.outletDeactivateTitle,
        message: l10n.outletDeactivateBody,
        confirmLabel: l10n.outletDeactivateConfirm,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(outletRepositoryProvider);
      if (outlet == null) {
        await repository.create(
          code: _code.text,
          name: _name.text,
          address: _address.text,
          phone: _phone.text,
        );
      } else {
        await repository.update(outlet.id, _changes());
      }
      ref.invalidate(outletsProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = outlet == null
          ? l10n.outletFormCreated
          : l10n.outletFormSaved;
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
          codeFields: {ApiErrorCode.outletCodeTaken: 'code'},
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = _outlet != null;
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
                  controller: _code,
                  enabled: !_saving && !isEdit,
                  readOnly: isEdit,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    const UpperCaseTextFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: isEdit
                      ? null
                      : _serverErrors.wrap(
                          'code',
                          FormValidators.outletCode(l10n),
                        ),
                  decoration: InputDecoration(
                    labelText: l10n.registerOwnerOutletCodeLabel,
                    helperText: isEdit
                        ? l10n.outletFormCodeLocked
                        : l10n.registerOwnerOutletCodeHelper,
                  ),
                ),
                const SizedBox(height: 16),
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
                  decoration: InputDecoration(
                    labelText: l10n.registerOwnerOutletNameLabel,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  validator: _serverErrors.wrap(
                    'address',
                    FormValidators.maxLength(l10n, 255),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.outletFormAddressLabel,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: _serverErrors.wrap(
                    'phone',
                    FormValidators.maxLength(l10n, 20),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.outletFormPhoneLabel,
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
