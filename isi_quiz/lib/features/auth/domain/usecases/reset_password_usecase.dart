import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/errors/failures.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    if (email.isEmpty) {
      return Left(ValidationFailure('Email cannot be empty', 'email'));
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return Left(ValidationFailure('Invalid email format', 'email'));
    }
    
    return await repository.resetPassword(email);
  }
}
