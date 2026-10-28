import 'package:material_ui/material_ui.dart';

import '../network/api_error_code.dart';
import '../network/api_exception.dart';
import 'l10n_extension.dart';

/// Localized, user-facing text for an error. Never shows the raw server message.
String errorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! ApiException) return l10n.errorUnknown;
  return switch (error.code) {
    ApiErrorCode.badRequest => l10n.errorBadRequest,
    ApiErrorCode.validationError => l10n.errorValidationError,
    ApiErrorCode.unauthorized => l10n.errorUnauthorized,
    ApiErrorCode.tokenExpired => l10n.errorTokenExpired,
    ApiErrorCode.invalidRefreshToken => l10n.errorInvalidRefreshToken,
    ApiErrorCode.invalidCredentials => l10n.errorInvalidCredentials,
    ApiErrorCode.accountInactive => l10n.errorAccountInactive,
    ApiErrorCode.forbidden => l10n.errorForbidden,
    ApiErrorCode.notFound => l10n.errorNotFound,
    ApiErrorCode.emailTaken => l10n.errorEmailTaken,
    ApiErrorCode.ownerAlreadyExists => l10n.errorOwnerAlreadyExists,
    ApiErrorCode.outletCodeTaken => l10n.errorOutletCodeTaken,
    ApiErrorCode.serviceNameTaken => l10n.errorServiceNameTaken,
    ApiErrorCode.outletInactive => l10n.errorOutletInactive,
    ApiErrorCode.serviceInactive => l10n.errorServiceInactive,
    ApiErrorCode.duplicateKiloService => l10n.errorDuplicateKiloService,
    ApiErrorCode.invalidStatusTransition => l10n.errorInvalidStatusTransition,
    ApiErrorCode.paymentRequired => l10n.errorPaymentRequired,
    ApiErrorCode.orderNotEditable => l10n.errorOrderNotEditable,
    ApiErrorCode.systemServiceNotDeletable =>
      l10n.errorSystemServiceNotDeletable,
    ApiErrorCode.otpInvalid => l10n.errorOtpInvalid,
    ApiErrorCode.otpExpired => l10n.errorOtpExpired,
    ApiErrorCode.otpTooManyAttempts => l10n.errorOtpTooManyAttempts,
    ApiErrorCode.rateLimited => l10n.errorRateLimited,
    ApiErrorCode.internalError => l10n.errorInternalError,
    ApiErrorCode.networkError => l10n.errorNetworkError,
    _ => l10n.errorUnknown,
  };
}

/// Maps the `field` of a VALIDATION_ERROR detail to a form field key by
/// ignoring case and underscores, so `outlet_code` and `OutletCode` match.
String normalizeFieldName(String field) =>
    field.toLowerCase().replaceAll('_', '').replaceAll('.', '');

/// Server-side validation errors by normalized field name. Unknown rules fall
/// back to a generic message.
Map<String, String> fieldErrorMessages(BuildContext context, Object error) {
  if (error is! ApiException || error.code != ApiErrorCode.validationError) {
    return const {};
  }
  final l10n = context.l10n;
  final result = <String, String>{};
  for (final detail in error.details) {
    final param = int.tryParse(detail.param ?? '');
    result.putIfAbsent(
      normalizeFieldName(detail.field),
      () => switch (detail.rule) {
        'required' => l10n.validationRequired,
        'email' => l10n.validationInvalidEmail,
        'min' when param != null => l10n.validationMinLength(param),
        'max' when param != null => l10n.validationMaxLength(param),
        _ => l10n.validationServerInvalid,
      },
    );
  }
  return result;
}
