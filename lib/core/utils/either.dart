sealed class Either<L, R> {
  const Either();
  T fold<T>(T Function(L) left, T Function(R) right);
}
final class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  @override
  T fold<T>(T Function(L) left, T Function(R) right) => left(value);
}
final class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  @override
  T fold<T>(T Function(L) left, T Function(R) right) => right(value);
}