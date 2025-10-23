abstract class SearchFailure {
  final String message;
  const SearchFailure(this.message);
}
class SearchFailureNetwork extends SearchFailure {
  const SearchFailureNetwork(super.message);
}
class SearchFailureServer extends SearchFailure {
  const SearchFailureServer(super.message);
}
class SearchFailureUnauthorized extends SearchFailure {
  const SearchFailureUnauthorized(super.message);
}
class SearchFailureNotFound extends SearchFailure {
  const SearchFailureNotFound(super.message);
}
class SearchFailureUnknown extends SearchFailure {
  const SearchFailureUnknown(super.message);
}