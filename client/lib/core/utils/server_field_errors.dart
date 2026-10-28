import 'package:material_ui/material_ui.dart';

import '../l10n/error_message.dart';

/// Holds server-side field errors for a form and merges them into validators.
/// Call [replace] after a failed submit, then validate the form to show them;
/// call [clear] before the next submit.
class ServerFieldErrors {
  Map<String, String> _errors = const {};

  void replace(Map<String, String> errors) => _errors = errors;

  void clear() => _errors = const {};

  /// Runs [validator] first, then falls back to the server error for [field].
  FormFieldValidator<String> wrap(
    String field,
    FormFieldValidator<String> validator,
  ) {
    return (value) => validator(value) ?? _errors[normalizeFieldName(field)];
  }
}
