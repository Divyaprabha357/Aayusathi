import '../core/constants/app_constants.dart';

/// Base user model representing an authenticated actor across the AAYUSATHI platform.
class User {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final AppInterfaceType role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      role: AppInterfaceType.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => AppInterfaceType.patient,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
