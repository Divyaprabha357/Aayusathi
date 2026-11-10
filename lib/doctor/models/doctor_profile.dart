import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';

/// Clinical availability statuses for the Doctor Workstation.
enum DoctorAvailabilityStatus {
  offline,
  online,
  available,
  inConsultation;

  String get value => name;

  String get label {
    switch (this) {
      case DoctorAvailabilityStatus.offline:
        return 'Offline';
      case DoctorAvailabilityStatus.online:
        return 'Online';
      case DoctorAvailabilityStatus.available:
        return 'Available';
      case DoctorAvailabilityStatus.inConsultation:
        return 'In Consultation';
    }
  }

  Color get color {
    switch (this) {
      case DoctorAvailabilityStatus.offline:
        return DoctorColors.statusOffline;
      case DoctorAvailabilityStatus.online:
        return DoctorColors.statusOnline;
      case DoctorAvailabilityStatus.available:
        return DoctorColors.statusAvailable;
      case DoctorAvailabilityStatus.inConsultation:
        return DoctorColors.statusInConsultation;
    }
  }

  IconData get icon {
    switch (this) {
      case DoctorAvailabilityStatus.offline:
        return Icons.circle_outlined;
      case DoctorAvailabilityStatus.online:
        return Icons.wifi_rounded;
      case DoctorAvailabilityStatus.available:
        return Icons.check_circle_rounded;
      case DoctorAvailabilityStatus.inConsultation:
        return Icons.record_voice_over_rounded;
    }
  }

  bool get isOnline => this != DoctorAvailabilityStatus.offline;
  bool get isAvailable => this == DoctorAvailabilityStatus.available;
  bool get isInConsultation => this == DoctorAvailabilityStatus.inConsultation;
  bool get isOffline => this == DoctorAvailabilityStatus.offline;

  static DoctorAvailabilityStatus fromString(String? val) {
    if (val == null) return DoctorAvailabilityStatus.offline;
    return DoctorAvailabilityStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DoctorAvailabilityStatus.offline,
    );
  }
}

/// Admin-created Doctor Profile model representing an authorized physician
/// in Cloud Firestore under `/doctors/{doctorId}`.
///
/// CRITICAL SECURITY MANDATES:
/// 1. Passwords are NEVER stored in this model or in Cloud Firestore.
///    Firebase Authentication owns all password credentials.
/// 2. Doctors cannot self-register; accounts are exclusively provisioned by Admin.
/// 3. Unique codes are normalized (trimmed and uppercased) for deterministic lookup.
class DoctorProfile {
  final String doctorId;
  final String doctorUniqueCode;
  final String name;
  final String qualification;
  final String department;
  final String registeredPhone;
  final String email;
  final bool isActive;
  final DoctorAvailabilityStatus availabilityStatus;
  final int clinicalAuthorityLevel;
  final String authUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorProfile({
    required this.doctorId,
    required this.doctorUniqueCode,
    required this.name,
    required this.qualification,
    required this.department,
    required this.registeredPhone,
    required this.email,
    this.isActive = true,
    this.availabilityStatus = DoctorAvailabilityStatus.available,
    this.clinicalAuthorityLevel = 1,
    required this.authUid,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Normalizes Doctor Unique Code for consistent targeted lookup.
  static String normalizeCode(String rawCode) {
    return rawCode.trim().toUpperCase();
  }

  /// Authority Level helpers
  bool get isStandardDoctor => clinicalAuthorityLevel == 1;
  bool get isSeniorDoctor => clinicalAuthorityLevel == 2;
  bool get isSpecialistHigherAuthority => clinicalAuthorityLevel >= 3;

  String get authorityLevelDisplay {
    switch (clinicalAuthorityLevel) {
      case 2:
        return 'Authority Level 2 (Senior Doctor)';
      case 3:
        return 'Authority Level 3 (Specialist / Higher Authority)';
      case 1:
      default:
        return 'Authority Level 1 (Standard Doctor)';
    }
  }

  /// Privacy-safe masked phone representation (e.g. '******4321').
  String get maskedPhone {
    final cleanPhone = registeredPhone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.length <= 4) {
      return '******';
    }
    final lastFour = cleanPhone.substring(cleanPhone.length - 4);
    return '******$lastFour';
  }

  DoctorProfile copyWith({
    String? doctorId,
    String? doctorUniqueCode,
    String? name,
    String? qualification,
    String? department,
    String? registeredPhone,
    String? email,
    bool? isActive,
    DoctorAvailabilityStatus? availabilityStatus,
    int? clinicalAuthorityLevel,
    String? authUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DoctorProfile(
      doctorId: doctorId ?? this.doctorId,
      doctorUniqueCode: doctorUniqueCode ?? this.doctorUniqueCode,
      name: name ?? this.name,
      qualification: qualification ?? this.qualification,
      department: department ?? this.department,
      registeredPhone: registeredPhone ?? this.registeredPhone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      clinicalAuthorityLevel: clinicalAuthorityLevel ?? this.clinicalAuthorityLevel,
      authUid: authUid ?? this.authUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorUniqueCode': normalizeCode(doctorUniqueCode),
      'name': name,
      'qualification': qualification,
      'department': department,
      'registeredPhone': registeredPhone,
      'email': email,
      'isActive': isActive,
      'availabilityStatus': availabilityStatus.value,
      'clinicalAuthorityLevel': clinicalAuthorityLevel,
      'authUid': authUid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Serializes clean doctor identity for Cloud Firestore.
  /// Strictly avoids persisting any passwords or credentials.
  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'doctorUniqueCode': normalizeCode(doctorUniqueCode),
      'name': name,
      'qualification': qualification,
      'department': department,
      'registeredPhone': registeredPhone,
      'email': email,
      'isActive': isActive,
      'availabilityStatus': availabilityStatus.value,
      'clinicalAuthorityLevel': clinicalAuthorityLevel,
      'authUid': authUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final id = docId ?? (map['doctorId'] as String? ?? '');
    final code = map['doctorUniqueCode'] as String? ?? (map['code'] as String? ?? '');

    return DoctorProfile(
      doctorId: id,
      doctorUniqueCode: normalizeCode(code),
      name: map['name'] as String? ?? '',
      qualification: map['qualification'] as String? ?? '',
      department: map['department'] as String? ?? (map['specialization'] as String? ?? 'general_medicine'),
      registeredPhone: map['registeredPhone'] as String? ?? (map['phone'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      availabilityStatus: DoctorAvailabilityStatus.fromString(
        map['availabilityStatus'] as String? ?? (map['isAvailable'] == true ? 'available' : 'offline'),
      ),
      clinicalAuthorityLevel: map['clinicalAuthorityLevel'] as int? ?? 1,
      authUid: map['authUid'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory DoctorProfile.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    return DoctorProfile.fromMap(data, docId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorProfile &&
          runtimeType == other.runtimeType &&
          doctorId == other.doctorId &&
          doctorUniqueCode == other.doctorUniqueCode &&
          authUid == other.authUid;

  @override
  int get hashCode => doctorId.hashCode ^ doctorUniqueCode.hashCode ^ authUid.hashCode;

  @override
  String toString() =>
      'DoctorProfile(id: $doctorId, code: $doctorUniqueCode, name: $name, dept: $department, level: $clinicalAuthorityLevel, active: $isActive)';
}
