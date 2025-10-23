abstract class AuthFailure {
  final String message;
  const AuthFailure(this.message);
}
class AuthFailureNetwork extends AuthFailure {
  const AuthFailureNetwork(super.message);
}
class AuthFailureServer extends AuthFailure {
  const AuthFailureServer(super.message);
}
class AuthFailureUnauthorized extends AuthFailure {
  const AuthFailureUnauthorized(super.message);
}
class AuthFailureNotFound extends AuthFailure {
  const AuthFailureNotFound(super.message);
}
class AuthFailureUnknown extends AuthFailure {
  const AuthFailureUnknown(super.message);
}