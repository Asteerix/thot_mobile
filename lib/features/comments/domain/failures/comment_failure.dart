abstract class CommentFailure {
  final String message;
  const CommentFailure(this.message);
  factory CommentFailure.serverError(String message) = CommentFailureServer;
  factory CommentFailure.network(String message) = CommentFailureNetwork;
  factory CommentFailure.unauthorized(String message) =
      CommentFailureUnauthorized;
  factory CommentFailure.notFound(String message) = CommentFailureNotFound;
  factory CommentFailure.unknown(String message) = CommentFailureUnknown;
}
class CommentFailureNetwork extends CommentFailure {
  const CommentFailureNetwork(super.message);
}
class CommentFailureServer extends CommentFailure {
  const CommentFailureServer(super.message);
}
class CommentFailureUnauthorized extends CommentFailure {
  const CommentFailureUnauthorized(super.message);
}
class CommentFailureNotFound extends CommentFailure {
  const CommentFailureNotFound(super.message);
}
class CommentFailureUnknown extends CommentFailure {
  const CommentFailureUnknown(super.message);
}