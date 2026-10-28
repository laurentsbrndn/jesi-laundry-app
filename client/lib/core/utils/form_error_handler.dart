import 'package:material_ui/material_ui.dart';

import '../l10n/error_message.dart';
import '../network/api_exception.dart';
import '../network/api_error_code.dart';
import '../widgets/app_snack_bar.dart';
import 'server_field_errors.dart';

/// Shows a failed submit on the right place: error codes in [codeFields] go on
/// that form field, VALIDATION_ERROR details go on their fields (plus a
/// snackbar), everything else is a snackbar.
void showFormError(
  BuildContext context,
  Object error, {
  required ServerFieldErrors serverErrors,
  required GlobalKey<FormState> formKey,
  Map<String, String> codeFields = const {},
}) {
  final field = error is ApiException ? codeFields[error.code] : null;
  if (field != null) {
    serverErrors.replace({
      normalizeFieldName(field): errorMessage(context, error),
    });
    formKey.currentState?.validate();
    return;
  }
  if (error is ApiException && error.code == ApiErrorCode.validationError) {
    serverErrors.replace(fieldErrorMessages(context, error));
    formKey.currentState?.validate();
  }
  showAppSnackBar(context, errorMessage(context, error));
}
