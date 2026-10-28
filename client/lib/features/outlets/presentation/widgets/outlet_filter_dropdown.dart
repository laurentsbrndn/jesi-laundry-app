import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../outlets_provider.dart';

/// Outlet selector for owners. Hidden when there is only one active outlet.
/// [value] null means "all outlets" and is only valid when [allowAll] is set.
class OutletFilterDropdown extends ConsumerWidget {
  const OutletFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAll = false,
  });

  /// Selected outlet id, or null for all outlets.
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAll;

  static const String _allValue = '__all__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outlets = ref.watch(outletsProvider).value;
    if (outlets == null) return const SizedBox.shrink();

    final active = outlets.where((o) => o.isActive).toList();
    if (active.length <= 1) return const SizedBox.shrink();

    // Only active outlets are choices, plus the selected one even if inactive.
    final choices = outlets.where((o) => o.isActive || o.id == value).toList();
    final l10n = context.l10n;
    final selected = choices.where((o) => o.id == value).firstOrNull;
    final label = selected?.name ?? l10n.outletFilterAll;

    return PopupMenuButton<String>(
      tooltip: l10n.outletFilterTooltip,
      onSelected: (id) => onChanged(id == _allValue ? null : id),
      itemBuilder: (context) => [
        if (allowAll)
          PopupMenuItem(value: _allValue, child: Text(l10n.outletFilterAll)),
        for (final outlet in choices)
          PopupMenuItem(
            value: outlet.id,
            child: Text(
              outlet.isActive
                  ? outlet.name
                  : '${outlet.name} (${l10n.commonInactive})',
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 20),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
