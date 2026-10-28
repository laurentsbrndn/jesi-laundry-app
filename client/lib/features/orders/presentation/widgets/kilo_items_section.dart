import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../../catalog/data/models/laundry_service.dart';
import '../../data/models/order_draft_item.dart';
import '../../data/models/service_speed.dart';
import '../order_pricing_preview.dart';

/// One kg field per active per-kilo service. A line exists in the draft only
/// while its field holds a valid positive quantity.
class KiloItemsSection extends StatefulWidget {
  const KiloItemsSection({
    super.key,
    required this.services,
    required this.items,
    required this.speed,
    required this.onChanged,
    this.enabled = true,
  });

  final List<LaundryService> services;
  final List<OrderDraftItem> items;
  final ServiceSpeed speed;
  final void Function(LaundryService service, int? quantity100) onChanged;
  final bool enabled;

  @override
  State<KiloItemsSection> createState() => _KiloItemsSectionState();
}

class _KiloItemsSectionState extends State<KiloItemsSection> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controllerFor(LaundryService service) {
    return _controllers.putIfAbsent(service.id, () {
      final existing = widget.items
          .where((item) => item.serviceId == service.id)
          .firstOrNull;
      final quantity = existing?.quantity100;
      return TextEditingController(
        text: quantity == null ? '' : hundredthsToInput(quantity),
      );
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    return Column(
      children: [
        for (final service in widget.services)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _row(context, service, l10n, locale),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    LaundryService service,
    AppLocalizations l10n,
    Locale locale,
  ) {
    final price = widget.speed == ServiceSpeed.express
        ? service.expressPrice
        : service.regularPrice;
    final controller = _controllerFor(service);
    final quantity100 = parseHundredths(controller.text) ?? 0;
    final minimum100 = minQuantityHundredths(service.minQuantity);
    final billedNote = quantity100 > 0 && quantity100 < minimum100
        ? l10n.orderFormBilledAs(formatQuantity(minimum100 / 100, locale))
        : null;

    return TextFormField(
      controller: controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        DecimalInputFormatter(),
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: (text) {
        setState(() {});
        widget.onChanged(service, parseHundredths(text));
      },
      validator: (text) {
        if ((text ?? '').trim().isEmpty) return null;
        final value = parseHundredths(text!);
        return value == null || value > 99999
            ? l10n.validationInvalidNumber
            : null;
      },
      decoration: InputDecoration(
        labelText: '${service.name} · ${formatCurrency(price)}/${l10n.unitKg}',
        suffixText: l10n.unitKg,
        helperText: billedNote,
      ),
    );
  }
}
