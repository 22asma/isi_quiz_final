import '../../domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserModel extends User {
  final bool isEmailVerified;

  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.university,
    super.institute,
    super.role,
    super.createdAt,
    super.updatedAt,
    this.isEmailVerified = false,
  });

  factory UserModel.fromSupabaseUser(supabase.User user) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'],
      university: user.userMetadata?['university'],
      institute: user.userMetadata?['institute'],
      role: user.userMetadata?['role'] ?? 'Student',
      createdAt: DateTime.tryParse(user.createdAt),
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }

  factory UserModel.fromProfileMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      university: map['university'],
      institute: map['institute'],
      role: map['role'] ?? 'Student',
      isEmailVerified: map['is_email_verified'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'university': university,
      'institute': institute,
      'role': role,
      'is_email_verified': isEmailVerified,
    };
  }
}