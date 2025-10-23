abstract class PostFailure {
  final String message;
  const PostFailure(this.message);
}
class PostFailureNetwork extends PostFailure {
  const PostFailureNetwork(super.message);
}
class PostFailureServer extends PostFailure {
  const PostFailureServer(super.message);
}
class PostFailureUnauthorized extends PostFailure {
  const PostFailureUnauthorized(super.message);
}
class PostFailureNotFound extends PostFailure {
  const PostFailureNotFound(super.message);
}
class PostFailureUnknown extends PostFailure {
  const PostFailureUnknown(super.message);
}