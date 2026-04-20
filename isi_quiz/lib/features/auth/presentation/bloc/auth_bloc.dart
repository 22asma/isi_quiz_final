import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:isi_quiz/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:isi_quiz/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as entity;  // Utilisez un préfixe
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthStatus> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.resetPasswordUseCase,
  }) : super(AuthInitial()) {
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<ResetPasswordEvent>(_onResetPassword);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthStatus> emit) async {
    emit(AuthLoading());
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      
      if (response.user != null) {
        final role = response.user!.userMetadata?['role'] ?? 'Student';
        
        // Utilisez entity.User au lieu de User
        final user = entity.User(
          id: response.user!.id,
          email: response.user!.email ?? '',
          fullName: response.user!.userMetadata?['full_name'],
          university: response.user!.userMetadata?['university'],
          institute: response.user!.userMetadata?['institute'],
          role: role,
        );
        
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Sign in failed'));
      }
    } catch (e) {
      emit(AuthError('Sign in failed: $e'));
    }
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthStatus> emit) async {
    emit(AuthLoading());
    
    final result = await signUpUseCase(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      university: event.university,
      institute: event.institute,
      role: event.role,
    );
    
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onResetPassword(ResetPasswordEvent event, Emitter<AuthStatus> emit) async {
    emit(AuthLoading());
    
    final result = await resetPasswordUseCase(event.email);
    
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(const AuthPasswordReset()),
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthStatus> emit) async {
    await Supabase.instance.client.auth.signOut();
    emit(Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthStatus> emit) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      final role = currentUser.userMetadata?['role'] ?? 'Student';
      // Utilisez entity.User au lieu de User
      final user = entity.User(
        id: currentUser.id,
        email: currentUser.email ?? '',
        fullName: currentUser.userMetadata?['full_name'],
        university: currentUser.userMetadata?['university'],
        institute: currentUser.userMetadata?['institute'],
        role: role,
      );
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  String _mapFailureToMessage(dynamic failure) {
    return failure.toString();
  }
}