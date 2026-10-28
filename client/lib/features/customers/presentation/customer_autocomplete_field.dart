import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/utils/form_validators.dart';
import '../data/models/customer.dart';
import 'customers_list_controller.dart';

/// Customer picker for the order form. Typing searches existing customers
/// (debounced); the last option starts a new customer, which reveals a phone
/// field. A picked customer is read-only with a "change" button.
class CustomerAutocompleteField extends ConsumerStatefulWidget {
  const CustomerAutocompleteField({
    super.key,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.onSelectExisting,
    required this.onNewCustomer,
    this.enabled = true,
  });

  /// Non-null when an existing customer is picked.
  final String? customerId;
  final String name;
  final String phone;
  final void Function(Customer customer) onSelectExisting;
  final void Function(String name, String phone) onNewCustomer;
  final bool enabled;

  @override
  ConsumerState<CustomerAutocompleteField> createState() =>
      _CustomerAutocompleteFieldState();
}

class _CustomerAutocompleteFieldState
    extends ConsumerState<CustomerAutocompleteField> {
  static const _debounce = Duration(milliseconds: 300);

  late final TextEditingController _name;
  late final TextEditingController _phone;
  Timer? _timer;

  /// Incremented per search so a late response cannot overwrite a newer one.
  int _generation = 0;
  List<Customer> _results = const [];
  bool _searching = false;
  bool _searchFailed = false;
  bool _addingNew = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _phone = TextEditingController(text: widget.phone);
    // Edit mode may start with a typed (non-picked) customer.
    _addingNew = widget.customerId == null && widget.phone.isNotEmpty;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _addingNew = _addingNew && value.trim().isNotEmpty;
    widget.onNewCustomer(value, _phone.text);
    _timer?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _generation++;
      setState(() {
        _results = const [];
        _searching = false;
        _searchFailed = false;
      });
      return;
    }
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    setState(() {
      _searching = true;
      _searchFailed = false;
    });
    try {
      final page = await ref
          .read(customerRepositoryProvider)
          .list(page: 1, limit: 10, search: query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = page.items;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      // A failed search must not block entering a new customer.
      setState(() {
        _results = const [];
        _searching = false;
        _searchFailed = true;
      });
    }
  }

  void _pick(Customer customer) {
    _timer?.cancel();
    _generation++;
    setState(() {
      _results = const [];
      _addingNew = false;
    });
    widget.onSelectExisting(customer);
  }

  void _change() {
    _name.text = widget.name;
    _phone.clear();
    setState(() => _addingNew = false);
    widget.onNewCustomer(widget.name, '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (widget.customerId != null) {
      final phone = widget.phone.trim();
      return Card(
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(widget.name),
          subtitle: phone.isEmpty ? null : Text(phone),
          trailing: TextButton(
            onPressed: widget.enabled ? _change : null,
            child: Text(l10n.orderFormCustomerChange),
          ),
        ),
      );
    }

    final typed = _name.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          enabled: widget.enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: _onNameChanged,
          validator: FormValidators.all([
            FormValidators.required(l10n),
            FormValidators.maxLength(l10n, 100),
          ]),
          decoration: InputDecoration(
            labelText: l10n.orderFormCustomerLabel,
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (!_addingNew && typed.isNotEmpty) ...[
          for (final customer in _results)
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline),
              title: Text(customer.name),
              subtitle: (customer.phone ?? '').trim().isEmpty
                  ? null
                  : Text(customer.phone!),
              onTap: () => _pick(customer),
            ),
          if (_searchFailed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.orderFormCustomerSearchFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: Text(l10n.orderFormCustomerAddNew(typed)),
            onTap: () => setState(() => _addingNew = true),
          ),
        ],
        if (_addingNew) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            onChanged: (value) => widget.onNewCustomer(_name.text, value),
            decoration: InputDecoration(
              labelText: l10n.orderFormCustomerPhoneLabel,
            ),
          ),
        ],
      ],
    );
  }
}
