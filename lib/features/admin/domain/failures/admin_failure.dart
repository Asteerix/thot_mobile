abstract class AdminFailure {
  final String message;
  const AdminFailure(this.message);
  factory AdminFailure.serverError(String message) = AdminFailureServer;
  factory AdminFailure.networkError(String message) = AdminFailureNetwork;
  factory AdminFailure.unauthorized(String message) = AdminFailureUnauthorized;
  factory AdminFailure.notFound(String message) = AdminFailureNotFound;
  factory AdminFailure.unknown(String message) = AdminFailureUnknown;
}
class AdminFailureNetwork extends AdminFailure {
  const AdminFailureNetwork(super.message);
}
class AdminFailureServer extends AdminFailure {
  const AdminFailureServer(super.message);
}
class AdminFailureUnauthorized extends AdminFailure {
  const AdminFailureUnauthorized(super.message);
}
class AdminFailureNotFound extends AdminFailure {
  const AdminFailureNotFound(super.message);
}
class AdminFailureUnknown extends AdminFailure {
  const AdminFailureUnknown(super.message);
}