import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'placeholder_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const PlaceholderSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const PlaceholderLoginScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
