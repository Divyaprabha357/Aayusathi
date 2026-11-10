import '../../core/backend/backend_mode.dart';
import '../../core/firebase/firebase_initializer.dart';
import '../models/admin_dashboard_overview.dart';
import 'firebase_admin_dashboard_service.dart';
import 'mock_admin_dashboard_service.dart';

/// Abstract service contract for the Admin Dashboard and Live System Overview.
abstract class AdminDashboardService {
  static AdminDashboardService? _customInstance;

  /// Custom override for unit and widget tests.
  static set instance(AdminDashboardService? service) {
    _customInstance = service;
  }

  /// Resolves the active dashboard service based on backend mode and test overrides.
  static AdminDashboardService get instance {
    if (_customInstance != null) return _customInstance!;
    if (BackendProvider.instance.isFirebaseMode &&
        FirebaseInitializer.isInitialized) {
      return FirebaseAdminDashboardService();
    }
    return MockAdminDashboardService.instance;
  }

  /// Retrieves the current system overview snapshot.
  Future<AdminDashboardOverview> getDashboardOverview();

  /// Real-time stream of the system overview metrics.
  Stream<AdminDashboardOverview> streamDashboardOverview();

  /// Manually forces a fresh fetch from the underlying data source.
  Future<void> refresh();
}
