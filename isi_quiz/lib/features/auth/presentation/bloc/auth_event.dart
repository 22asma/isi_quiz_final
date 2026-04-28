import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;
  const SignInEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? university;
  final String? institute;
  final String role;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.fullName,
    this.university,
    this.institute,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, university, institute, role];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  const ResetPasswordEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResendVerificationEmailEvent extends AuthEvent {
  final String email;
  const ResendVerificationEmailEvent({required this.email});

  @override
  List<Object?> get props => [email];
}

// ✅ AJOUTÉ : vérification OTP (6 chiffres reçus par email)
class VerifyOtpEvent extends AuthEvent {
  final String email;
  final String token;
  const VerifyOtpEvent({required this.email, required this.token});

  @override
  List<Object?> get props => [email, token];
}

class SignOutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}