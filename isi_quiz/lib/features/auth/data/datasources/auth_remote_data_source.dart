import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';

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
  Stream<UserModel?> authStateChanges();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw ServerException('Sign in failed');
      }

      // Get user metadata from profiles table (if exists)
      Map<String, dynamic>? profileData;
      try {
        profileData = await client
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
      } catch (e) {
        // If profiles table doesn't exist, continue without it
        print('Profiles table might not exist yet: $e');
      }

      return UserModel.fromSupabaseUser(response.user!.toJson(), profileData);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('An unexpected error occurred');
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
      print('=== DEBUG SIGN UP ===');
      print('Email: $email');
      print('FullName: $fullName');
      print('University: $university');
      print('Institute: $institute');
      print('Role: $role');
      print('Supabase URL: ${AppConstants.supabaseUrl}');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'university': university,
          'institute': institute,
          'role': role,
        },
      );

      print('Sign up response: ${response.toString()}');
      print('User: ${response.user?.toJson()}');

      if (response.user == null) {
        print('Sign up failed: user is null');
        throw ServerException('Sign up failed');
      }

      // Create profile in profiles table (if table exists)
      try {
        await client.from('profiles').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'university': university,
          'institute': institute,
          'role': role ?? 'Student',
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // If profiles table doesn't exist, continue without it
        print('Profiles table might not exist yet: $e');
      }

      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        university: university,
        institute: institute,
        role: role ?? 'Student',
      );
    } on AuthException catch (e) {
      print('AuthException during sign up: ${e.message}');
      print('AuthException details: ${e.toString()}');
      throw ServerException(e.message);
    } catch (e) {
      print('Unexpected error during sign up: ${e.toString()}');
      print('Error type: ${e.runtimeType}');
      throw ServerException('An unexpected error occurred: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerException('Sign out failed');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to send reset email');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return null;

      Map<String, dynamic>? profileData;
      try {
        profileData = await client
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .single();
      } catch (e) {
        // If profiles table doesn't exist, continue without it
        print('Profiles table might not exist yet: $e');
      }

      return UserModel.fromSupabaseUser(currentUser.toJson(), profileData);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;

      Map<String, dynamic>? profileData;
      try {
        profileData = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
      } catch (e) {
        // If profiles table doesn't exist, continue without it
        print('Profiles table might not exist yet: $e');
      }

      return UserModel.fromSupabaseUser(user.toJson(), profileData);
    });
  }
}
