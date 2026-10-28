import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// `true` when an owner is already registered. Failures are not retried
/// automatically; the login screen just hides the register button.
final setupStatusProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(authRepositoryProvider).setupStatus(),
  retry: (_, _) => null,
);
