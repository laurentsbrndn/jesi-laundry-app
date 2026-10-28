import 'package:material_ui/material_ui.dart';

import '../../data/models/dashboard_range.dart';

/// Horizontally scrollable choice chips for the dashboard range.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DashboardRange value;
  final ValueChanged<DashboardRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final range in DashboardRange.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(range.label(context)),
                selected: range == value,
                onSelected: (_) => onChanged(range),
              ),
            ),
        ],
      ),
    );
  }
}
