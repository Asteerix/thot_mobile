import 'package:thot/core/utils/either.dart';
import 'package:thot/features/public/auth/shared/models/user.dart';
import 'package:thot/features/public/auth/shared/models/auth_failure.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, User>> login(String email, String password);
  Future<Either<AuthFailure, User>> register(
      String email, String password, String name);
  Future<Either<AuthFailure, void>> logout();
  Future<Either<AuthFailure, String>> refreshToken();
  Future<Either<AuthFailure, User?>> getCurrentUser();
  Stream<User?> get authStateChanges;
}
