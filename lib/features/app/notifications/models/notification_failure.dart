abstract class NotificationFailure {
  final String message;
  const NotificationFailure(this.message);
  factory NotificationFailure.serverError(String message) =
      NotificationFailureServer;
  factory NotificationFailure.networkError(String message) =
      NotificationFailureNetwork;
  factory NotificationFailure.unauthorized(String message) =
      NotificationFailureUnauthorized;
  factory NotificationFailure.notFound(String message) =
      NotificationFailureNotFound;
  factory NotificationFailure.unknown(String message) =
      NotificationFailureUnknown;
}
class NotificationFailureNetwork extends NotificationFailure {
  const NotificationFailureNetwork(super.message);
}
class NotificationFailureServer extends NotificationFailure {
  const NotificationFailureServer(super.message);
}
class NotificationFailureUnauthorized extends NotificationFailure {
  const NotificationFailureUnauthorized(super.message);
}
class NotificationFailureNotFound extends NotificationFailure {
  const NotificationFailureNotFound(super.message);
}
class NotificationFailureUnknown extends NotificationFailure {
  const NotificationFailureUnknown(super.message);
}