import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/university_data_complete.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
    String? university,
    String? institute,
    String? role,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<UserModel?> getCurrentUser();
  Future<void> resendVerificationEmail(String email);
  Future<UserModel> verifyOtp(String email, String token); // ✅ AJOUTÉ
  Stream<UserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  void _validateEmailDomain(String email, String? institute, String? university) {
    if (institute == null || university == null) return;

    final faculties = UniversityData.getFacultiesForUniversity(university);
    final faculty = faculties.firstWhere(
      (f) => f.name == institute,
      orElse: () => Faculty('', '', ''),
    );

    if (faculty.emailDomain.isEmpty) return;

    final emailDomain = email.split('@').last;

    if (institute.contains('ISI') || institute.contains('Institut Supérieur d\'Informatique')) {
      if (emailDomain != 'etudiant-isi.utm.tn' && emailDomain != 'utm.tn') {
        throw ServerException(
          'Your email must end with @etudiant-isi.utm.tn (students) or @utm.tn (staff) for ISI',
        );
      }
    } else {
      final expectedDomain = faculty.emailDomain.contains('@')
          ? faculty.emailDomain.split('@').last
          : faculty.emailDomain;

      if (emailDomain != expectedDomain) {
        throw ServerException(
          'Your email must end with @$expectedDomain for ${faculty.abbreviation}',
        );
      }
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
    String? university,
    String? institute,
    String? role,
  }) async {
    try {
      _validateEmailDomain(email, institute, university);

      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? '',
          'university': university ?? '',
          'institute': institute ?? '',
          'role': role ?? 'Student',
        },
      );

      if (response.user == null) {
        throw ServerException('Sign up failed: no user returned');
      }

      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        fullName: fullName,
        university: university,
        institute: institute,
        role: role ?? 'Student',
        isEmailVerified: response.user!.emailConfirmedAt != null,
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Sign up failed: $e');
    }
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw ServerException('Sign in failed');
      }

      if (response.user!.emailConfirmedAt == null) {
        await supabaseClient.auth.signOut();
        throw ServerException('Please verify your email before signing in.');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Sign in failed: $e');
    }
  }

  // ✅ AJOUTÉ : vérification OTP
  @override
  Future<UserModel> verifyOtp(String email, String token) async {
    try {
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (response.user == null) {
        throw ServerException('Verification failed');
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Verification failed: $e');
    }
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    try {
      await supabaseClient.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      throw ServerException('Failed to get current user: $e');
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return supabaseClient.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    });
  }
}