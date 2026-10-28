abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String registerOwner = '/register-owner';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';

  /// Routes reachable only while signed out.
  static const Set<String> authRoutes = {
    login,
    registerOwner,
    forgotPassword,
    resetPassword,
  };
}
