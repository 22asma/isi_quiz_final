import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? fullName,
    String? university,
    String? institute,
    String? role,
  });
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, User?>> getCurrentUser();
  Stream<User?> get authStateChanges;
}
