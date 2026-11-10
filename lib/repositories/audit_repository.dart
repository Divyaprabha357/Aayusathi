import '../models/audit_log.dart';

/// Abstract contract for audit logging and governance event tracking.
abstract class AuditRepository {
  /// Records a critical lifecycle audit event.
  Future<void> logEvent(AuditLog log);

  /// Retrieves audit records for a specific business entity.
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  });
}
