import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.university,
    super.institute,
    super.role,
    super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      university: json['university'] as String?,
      institute: json['institute'] as String?,
      role: json['role'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'university': university,
      'institute': institute,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromSupabaseUser(Map<String, dynamic> user, Map<String, dynamic>? metadata) {
    return UserModel(
      id: user['id'] as String,
      email: user['email'] as String,
      fullName: metadata?['full_name'] as String?,
      university: metadata?['university'] as String?,
      institute: metadata?['institute'] as String?,
      role: metadata?['role'] as String?,
      createdAt: user['created_at'] != null 
          ? DateTime.parse(user['created_at'] as String)
          : null,
      updatedAt: user['updated_at'] != null
          ? DateTime.parse(user['updated_at'] as String)
          : null,
    );
  }
}
