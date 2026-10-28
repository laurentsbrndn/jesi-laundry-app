import 'package:material_ui/material_ui.dart';

/// Replaces any visible snackbar with [message].
void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
