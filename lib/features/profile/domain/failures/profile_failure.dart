abstract class ProfileFailure {
  final String message;
  const ProfileFailure(this.message);
  factory ProfileFailure.serverError(String message) = ProfileFailureServer;
  factory ProfileFailure.network(String message) = ProfileFailureNetwork;
  factory ProfileFailure.unauthorized(String message) =
      ProfileFailureUnauthorized;
  factory ProfileFailure.notFound(String message) = ProfileFailureNotFound;
  factory ProfileFailure.unknown(String message) = ProfileFailureUnknown;
}
class ProfileFailureNetwork extends ProfileFailure {
  const ProfileFailureNetwork(super.message);
}
class ProfileFailureServer extends ProfileFailure {
  const ProfileFailureServer(super.message);
}
class ProfileFailureUnauthorized extends ProfileFailure {
  const ProfileFailureUnauthorized(super.message);
}
class ProfileFailureNotFound extends ProfileFailure {
  const ProfileFailureNotFound(super.message);
}
class ProfileFailureUnknown extends ProfileFailure {
  const ProfileFailureUnknown(super.message);
}