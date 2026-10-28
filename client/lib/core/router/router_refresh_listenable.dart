import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_controller.dart';

/// Bridges the auth state to GoRouter's `refreshListenable`, so the redirect
/// runs again whenever the user signs in, signs out, or the session check ends.
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}
