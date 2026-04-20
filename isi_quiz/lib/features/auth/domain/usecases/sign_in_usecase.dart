import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Either<Failure, User>> call(String email, String password) async {
    if (email.isEmpty) {
      return Left(ValidationFailure('Email cannot be empty', 'email'));
    }
    if (password.isEmpty) {
      return Left(ValidationFailure('Password cannot be empty', 'password'));
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return Left(ValidationFailure('Invalid email format', 'email'));
    }
    
    return await repository.signIn(email, password);
  }
}
