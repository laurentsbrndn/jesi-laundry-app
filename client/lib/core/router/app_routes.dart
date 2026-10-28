abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String registerOwner = '/register-owner';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String orders = '/orders';
  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String settingsChangePassword = '/settings/change-password';
  static const String outlets = '/settings/outlets';
  static const String outletNew = '/settings/outlets/new';
  static const String services = '/settings/services';
  static const String serviceNew = '/settings/services/new';
  static const String staff = '/settings/staff';
  static const String staffNew = '/settings/staff/new';
  static const String customers = '/settings/customers';

  static String outletEdit(String id) => '$outlets/$id';
  static String staffEdit(String id) => '$staff/$id';
  static String customerEdit(String id) => '$customers/$id';

  /// Add-unit-service screen; the outlet is passed as a query parameter.
  static String serviceNewFor(String outletId) =>
      Uri(path: serviceNew, queryParameters: {'outletId': outletId}).toString();

  static String serviceEdit(String id, String outletId) => Uri(
    path: '$services/$id',
    queryParameters: {'outletId': outletId},
  ).toString();

  /// Routes reachable only while signed out.
  static const Set<String> authRoutes = {
    login,
    registerOwner,
    forgotPassword,
    resetPassword,
  };

  /// Path prefixes only owners may open. F4/F5 add their routes under these.
  static const List<String> ownerOnlyPrefixes = [
    '/settings/services',
    '/settings/customers',
    '/settings/staff',
    '/settings/outlets',
  ];

  static final RegExp _orderEdit = RegExp(r'^/orders/[^/]+/edit$');

  static bool isOwnerOnly(String location) {
    return ownerOnlyPrefixes.any(
          (prefix) => location == prefix || location.startsWith('$prefix/'),
        ) ||
        _orderEdit.hasMatch(location);
  }
}
