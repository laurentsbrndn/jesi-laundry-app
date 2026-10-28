import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_owner_screen.dart';
import '../../features/auth/presentation/reset_password_args.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/setup_status_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import 'app_routes.dart';
import 'router_refresh_listenable.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable(ref);

  String? redirect(_, GoRouterState state) {
    final location = state.matchedLocation;
    final authState = ref.read(authControllerProvider).value;

    // Session check still running, or it failed (e.g. no network): stay on the
    // splash, which shows the loading indicator or an error with retry.
    if (authState == null) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isAuthRoute = AppRoutes.authRoutes.contains(location);
    switch (authState) {
      case Authenticated():
        return isAuthRoute || location == AppRoutes.splash
            ? AppRoutes.dashboard
            : null;
      case Unauthenticated():
        if (location == AppRoutes.splash || !isAuthRoute) {
          return AppRoutes.login;
        }
        // Registration only while no owner exists. An unknown status (not
        // loaded or failed) is allowed here; the screen guards on its own.
        if (location == AppRoutes.registerOwner &&
            ref.read(setupStatusProvider).value == true) {
          return AppRoutes.login;
        }
        return null;
    }
  }

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerOwner,
        builder: (context, state) => const RegisterOwnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        // Without the email from the previous step there is nothing to reset.
        redirect: (context, state) =>
            state.extra is ResetPasswordArgs ? null : AppRoutes.forgotPassword,
        builder: (context, state) =>
            ResetPasswordScreen(args: state.extra! as ResetPasswordArgs),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
