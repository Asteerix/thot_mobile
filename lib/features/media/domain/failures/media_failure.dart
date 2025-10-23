abstract class MediaFailure {
  final String message;
  const MediaFailure(this.message);
}
class MediaFailureNetwork extends MediaFailure {
  const MediaFailureNetwork(super.message);
}
class MediaFailureServer extends MediaFailure {
  const MediaFailureServer(super.message);
}
class MediaFailureUnauthorized extends MediaFailure {
  const MediaFailureUnauthorized(super.message);
}
class MediaFailureNotFound extends MediaFailure {
  const MediaFailureNotFound(super.message);
}
class MediaFailureUnknown extends MediaFailure {
  const MediaFailureUnknown(super.message);
}