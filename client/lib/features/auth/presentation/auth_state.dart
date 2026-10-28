import '../data/models/app_user.dart';

sealed class AuthState {
  const AuthState();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AppUser user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}
