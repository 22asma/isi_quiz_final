import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthStatus extends Equatable {
  const AuthStatus();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthStatus {}

class AuthLoading extends AuthStatus {}

class Authenticated extends AuthStatus {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthStatus {}

class AuthError extends AuthStatus {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordReset extends AuthStatus {
  const AuthPasswordReset();
}