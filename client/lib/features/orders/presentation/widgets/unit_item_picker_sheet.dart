import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../../catalog/data/models/laundry_service.dart';
import '../../../catalog/data/models/pricing_unit.dart';
import '../../data/models/order_draft_item.dart';
import '../../data/models/service_speed.dart';
import '../order_pricing_preview.dart';

/// What the sheet returns: the chosen service and its quantity (hundredths).
typedef UnitItemInput = ({
  LaundryService service,
  int? quantity100,
  int? length100,
  int? width100,
});

/// Picks a unit service and enters its quantity (pcs) or size (m²). Pass
/// [existing] and its [service] to edit a line instead of adding one.
Future<UnitItemInput?> showUnitItemPickerSheet(
  BuildContext context, {
  required List<LaundryService> services,
  required ServiceSpeed speed,
  LaundryService? service,
  OrderDraftItem? existing,
}) {
  return showModalBottomSheet<UnitItemInput>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _UnitItemSheet(
        services: services,
        speed: speed,
        initialService: service,
        existing: existing,
      ),
    ),
  );
}

class _UnitItemSheet extends StatefulWidget {
  const _UnitItemSheet({
    required this.services,
    required this.speed,
    required this.initialService,
    required this.existing,
  });

  final List<LaundryService> services;
  final ServiceSpeed speed;
  final LaundryService? initialService;
  final OrderDraftItem? existing;

  @override
  State<_UnitItemSheet> createState() => _UnitItemSheetState();
}

class _UnitItemSheetState extends State<_UnitItemSheet> {
  LaundryService? _service;
  int _count = 1;
  final _length = TextEditingController();
  final _width = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = widget.initialService;
    final existing = widget.existing;
    if (existing != null) {
      _count = ((existing.quantity100 ?? 100) ~/ 100).clamp(1, 999);
      if (existing.length100 != null) {
        _length.text = hundredthsToInput(existing.length100!);
      }
      if (existing.width100 != null) {
        _width.text = hundredthsToInput(existing.width100!);
      }
    }
  }

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  int get _length100 => parseHundredths(_length.text) ?? 0;
  int get _width100 => parseHundredths(_width.text) ?? 0;

  bool get _isValid {
    final service = _service;
    if (service == null) return false;
    final item = OrderDraftItem(
      uid: 0,
      serviceId: service.id,
      serviceName: service.name,
      unit: service.pricingUnit,
      quantity100: _count * 100,
      length100: _length100,
      width100: _width100,
    );
    return previewItem(item, service, widget.speed).isValid;
  }

  void _submit() {
    final service = _service!;
    final isArea = service.pricingUnit == PricingUnit.sqm;
    Navigator.of(context).pop((
      service: service,
      quantity100: isArea ? null : _count * 100,
      length100: isArea ? _length100 : null,
      width100: isArea ? _width100 : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: service == null ? _list(context) : _form(context, service),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.orderFormUnitPickerTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (widget.services.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.orderFormUnitPickerEmpty),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final option in widget.services)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.name),
                    subtitle: Text(
                      '${formatCurrency(widget.speed == ServiceSpeed.express ? option.expressPrice : option.regularPrice)}/${option.pricingUnit.label(context)}',
                    ),
                    onTap: () => setState(() => _service = option),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _form(BuildContext context, LaundryService service) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isEditing = widget.existing != null;
    final isArea = service.pricingUnit == PricingUnit.sqm;
    final area100 = areaHundredths(_length100, _width100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (!isEditing)
              IconButton(
                tooltip: l10n.commonBack,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _service = null),
              ),
            Expanded(
              child: Text(service.name, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isArea) ...[
          TextField(
            controller: _length,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              DecimalInputFormatter(),
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.orderFormLengthLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _width,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              DecimalInputFormatter(),
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.orderFormWidthLabel),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.orderFormArea(
              formatQuantity(area100 / 100, locale),
              l10n.unitSqm,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                tooltip: l10n.orderFormDecrease,
                icon: const Icon(Icons.remove),
                onPressed: _count > 1 ? () => setState(() => _count--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$_count', style: theme.textTheme.headlineSmall),
              ),
              IconButton.outlined(
                tooltip: l10n.orderFormIncrease,
                icon: const Icon(Icons.add),
                onPressed: _count < 999 ? () => setState(() => _count++) : null,
              ),
            ],
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: Text(isEditing ? l10n.commonSave : l10n.orderFormUnitAdd),
        ),
      ],
    );
  }
}
