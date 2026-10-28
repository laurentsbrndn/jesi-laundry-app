import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/decimal_input.dart';
import '../../../core/utils/form_error_handler.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_button.dart';
import '../data/models/laundry_service.dart';
import '../data/models/pricing_unit.dart';
import 'services_provider.dart';

/// Add a unit service ([serviceId] null) or edit any service of [outletId].
/// There is no `GET /services/:id`, so an edit reads the service from the list.
class ServiceFormScreen extends ConsumerWidget {
  const ServiceFormScreen({super.key, required this.outletId, this.serviceId});

  final String outletId;
  final String? serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = serviceId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.serviceFormAddTitle)),
        body: _ServiceForm(outletId: outletId, service: null),
      );
    }

    final query = (outletId: outletId, includeInactive: true);
    final services = ref.watch(servicesProvider(query));
    final service = services.value?.where((s) => s.id == id).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.serviceFormEditTitle)),
      body: service != null
          ? _ServiceForm(outletId: outletId, service: service)
          : services.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(servicesProvider(query)),
              ),
              // The list was fetched and does not contain the service.
              data: (_) => ErrorView(
                error: const ApiException(code: ApiErrorCode.notFound),
                onRetry: () => context.pop(),
              ),
            ),
    );
  }
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({required this.outletId, required this.service});

  final String outletId;
  final LaundryService? service;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _serverErrors = ServerFieldErrors();
  late final TextEditingController _name;
  late final TextEditingController _regularPrice;
  late final TextEditingController _expressPrice;
  late final TextEditingController _regularDays;
  late final TextEditingController _expressDays;
  late final TextEditingController _minQuantity;
  late bool _isActive;
  PricingUnit _unit = PricingUnit.piece;
  bool _saving = false;

  LaundryService? get _service => widget.service;
  bool get _isEdit => _service != null;
  bool get _isKilo => _service?.category.isKilo ?? false;

  @override
  void initState() {
    super.initState();
    final service = _service;
    _name = TextEditingController(text: service?.name ?? '');
    _regularPrice = TextEditingController(
      text: service == null ? '' : '${service.regularPrice}',
    );
    _expressPrice = TextEditingController(
      text: service == null ? '' : '${service.expressPrice}',
    );
    _regularDays = TextEditingController(
      text: service == null ? '' : '${service.regularDurationDays}',
    );
    _expressDays = TextEditingController(
      text: service == null ? '' : '${service.expressDurationDays}',
    );
    _minQuantity = TextEditingController(
      text: service == null ? '0' : _plainNumber(service.minQuantity),
    );
    _isActive = service?.isActive ?? true;
    for (final c in [
      _name,
      _regularPrice,
      _expressPrice,
      _regularDays,
      _expressDays,
      _minQuantity,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _regularPrice.dispose();
    _expressPrice.dispose();
    _regularDays.dispose();
    _expressDays.dispose();
    _minQuantity.dispose();
    super.dispose();
  }

  static String _plainNumber(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// Edit mode: only the fields that differ from the loaded service.
  Map<String, Object?> _changes() {
    final service = _service!;
    final regularPrice = int.tryParse(_regularPrice.text.trim());
    final expressPrice = int.tryParse(_expressPrice.text.trim());
    final regularDays = int.tryParse(_regularDays.text.trim());
    final expressDays = int.tryParse(_expressDays.text.trim());
    final minQuantity = parseDecimal(_minQuantity.text);
    return {
      if (_name.text.trim() != service.name) 'name': _name.text.trim(),
      if (regularPrice != null && regularPrice != service.regularPrice)
        'regular_price': regularPrice,
      if (expressPrice != null && expressPrice != service.expressPrice)
        'express_price': expressPrice,
      if (regularDays != null && regularDays != service.regularDurationDays)
        'regular_duration_days': regularDays,
      if (expressDays != null && expressDays != service.expressDurationDays)
        'express_duration_days': expressDays,
      if (_isKilo &&
          minQuantity != null &&
          (minQuantity - service.minQuantity).abs() > 0.001)
        'min_quantity': minQuantity,
      if (_isActive != service.isActive) 'is_active': _isActive,
    };
  }

  bool get _hasChanges => !_isEdit || _changes().isNotEmpty;

  Future<void> _save() async {
    if (_saving) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final service = _service;

    if (service != null && service.isSystem && service.isActive && !_isActive) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.serviceFormDeactivateKiloTitle,
        message: l10n.serviceFormDeactivateKiloBody,
        confirmLabel: l10n.serviceFormDeactivateConfirm,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(catalogRepositoryProvider);
      if (service == null) {
        await repository.createUnitService(
          outletId: widget.outletId,
          name: _name.text,
          pricingUnit: _unit,
          regularPrice: int.parse(_regularPrice.text.trim()),
          expressPrice: int.parse(_expressPrice.text.trim()),
          regularDurationDays: int.parse(_regularDays.text.trim()),
          expressDurationDays: int.parse(_expressDays.text.trim()),
        );
      } else {
        await repository.update(service.id, _changes());
      }
      ref.invalidate(servicesProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = service == null
          ? l10n.serviceFormCreated
          : l10n.serviceFormSaved;
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
          codeFields: {ApiErrorCode.serviceNameTaken: 'name'},
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String serverField,
    required FormFieldValidator<String> validator,
    required int maxDigits,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      textInputAction: action,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxDigits),
      ],
      validator: _serverErrors.wrap(serverField, validator),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = _service;
    final unitLabel = (_isEdit ? service!.pricingUnit : _unit).label(context);
    final price = FormValidators.integerInRange(l10n, 0, 9999999999);
    final days = FormValidators.integerInRange(l10n, 1, 30);

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
                  decoration: InputDecoration(
                    labelText: l10n.serviceFormNameLabel,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isEdit)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.serviceFormUnitLabel,
                      helperText: l10n.serviceFormUnitLocked,
                      enabled: false,
                    ),
                    child: Text(
                      '${service!.category.label(context)} · $unitLabel',
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.serviceFormUnitLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<PricingUnit>(
                        segments: [
                          ButtonSegment(
                            value: PricingUnit.piece,
                            label: Text(PricingUnit.piece.label(context)),
                          ),
                          ButtonSegment(
                            value: PricingUnit.sqm,
                            label: Text(PricingUnit.sqm.label(context)),
                          ),
                        ],
                        selected: {_unit},
                        onSelectionChanged: _saving
                            ? null
                            : (selection) =>
                                  setState(() => _unit = selection.first),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _regularPrice,
                  label: l10n.serviceFormRegularPriceLabel(unitLabel),
                  serverField: 'regular_price',
                  validator: price,
                  maxDigits: 10,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _expressPrice,
                  label: l10n.serviceFormExpressPriceLabel(unitLabel),
                  serverField: 'express_price',
                  validator: price,
                  maxDigits: 10,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _regularDays,
                  label: l10n.serviceFormRegularDaysLabel,
                  serverField: 'regular_duration_days',
                  validator: days,
                  maxDigits: 2,
                ),
                const SizedBox(height: 16),
                _numberField(
                  controller: _expressDays,
                  label: l10n.serviceFormExpressDaysLabel,
                  serverField: 'express_duration_days',
                  validator: days,
                  maxDigits: 2,
                  action: _isKilo ? TextInputAction.next : TextInputAction.done,
                ),
                if (_isKilo) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minQuantity,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [DecimalInputFormatter()],
                    validator: _serverErrors.wrap(
                      'min_quantity',
                      FormValidators.nonNegativeNumber(l10n),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.serviceFormMinQuantityLabel,
                      helperText: l10n.serviceFormMinQuantityHelper,
                    ),
                  ),
                ],
                if (_isEdit) ...[
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
