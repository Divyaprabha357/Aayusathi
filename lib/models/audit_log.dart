import 'package:cloud_firestore/cloud_firestore.dart';

/// Actor category initiating an action in the system.
enum AuditActorType {
  kiosk,
  patient,
  doctor,
  admin,
  system;

  String get value => name.toUpperCase();

  static AuditActorType fromString(String val) {
    return AuditActorType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AuditActorType.system,
    );
  }
}

/// Audit event representation persisted under the `auditLogs` collection in Cloud Firestore.
class AuditLog {
  final String auditId;
  final String actorType; // 'KIOSK', 'PATIENT', 'DOCTOR', 'ADMIN', 'SYSTEM'
  final String actorId;
  final String action;
  final String entityType;
  final String entityId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AuditLog({
    required this.auditId,
    required this.actorType,
    required this.actorId,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    this.metadata = const {},
  });

  AuditLog copyWith({
    String? auditId,
    String? actorType,
    String? actorId,
    String? action,
    String? entityType,
    String? entityId,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AuditLog(
      auditId: auditId ?? this.auditId,
      actorType: actorType ?? this.actorType,
      actorId: actorId ?? this.actorId,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auditId': auditId,
      'actorType': actorType,
      'actorId': actorId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'auditId': auditId,
      'actorType': actorType,
      'actorId': actorId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return AuditLog(
      auditId: map['auditId'] as String? ?? '',
      actorType: map['actorType'] as String? ?? 'SYSTEM',
      actorId: map['actorId'] as String? ?? '',
      action: map['action'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      timestamp: parseDate(map['timestamp']),
      metadata: (map['metadata'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? const {},
    );
  }

  factory AuditLog.fromFirestore(Map<String, dynamic> data, [String? documentId]) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null && !map.containsKey('auditId')) {
      map['auditId'] = documentId;
    }
    return AuditLog.fromMap(map);
  }

  @override
  String toString() =>
      'AuditLog(id: $auditId, actor: $actorType/$actorId, action: $action, entity: $entityType/$entityId)';
}
