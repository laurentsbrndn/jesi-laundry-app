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
