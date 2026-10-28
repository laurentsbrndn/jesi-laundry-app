import 'package:material_ui/material_ui.dart';

import '../../data/models/service_speed.dart';

class SpeedSelector extends StatelessWidget {
  const SpeedSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final ServiceSpeed value;
  final ValueChanged<ServiceSpeed> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<ServiceSpeed>(
        segments: [
          for (final speed in ServiceSpeed.values)
            ButtonSegment(value: speed, label: Text(speed.label(context))),
        ],
        selected: {value},
        onSelectionChanged: enabled
            ? (selection) => onChanged(selection.first)
            : null,
      ),
    );
  }
}
