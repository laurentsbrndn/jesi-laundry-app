/// Error codes from ARCHITECTURE.md §8.1, plus the client-only [networkError].
abstract final class ApiErrorCode {
  static const String badRequest = 'BAD_REQUEST';
  static const String validationError = 'VALIDATION_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String invalidRefreshToken = 'INVALID_REFRESH_TOKEN';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String accountInactive = 'ACCOUNT_INACTIVE';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String emailTaken = 'EMAIL_TAKEN';
  static const String ownerAlreadyExists = 'OWNER_ALREADY_EXISTS';
  static const String outletCodeTaken = 'OUTLET_CODE_TAKEN';
  static const String serviceNameTaken = 'SERVICE_NAME_TAKEN';
  static const String outletInactive = 'OUTLET_INACTIVE';
  static const String serviceInactive = 'SERVICE_INACTIVE';
  static const String duplicateKiloService = 'DUPLICATE_KILO_SERVICE';
  static const String invalidStatusTransition = 'INVALID_STATUS_TRANSITION';
  static const String paymentRequired = 'PAYMENT_REQUIRED';
  static const String orderNotEditable = 'ORDER_NOT_EDITABLE';
  static const String systemServiceNotDeletable =
      'SYSTEM_SERVICE_NOT_DELETABLE';
  static const String otpInvalid = 'OTP_INVALID';
  static const String otpExpired = 'OTP_EXPIRED';
  static const String otpTooManyAttempts = 'OTP_TOO_MANY_ATTEMPTS';
  static const String rateLimited = 'RATE_LIMITED';
  static const String internalError = 'INTERNAL_ERROR';

  /// Client-only: timeout, no connection, or an unreadable response.
  static const String networkError = 'NETWORK_ERROR';
}
