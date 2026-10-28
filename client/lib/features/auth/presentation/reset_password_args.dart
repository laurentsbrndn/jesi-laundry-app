/// `extra` of the reset-password route.
class ResetPasswordArgs {
  const ResetPasswordArgs({
    required this.email,
    required this.retryAfterSeconds,
  });

  final String email;

  /// Cooldown returned by forgot-password before another code may be requested.
  final int retryAfterSeconds;
}
