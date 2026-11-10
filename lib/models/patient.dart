import 'package:cloud_firestore/cloud_firestore.dart';
import '../kiosk/models/patient_identity.dart';

/// Central patient entity matching the Cloud Firestore `patients` collection schema.
/// 
/// Strict Security Rules:
/// - Document ID matches [patientId] (e.g., "AAYU-102938").
/// - Aadhaar numbers are STRICTLY NEVER stored in Firestore documents.
/// - Timestamps are persisted as Firestore [Timestamp] or ISO-8601 strings.
class Patient {
  final String patientId;
  final String name;
  final String dateOfBirth;
  final int age;
  final String gender;
  final String phone;
  final String bloodGroup;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const Patient({
    required this.patientId,
    required this.name,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.phone,
    required this.bloodGroup,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Masked phone number showing only last 4 digits for privacy.
  String get maskedPhone {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.length >= 10) {
      final suffix = clean.substring(clean.length - 4);
      return '+91 ••••• •$suffix';
    }
    return phone;
  }

  Patient copyWith({
    String? patientId,
    String? name,
    String? dateOfBirth,
    int? age,
    String? gender,
    String? phone,
    String? bloodGroup,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Patient(
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converts this [Patient] to a standard JSON map.
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'gender': gender,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Converts this [Patient] to a Firestore document map with native [Timestamp] values.
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'age': age,
      'gender': gender,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Creates a [Patient] from a standard JSON map.
  factory Patient.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Patient(
      patientId: map['patientId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      bloodGroup: map['bloodGroup'] as String? ?? '',
      address: map['address'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Factory constructor parsing from a Cloud Firestore DocumentSnapshot or map.
  factory Patient.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('patientId')) {
      map['patientId'] = documentId;
    }
    return Patient.fromMap(map);
  }

  /// Converts a Kiosk-layer [PatientIdentity] to a Firestore-safe [Patient] model.
  /// Aadhaar number is deliberately omitted from this model.
  factory Patient.fromPatientIdentity(PatientIdentity identity, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return Patient(
      patientId: identity.patientId,
      name: identity.fullName,
      dateOfBirth: identity.dob,
      age: identity.age,
      gender: identity.gender,
      phone: identity.phone,
      bloodGroup: identity.bloodGroup,
      address: identity.address,
      createdAt: timestamp,
      updatedAt: timestamp,
      isActive: true,
    );
  }

  /// Converts this [Patient] to a [PatientIdentity] for the Kiosk session.
  /// Aadhaar is masked or supplied separately by the lookup service.
  PatientIdentity toPatientIdentity({String aadhaarNumber = ''}) {
    return PatientIdentity(
      aadhaarNumber: aadhaarNumber,
      patientId: patientId,
      fullName: name,
      dob: dateOfBirth,
      age: age,
      gender: gender,
      phone: phone,
      address: address,
      bloodGroup: bloodGroup,
      isNewRegistration: false,
    );
  }

  @override
  String toString() => 'Patient(id: $patientId, name: $name, age: $age, phone: $phone)';
}
