import '../../models/audit_log.dart';
import '../audit_repository.dart';

/// In-memory mock implementation of [AuditRepository] for audit event recording.
class MockAuditRepository implements AuditRepository {
  static final MockAuditRepository instance = MockAuditRepository._();
  MockAuditRepository._();
  factory MockAuditRepository() => instance;

  final List<AuditLog> _logs = [];

  @override
  Future<void> logEvent(AuditLog log) async {
    _logs.add(log);
  }

  @override
  Future<List<AuditLog>> getLogsForEntity({
    required String entityType,
    required String entityId,
  }) async {
    return _logs
        .where((l) =>
            l.entityType.toUpperCase() == entityType.toUpperCase() &&
            l.entityId == entityId)
        .toList();
  }

  /// Exposes count for test verification
  int get count => _logs.length;

  /// Exposes all recorded logs for test inspection
  List<AuditLog> get logs => List.unmodifiable(_logs);

  /// Clear all stored audit logs
  void clear() {
    _logs.clear();
  }
}
