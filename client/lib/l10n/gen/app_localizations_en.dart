// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Jesi Laundry';

  @override
  String get splashLoading => 'Loading…';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get configErrorTitle => 'Configuration incomplete';

  @override
  String get configErrorBody =>
      'API_BASE_URL is not set. Run the app with --dart-define=API_BASE_URL=<server address>.';

  @override
  String get errorBadRequest => 'The request could not be processed.';

  @override
  String get errorValidationError =>
      'Some of the entered data is invalid. Please check your input.';

  @override
  String get errorUnauthorized => 'Invalid session. Please sign in again.';

  @override
  String get errorTokenExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorInvalidRefreshToken =>
      'Your session has ended. Please sign in again.';

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorAccountInactive =>
      'Your account has been deactivated. Contact the owner.';

  @override
  String get errorForbidden => 'You do not have permission to do this.';

  @override
  String get errorNotFound => 'The requested data was not found.';

  @override
  String get errorEmailTaken => 'This email is already in use.';

  @override
  String get errorOwnerAlreadyExists => 'An owner is already registered.';

  @override
  String get errorOutletCodeTaken => 'This outlet code is already in use.';

  @override
  String get errorServiceNameTaken =>
      'A service with this name already exists in this outlet.';

  @override
  String get errorOutletInactive =>
      'This outlet is inactive and cannot accept orders.';

  @override
  String get errorServiceInactive =>
      'The service is inactive, deleted, or does not belong to the order outlet.';

  @override
  String get errorDuplicateKiloService =>
      'The same per-kilo service cannot appear more than once in an order.';

  @override
  String get errorInvalidStatusTransition =>
      'This status change is not allowed.';

  @override
  String get errorPaymentRequired =>
      'The order must be paid before it can be marked as picked up.';

  @override
  String get errorOrderNotEditable =>
      'Paid or picked-up orders cannot be edited.';

  @override
  String get errorSystemServiceNotDeletable =>
      'Built-in per-kilo services cannot be deleted.';

  @override
  String get errorOtpInvalid => 'The OTP code is incorrect.';

  @override
  String get errorOtpExpired => 'The OTP code has expired. Request a new one.';

  @override
  String get errorOtpTooManyAttempts =>
      'Too many attempts. Request a new code.';

  @override
  String get errorRateLimited => 'Too many requests. Please try again shortly.';

  @override
  String get errorInternalError =>
      'A server error occurred. Please try again later.';

  @override
  String get errorNetworkError =>
      'Cannot reach the server. Check your internet connection.';

  @override
  String get errorUnknown => 'An unknown error occurred.';

  @override
  String get serviceCategoryWashIron => 'Wash & Iron';

  @override
  String get serviceCategoryIronOnly => 'Iron Only';

  @override
  String get serviceCategoryWashFold => 'Wash & Fold';

  @override
  String get serviceCategoryUnit => 'Unit Items';

  @override
  String get serviceSpeedRegular => 'Regular';

  @override
  String get serviceSpeedExpress => 'Express';

  @override
  String get orderStatusReceived => 'Received';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusDone => 'Ready';

  @override
  String get orderStatusPickedUp => 'Picked Up';

  @override
  String get paymentStatusUnpaid => 'Unpaid';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get pricingUnitPiece => 'pcs';

  @override
  String get pricingUnitSqm => 'm²';

  @override
  String get unitKg => 'kg';

  @override
  String get unitPcs => 'pcs';

  @override
  String get unitSqm => 'm²';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Yes';

  @override
  String get commonEmptyTitle => 'Nothing here yet';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationInvalidEmail => 'Invalid email format';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get validationPasswordNeedsLetterAndDigit =>
      'Password must contain letters and digits';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationInvalidNumber => 'Invalid number';

  @override
  String validationMinLength(int min) {
    return 'At least $min characters';
  }

  @override
  String validationMaxLength(int max) {
    return 'At most $max characters';
  }

  @override
  String get splashSlowHint =>
      'The server may be waking up. Please wait a moment…';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginRegisterOwner => 'Register as Owner';

  @override
  String get loginSessionExpired => 'Session expired, please sign in again';

  @override
  String get registerOwnerTitle => 'Register as Owner';

  @override
  String get registerOwnerAccountSection => 'Owner account';

  @override
  String get registerOwnerOutletSection => 'First outlet';

  @override
  String get registerOwnerOutletNameLabel => 'Outlet name';

  @override
  String get registerOwnerOutletCodeLabel => 'Outlet code';

  @override
  String get registerOwnerOutletCodeHelper => '2–5 letters or digits';

  @override
  String get registerOwnerOutletAddressLabel => 'Outlet address (optional)';

  @override
  String get registerOwnerOutletPhoneLabel => 'Outlet phone (optional)';

  @override
  String get registerOwnerSubmit => 'Register';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordBody =>
      'Enter your account email. If it is registered, we will send a 6-digit verification code.';

  @override
  String get forgotPasswordSubmit => 'Send code';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String resetPasswordBody(String email) {
    return 'Enter the 6-digit code sent to $email and your new password.';
  }

  @override
  String get resetPasswordOtpLabel => 'OTP code';

  @override
  String get resetPasswordResend => 'Resend code';

  @override
  String resetPasswordResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resetPasswordResent =>
      'If the email is registered, a new code has been sent.';

  @override
  String get resetPasswordSubmit => 'Reset password';

  @override
  String get resetPasswordSuccess => 'Password changed. Please sign in.';

  @override
  String get userRoleOwner => 'Owner';

  @override
  String get userRoleStaff => 'Staff';

  @override
  String get validationPasswordTooLong =>
      'Password is too long (72 bytes maximum)';

  @override
  String get validationOtpLength => 'The code must be 6 digits';

  @override
  String get validationOutletCode =>
      'Outlet code must be 2–5 letters or digits';

  @override
  String get validationServerInvalid => 'Invalid value';

  @override
  String get dashboardPlaceholderTitle => 'Dashboard';

  @override
  String get dashboardPlaceholderNotice =>
      'Temporary screen. The full dashboard comes later.';

  @override
  String get dashboardPlaceholderRoleLabel => 'Role';

  @override
  String get dashboardPlaceholderOutletLabel => 'Outlet';

  @override
  String get shellTabDashboard => 'Dashboard';

  @override
  String get shellTabOrders => 'Orders';

  @override
  String get shellTabSettings => 'Settings';

  @override
  String get ordersPlaceholderTitle => 'Orders';

  @override
  String get ordersPlaceholderMessage => 'Orders are coming soon';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSectionManage => 'Manage';

  @override
  String get settingsManageServices => 'Services & Prices';

  @override
  String get settingsManageCustomers => 'Customers';

  @override
  String get settingsManageStaff => 'Staff';

  @override
  String get settingsManageOutlets => 'Outlets';

  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutConfirmTitle => 'Sign out?';

  @override
  String get settingsLogoutConfirmBody =>
      'You will need to sign in again to use the app.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileOutletLabel => 'Outlet';

  @override
  String get profileAllOutlets => 'All outlets';

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordSubmit => 'Change password';

  @override
  String get changePasswordCurrentWrong => 'Current password is incorrect';

  @override
  String get changePasswordSuccess => 'Password changed';
}
