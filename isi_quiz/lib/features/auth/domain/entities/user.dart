import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? university;
  final String? institute;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.university,
    this.institute,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        university,
        institute,
        role,
        createdAt,
        updatedAt,
      ];

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? university,
    String? institute,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      institute: institute ?? this.institute,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Ajoutez ces getters à la classe User existante
bool get isInstructor => role?.toLowerCase() == 'instructor';
bool get isStudent => role?.toLowerCase() == 'student';
}
