import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import 'decimal_input.dart';

/// Form validators mirroring the server rules. Each takes the localizations
/// so error text follows the app language.
abstract final class FormValidators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static FormFieldValidator<String> required(AppLocalizations l10n) {
    return (value) =>
        (value ?? '').trim().isEmpty ? l10n.validationRequired : null;
  }

  static FormFieldValidator<String> email(AppLocalizations l10n) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return l10n.validationRequired;
      return _email.hasMatch(text) ? null : l10n.validationInvalidEmail;
    };
  }

  /// At least 8 characters with a letter and a digit.
  static FormFieldValidator<String> password(AppLocalizations l10n) {
    return (value) {
      final text = value ?? '';
      if (text.isEmpty) return l10n.validationRequired;
      if (text.length < 8) return l10n.validationPasswordTooShort;
      if (!text.contains(RegExp(r'[A-Za-z]')) ||
          !text.contains(RegExp(r'\d'))) {
        return l10n.validationPasswordNeedsLetterAndDigit;
      }
      return null;
    };
  }

  static FormFieldValidator<String> confirmPassword(
    AppLocalizations l10n,
    String Function() original,
  ) {
    return (value) {
      if ((value ?? '').isEmpty) return l10n.validationRequired;
      return value == original() ? null : l10n.validationPasswordMismatch;
    };
  }

  static FormFieldValidator<String> minLength(AppLocalizations l10n, int min) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return l10n.validationRequired;
      return text.length < min ? l10n.validationMinLength(min) : null;
    };
  }

  static FormFieldValidator<String> maxLength(AppLocalizations l10n, int max) {
    return (value) =>
        (value ?? '').length > max ? l10n.validationMaxLength(max) : null;
  }

  /// A decimal number greater than zero.
  static FormFieldValidator<String> positiveNumber(AppLocalizations l10n) {
    return (value) {
      if ((value ?? '').trim().isEmpty) return l10n.validationRequired;
      final number = parseDecimal(value!);
      return number == null || number <= 0
          ? l10n.validationInvalidNumber
          : null;
    };
  }
}
