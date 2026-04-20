import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    String? fullName,
    String? university,
    String? institute,
    String? role,
  }) async {
    // Validation
    if (email.isEmpty) {
      return Left(ValidationFailure('Email cannot be empty', 'email'));
    }
    if (password.isEmpty) {
      return Left(ValidationFailure('Password cannot be empty', 'password'));
    }
    if (password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters', 'password'));
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return Left(ValidationFailure('Invalid email format', 'email'));
    }
    if (fullName?.isEmpty ?? true) {
      return Left(ValidationFailure('Full name cannot be empty', 'fullName'));
    }
    
    return await repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      university: university,
      institute: institute,
      role: role,
    );
  }
}
