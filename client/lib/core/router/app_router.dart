import 'package:flutter/widgets.dart';
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
import '../../features/orders/presentation/orders_list_screen.dart';
import '../../features/settings/presentation/change_password_screen.dart';
import '../../features/settings/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import 'app_routes.dart';
import 'router_refresh_listenable.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshListenable(ref);
  final rootNavigatorKey = GlobalKey<NavigatorState>();

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
      case Authenticated(:final user):
        if (isAuthRoute || location == AppRoutes.splash) {
          return AppRoutes.dashboard;
        }
        // Owner-only screens: staff go back to the dashboard.
        if (!user.isOwner && AppRoutes.isOwnerOnly(location)) {
          return AppRoutes.dashboard;
        }
        return null;
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
    navigatorKey: rootNavigatorKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  // Detail screens use the root navigator so the bottom
                  // navigation bar is hidden on them.
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
