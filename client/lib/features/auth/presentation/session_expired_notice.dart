import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the session ended because the server rejected the tokens. The
/// login screen shows a one-time snackbar and then calls [consume].
final sessionExpiredNoticeProvider =
    NotifierProvider<SessionExpiredNotice, bool>(SessionExpiredNotice.new);

class SessionExpiredNotice extends Notifier<bool> {
  @override
  bool build() => false;

  void raise() => state = true;

  void consume() => state = false;
}
