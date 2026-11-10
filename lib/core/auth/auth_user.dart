import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Role taxonomy across the AAYUSATHI ecosystem.
enum UserRole {
  kiosk,
  patient,
  doctor,
  admin;

  String get value => name;

  static UserRole fromString(String? val) {
    if (val == null) return UserRole.patient;
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => UserRole.patient,
    );
  }
}

/// Represents an authenticated actor identity in AAYUSATHI.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
    this.isAnonymous = false,
    this.createdAt,
    this.lastSignInAt,
  });

  bool get isKiosk => role == UserRole.kiosk;
  bool get isDoctor => role == UserRole.doctor;
  bool get isAdmin => role == UserRole.admin;
  bool get isPatient => role == UserRole.patient;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isAnonymous': isAnonymous,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastSignInAt != null) 'lastSignInAt': lastSignInAt!.toIso8601String(),
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return AuthUser(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
      lastSignInAt: parseDate(map['lastSignInAt']),
    );
  }

  /// Converts a native Firebase Auth [User] into the domain [AuthUser].
  factory AuthUser.fromFirebaseUser(fb.User user, {UserRole? role}) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: role ?? (user.isAnonymous ? UserRole.kiosk : UserRole.patient),
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  @override
  String toString() =>
      'AuthUser(uid: $uid, role: ${role.name}, anonymous: $isAnonymous, email: $email)';
}
