import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/admin_dashboard_overview.dart';
import '../services/admin_dashboard_service.dart';

/// Controller managing the state, real-time lifecycle, and refresh operations
/// of the Admin Dashboard.
class AdminDashboardController extends ChangeNotifier {
  static final AdminDashboardController instance = AdminDashboardController._();
  AdminDashboardController._();
  factory AdminDashboardController() => instance;

  AdminDashboardOverview? _overview;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  StreamSubscription<AdminDashboardOverview>? _streamSubscription;

  /// Current system overview snapshot.
  AdminDashboardOverview? get overview => _overview;

  /// Whether the initial dashboard data is being loaded.
  bool get isLoading => _isLoading;

  /// Whether a manual refresh is in progress.
  bool get isRefreshing => _isRefreshing;

  /// Error message if data retrieval fails.
  String? get errorMessage => _errorMessage;

  /// Returns true if an error state is active.
  bool get hasError => _errorMessage != null;

  /// Initializes the dashboard data and subscribes to real-time updates.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final initialData = await AdminDashboardService.instance.getDashboardOverview();
      _overview = initialData;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      // Listen for stream updates
      await _streamSubscription?.cancel();
      _streamSubscription = AdminDashboardService.instance
          .streamDashboardOverview()
          .listen(
        (updatedData) {
          _overview = updatedData;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('[AdminDashboardController] Stream error: $err');
          _errorMessage = 'Live data stream interrupted. Click refresh to retry.';
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[AdminDashboardController] Load exception: $e');
      _isLoading = false;
      _errorMessage = 'Unable to load live dashboard data.';
      notifyListeners();
    }
  }

  /// Manually triggers a reload while preventing duplicate concurrent clicks.
  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AdminDashboardService.instance.refresh();
      final fresh = await AdminDashboardService.instance.getDashboardOverview();
      _overview = fresh;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[AdminDashboardController] Refresh error: $e');
      _errorMessage = 'Unable to load live dashboard data.';
    } finally {
      _isRefreshing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retries fetching after an error.
  Future<void> retry() => initialize();

  /// Reset controller state (used for tests and teardown).
  @visibleForTesting
  void resetForTesting() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _overview = null;
    _isLoading = true;
    _isRefreshing = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
