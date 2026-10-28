import 'package:material_ui/material_ui.dart';

/// Bottom sheet listing [options]; the current one shows a check mark.
/// Returns the picked option, or null if dismissed.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T option) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final option in options)
            ListTile(
              title: Text(labelOf(option)),
              trailing: option == selected ? const Icon(Icons.check) : null,
              selected: option == selected,
              onTap: () => Navigator.of(context).pop(option),
            ),
        ],
      ),
    ),
  );
}
