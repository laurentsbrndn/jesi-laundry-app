import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the network layer announce that the session ended (invalid or revoked
/// tokens) without depending on the auth controller, which listens to [expired].
class SessionEvents {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get expired => _controller.stream;

  void notifyExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
