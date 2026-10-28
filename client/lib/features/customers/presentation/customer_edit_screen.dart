import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/utils/form_error_handler.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_button.dart';
import '../data/models/customer.dart';
import 'customers_list_controller.dart';

/// Edit a customer's name and phone. Customers are only created through orders.
class CustomerEditScreen extends ConsumerWidget {
  const CustomerEditScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(customerDetailProvider(customerId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.customerEditTitle)),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
        data: (customer) => _CustomerForm(customer: customer),
      ),
    );
  }
}

class _CustomerForm extends ConsumerStatefulWidget {
  const _CustomerForm({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _serverErrors = ServerFieldErrors();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer.name);
    _phone = TextEditingController(text: widget.customer.phone ?? '');
    _name.addListener(() => setState(() {}));
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Only changed fields. A cleared phone is sent as an empty string.
  Map<String, Object?> _changes() {
    final customer = widget.customer;
    return {
      if (_name.text.trim() != customer.name) 'name': _name.text.trim(),
      if (_phone.text.trim() != (customer.phone ?? ''))
        'phone': _phone.text.trim(),
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(customerRepositoryProvider)
          .update(widget.customer.id, _changes());
      ref.invalidate(customerDetailProvider(widget.customer.id));
      ref.invalidate(customersListControllerProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = context.l10n.customerEditSaved;
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
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: _serverErrors.wrap(
                    'phone',
                    FormValidators.maxLength(l10n, 20),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.customerEditPhoneLabel,
                  ),
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  onPressed: _changes().isNotEmpty ? _save : null,
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
