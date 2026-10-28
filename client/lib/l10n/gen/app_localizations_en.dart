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
  String get shellTabDashboard => 'Dashboard';

  @override
  String get shellTabOrders => 'Orders';

  @override
  String get shellTabSettings => 'Settings';

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

  @override
  String get commonSearch => 'Search';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonActive => 'Active';

  @override
  String get commonInactive => 'Inactive';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonContinue => 'Continue';

  @override
  String commonDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String validationRange(int min, int max) {
    return 'Enter a number from $min to $max';
  }

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String timeAgoMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get outletsTitle => 'Outlets';

  @override
  String get outletsAdd => 'Add outlet';

  @override
  String get outletsEmpty => 'No outlets yet';

  @override
  String get outletFormAddTitle => 'Add Outlet';

  @override
  String get outletFormEditTitle => 'Edit Outlet';

  @override
  String get outletFormAddressLabel => 'Address (optional)';

  @override
  String get outletFormPhoneLabel => 'Phone (optional)';

  @override
  String get outletFormCodeLocked => 'The code cannot be changed';

  @override
  String get outletFormCreated =>
      'Outlet created. The default service catalog was created automatically.';

  @override
  String get outletFormSaved => 'Outlet saved';

  @override
  String get outletDeactivateTitle => 'Deactivate outlet?';

  @override
  String get outletDeactivateBody =>
      'An inactive outlet cannot receive new orders.';

  @override
  String get outletDeactivateConfirm => 'Deactivate';

  @override
  String get outletFilterAll => 'All outlets';

  @override
  String get outletFilterTooltip => 'Choose outlet';

  @override
  String get outletPickerLabel => 'Outlet';

  @override
  String get outletPickerTitle => 'Choose outlet';

  @override
  String get servicesTitle => 'Services & Prices';

  @override
  String get servicesAddUnit => 'Add unit item';

  @override
  String get servicesSectionKilo => 'Per kilo';

  @override
  String get servicesSectionUnit => 'Unit items';

  @override
  String get servicesUnitEmpty => 'No unit services yet';

  @override
  String get servicesBadgeSystem => 'System';

  @override
  String get servicesDeleteTitle => 'Delete service?';

  @override
  String servicesDeleteBody(String name) {
    return 'The service \"$name\" will be deleted. Existing orders are not affected.';
  }

  @override
  String get servicesDeleted => 'Service deleted';

  @override
  String get serviceFormAddTitle => 'Add Unit Service';

  @override
  String get serviceFormEditTitle => 'Edit Service';

  @override
  String get serviceFormNameLabel => 'Service name';

  @override
  String get serviceFormUnitLabel => 'Unit';

  @override
  String get serviceFormUnitLocked => 'The unit cannot be changed';

  @override
  String serviceFormRegularPriceLabel(String unit) {
    return 'Regular price (per $unit)';
  }

  @override
  String serviceFormExpressPriceLabel(String unit) {
    return 'Express price (per $unit)';
  }

  @override
  String get serviceFormRegularDaysLabel => 'Regular duration (days)';

  @override
  String get serviceFormExpressDaysLabel => 'Express duration (days)';

  @override
  String get serviceFormMinQuantityLabel => 'Minimum quantity (kg)';

  @override
  String get serviceFormMinQuantityHelper => '0 = no minimum';

  @override
  String get serviceFormCreated => 'Service added';

  @override
  String get serviceFormSaved => 'Service saved';

  @override
  String get serviceFormDeactivateKiloTitle => 'Deactivate service?';

  @override
  String get serviceFormDeactivateKiloBody =>
      'An inactive service cannot be chosen when creating new orders.';

  @override
  String get serviceFormDeactivateConfirm => 'Deactivate';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffSearchHint => 'Search name or email';

  @override
  String get staffEmpty => 'No staff yet';

  @override
  String get staffFormAddTitle => 'Add Staff';

  @override
  String get staffFormEditTitle => 'Edit Staff';

  @override
  String get staffFormCreated => 'Staff added';

  @override
  String get staffFormSaved => 'Staff saved';

  @override
  String get staffSessionEndsTitle => 'End the staff session?';

  @override
  String get staffSessionEndsBody =>
      'This staff member will be signed out and must sign in again.';

  @override
  String get staffResetPassword => 'Reset password';

  @override
  String get staffResetPasswordTitle => 'Reset staff password';

  @override
  String get staffResetPasswordBody =>
      'Enter a new password. All sessions of this staff member will end.';

  @override
  String get staffResetPasswordDone => 'Staff password reset';

  @override
  String get customersTitle => 'Customers';

  @override
  String get customersSearchHint => 'Search name or phone';

  @override
  String get customersEmptyTitle => 'No customers yet';

  @override
  String get customersEmptyMessage =>
      'Customers appear automatically when orders are created.';

  @override
  String customersLastOrder(String when) {
    return 'Last order: $when';
  }

  @override
  String get customerEditTitle => 'Edit Customer';

  @override
  String get customerEditSaved => 'Customer saved';

  @override
  String get customerEditPhoneLabel => 'Phone (optional)';

  @override
  String get commonBack => 'Back';

  @override
  String get commonOk => 'OK';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get ordersNew => 'New Order';

  @override
  String get ordersSearchHint => 'Search order number or customer';

  @override
  String get ordersFilterAll => 'All';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyMessage => 'Tap New Order to create the first one.';

  @override
  String ordersEstimatedDone(String date) {
    return 'Estimated done: $date';
  }

  @override
  String get orderActionStart => 'Start Processing';

  @override
  String get orderActionFinish => 'Mark Ready';

  @override
  String get orderActionPickUp => 'Mark Picked Up';

  @override
  String get orderActionMarkPaid => 'Mark Paid';

  @override
  String get orderActionsMenu => 'Order menu';

  @override
  String get orderActionEdit => 'Edit';

  @override
  String get orderActionChangeStatus => 'Change status';

  @override
  String get orderActionUnpay => 'Cancel payment';

  @override
  String get orderActionDelete => 'Delete';

  @override
  String get orderPaidQuestionTitle => 'Has the customer paid?';

  @override
  String get orderPaidQuestionBody =>
      'The order must be paid before it is marked picked up.';

  @override
  String get orderPaidQuestionConfirm => 'Yes, paid';

  @override
  String get orderPaidButNotPickedUp =>
      'The order was marked paid, but not yet marked picked up.';

  @override
  String get orderUnpayTitle => 'Cancel paid status?';

  @override
  String get orderUnpayBody => 'The order will become unpaid again.';

  @override
  String get orderDeleteTitle => 'Delete order?';

  @override
  String orderDeleteBody(String number) {
    return 'Order $number will be deleted and will no longer appear in the list.';
  }

  @override
  String get orderDeleted => 'Order deleted';

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get orderDetailOutlet => 'Outlet';

  @override
  String get orderDetailReceivedAt => 'Received';

  @override
  String get orderDetailSpeed => 'Speed';

  @override
  String get orderDetailCreatedBy => 'Created by';

  @override
  String get orderDetailCustomer => 'Customer';

  @override
  String get orderDetailProgress => 'Progress';

  @override
  String get orderDetailItems => 'Items';

  @override
  String get orderDetailTotal => 'Total';

  @override
  String get orderDetailPayment => 'Payment';

  @override
  String get orderDetailPaidAt => 'Paid on';

  @override
  String get orderDetailNotes => 'Notes';

  @override
  String orderItemDimensions(String length, String width, String area) {
    return '$length × $width m = $area m²';
  }

  @override
  String orderItemBilled(String quantity, String unit) {
    return 'billed $quantity $unit';
  }

  @override
  String get orderFormNewTitle => 'New Order';

  @override
  String get orderFormEditTitle => 'Edit Order';

  @override
  String get orderFormEditNote =>
      'Prices are recalculated with the latest prices when saved.';

  @override
  String get orderFormCustomerSection => 'Customer';

  @override
  String get orderFormCustomerLabel => 'Customer name';

  @override
  String get orderFormCustomerPhoneLabel => 'Phone (optional)';

  @override
  String orderFormCustomerAddNew(String name) {
    return 'Add new customer: $name';
  }

  @override
  String get orderFormCustomerChange => 'Change';

  @override
  String get orderFormCustomerSearchFailed =>
      'Could not search customers. You can still add a new customer.';

  @override
  String get orderFormSpeedSection => 'Speed';

  @override
  String orderFormEstimatedDone(String date) {
    return 'Estimated done: $date';
  }

  @override
  String get orderFormPickOutlet => 'Choose an outlet first.';

  @override
  String get orderFormKiloSection => 'Per kilo';

  @override
  String get orderFormNoKiloServices => 'No active per-kilo services.';

  @override
  String orderFormBilledAs(String min) {
    return 'Billed as $min kg';
  }

  @override
  String get orderFormUnitSection => 'Unit items';

  @override
  String get orderFormAddUnitItem => 'Add unit item';

  @override
  String get orderFormUnitPickerTitle => 'Choose a unit service';

  @override
  String get orderFormUnitPickerEmpty => 'No active unit services.';

  @override
  String get orderFormUnitAdd => 'Add';

  @override
  String get orderFormLengthLabel => 'Length (m)';

  @override
  String get orderFormWidthLabel => 'Width (m)';

  @override
  String orderFormArea(String area, String unit) {
    return 'Area: $area $unit';
  }

  @override
  String get orderFormDecrease => 'Decrease';

  @override
  String get orderFormIncrease => 'Increase';

  @override
  String get orderFormRemoveItem => 'Remove item';

  @override
  String get orderFormInactiveWarning =>
      'These services are no longer active. Remove them before saving.';

  @override
  String get orderFormNotesSection => 'Notes';

  @override
  String get orderFormNotesHint => 'Notes for this order (optional)';

  @override
  String get orderFormPaidSwitch => 'Already paid';

  @override
  String get orderFormEstimatedTotal => 'Estimated total';

  @override
  String get orderFormOutletRequired => 'Choose an outlet first.';

  @override
  String get orderFormItemsRequired => 'Add at least one item.';

  @override
  String get orderFormItemsInvalid =>
      'Check the item quantities. Enter valid numbers.';

  @override
  String get orderFormRemoveInactive =>
      'Remove inactive services before saving.';

  @override
  String get orderFormTooManyItems => 'An order can have at most 50 items.';

  @override
  String orderFormItemError(String name) {
    return 'Item \"$name\" is not valid. Check its quantity.';
  }

  @override
  String get orderFormChangeOutletTitle => 'Change outlet?';

  @override
  String get orderFormChangeOutletBody =>
      'Services differ per outlet, so all items will be cleared.';

  @override
  String get orderFormDiscardTitle => 'Discard changes?';

  @override
  String get orderFormDiscardBody => 'What you entered will be lost.';

  @override
  String get orderFormDiscardConfirm => 'Discard';

  @override
  String orderFormCreated(String number) {
    return 'Order $number created';
  }

  @override
  String get orderFormSaved => 'Order saved';

  @override
  String get orderFormCreateUnknownTitle => 'Result unknown';

  @override
  String get orderFormCreateUnknownBody =>
      'The connection dropped. The order may already have been saved. Check the order list before trying again to avoid a duplicate.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardRange1h => '1h';

  @override
  String get dashboardRange24h => '24h';

  @override
  String get dashboardRange7d => '7d';

  @override
  String get dashboardRange30d => '30d';

  @override
  String get dashboardRange1y => '1y';

  @override
  String get dashboardRangeAll => 'All';

  @override
  String dashboardPeriod(String from, String to) {
    return 'Period: $from – $to';
  }

  @override
  String get dashboardOperationalNow => 'Current status';

  @override
  String get dashboardInProgress => 'In progress';

  @override
  String get dashboardReadyForPickup => 'Ready for pickup';

  @override
  String get dashboardUnpaid => 'Unpaid';

  @override
  String get dashboardSummary => 'Period summary';

  @override
  String get dashboardTotalOrders => 'Orders';

  @override
  String get dashboardTotalKg => 'Total kg';

  @override
  String get dashboardTotalPcs => 'Total pcs';

  @override
  String get dashboardTotalSqm => 'Total m²';

  @override
  String get dashboardRevenue => 'Revenue';

  @override
  String get dashboardRevenuePaid => 'Paid';

  @override
  String get dashboardRevenueUnpaid => 'Unpaid';

  @override
  String dashboardOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get dashboardChartTitle => 'Chart';

  @override
  String get dashboardMetricOrders => 'Orders';

  @override
  String get dashboardMetricWeight => 'Kg';

  @override
  String get dashboardMetricRevenue => 'Revenue';

  @override
  String get dashboardByCategory => 'By category';

  @override
  String get dashboardByUnitService => 'By unit item';

  @override
  String get dashboardByStatus => 'By status';

  @override
  String get dashboardEmpty => 'No orders in this period';
}
