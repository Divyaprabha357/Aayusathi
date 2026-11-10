import 'package:cloud_firestore/cloud_firestore.dart';

/// Doctor model representing a medical professional within the AAYUSATHI ecosystem.
/// 
/// Privacy Rule:
/// - Doctor details (name, cabin, doctorId) are strictly internal and must
///   NEVER be displayed on the patient-facing Kiosk queue confirmation screen.
class Doctor {
  final String doctorId;
  final String name;
  final String specialization;
  final List<String> domains;
  final bool isActive;
  final bool isAvailable;
  final int currentQueueCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Doctor({
    required this.doctorId,
    required this.name,
    required this.specialization,
    required this.domains,
    this.isActive = true,
    this.isAvailable = true,
    this.currentQueueCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Doctor copyWith({
    String? doctorId,
    String? name,
    String? specialization,
    List<String>? domains,
    bool? isActive,
    bool? isAvailable,
    int? currentQueueCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Doctor(
      doctorId: doctorId ?? this.doctorId,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      domains: domains ?? this.domains,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      currentQueueCount: currentQueueCount ?? this.currentQueueCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'name': name,
      'specialization': specialization,
      'domains': domains,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'currentQueueCount': currentQueueCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'name': name,
      'specialization': specialization,
      'domains': domains,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'currentQueueCount': currentQueueCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return Doctor(
      doctorId: map['doctorId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      specialization: map['specialization'] as String? ?? '',
      domains: (map['domains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: map['isActive'] as bool? ?? true,
      isAvailable: map['isAvailable'] as bool? ?? true,
      currentQueueCount: (map['currentQueueCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory Doctor.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('doctorId')) {
      map['doctorId'] = documentId;
    }
    return Doctor.fromMap(map);
  }

  @override
  String toString() =>
      'Doctor(id: $doctorId, name: $name, spec: $specialization, available: $isAvailable)';
}
