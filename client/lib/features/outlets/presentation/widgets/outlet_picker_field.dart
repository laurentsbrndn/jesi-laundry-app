import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../settings/presentation/widgets/choice_sheet.dart';
import '../outlets_provider.dart';

/// Form field to pick one outlet. Choices are the active outlets plus
/// [currentOutletId] (shown as inactive) so an existing assignment stays visible.
class OutletPickerField extends ConsumerWidget {
  const OutletPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.currentOutletId,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final String? currentOutletId;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final outlets = ref.watch(outletsProvider).value ?? const [];
    final choices = outlets
        .where((o) => o.isActive || o.id == currentOutletId)
        .toList();
    String labelOf(String id) {
      final outlet = outlets.where((o) => o.id == id).firstOrNull;
      if (outlet == null) return '';
      final text = '${outlet.code} · ${outlet.name}';
      return outlet.isActive ? text : '$text (${l10n.commonInactive})';
    }

    return FormField<String>(
      initialValue: value,
      validator: (_) => value == null ? l10n.validationRequired : null,
      builder: (state) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: !enabled || choices.isEmpty
              ? null
              : () async {
                  final picked = await showChoiceSheet<String>(
                    context,
                    title: l10n.outletPickerTitle,
                    options: [for (final o in choices) o.id],
                    selected: value ?? '',
                    labelOf: labelOf,
                  );
                  if (picked != null) {
                    onChanged(picked);
                    state.didChange(picked);
                  }
                },
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              labelText: l10n.outletPickerLabel,
              errorText: state.errorText,
              enabled: enabled,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(value == null ? '' : labelOf(value!)),
          ),
        );
      },
    );
  }
}
