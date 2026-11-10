import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/doctor_navigation_item.dart';
import '../models/doctor_patient_request.dart';
import '../services/doctor_patient_request_service.dart';
import '../services/doctor_presence_service.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_patient_request_card.dart';
import '../widgets/doctor_sidebar.dart';
import '../widgets/doctor_state_views.dart';

/// Doctor Patient Requests / Incoming OPD Request Queue Screen.
///
/// Displays incoming OPD consultation requests for the active doctor's department.
/// Implements responsive layout, domain filtering, FIFO queue ordering, presence awareness,
/// loading, error, empty, and loaded states with privacy compliance.
class DoctorPatientRequestScreen extends StatefulWidget {
  const DoctorPatientRequestScreen({super.key});

  @override
  State<DoctorPatientRequestScreen> createState() =>
      _DoctorPatientRequestScreenState();
}

class _DoctorPatientRequestScreenState
    extends State<DoctorPatientRequestScreen> {
  bool _isLoading = true;
  String? _acceptingRequestId;
  String? _errorMessage;
  List<DoctorPatientRequest> _requests = [];
  StreamSubscription<List<DoctorPatientRequest>>? _requestsSub;

  final List<DoctorNavigationItem> _navItems = const [
    DoctorNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      routeName: AppRoutes.doctorDashboard,
    ),
    DoctorNavigationItem(
      id: 'patient_requests',
      label: 'Patient Requests',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      routeName: AppRoutes.doctorPatientRequest,
    ),
    DoctorNavigationItem(
      id: 'patient_workspace',
      label: 'Patient Workspace',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
      routeName: AppRoutes.doctorPatientWorkspace,
    ),
    DoctorNavigationItem(
      id: 'consultation',
      label: 'Consultation',
      icon: Icons.video_camera_front_outlined,
      selectedIcon: Icons.video_camera_front_rounded,
      routeName: AppRoutes.doctorConsultation,
    ),
    DoctorNavigationItem(
      id: 'cases',
      label: 'Cases & Visits',
      icon: Icons.folder_open_rounded,
      selectedIcon: Icons.folder_rounded,
      routeName: AppRoutes.doctorCase,
    ),
    DoctorNavigationItem(
      id: 'reports',
      label: 'Reports & Diagnostics',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      routeName: AppRoutes.doctorReports,
    ),
  ];

  @override
  void initState() {
    super.initState();
    DoctorPresenceService.instance.addListener(_onPresenceChanged);
    DoctorSidebarController.instance.addListener(_onSidebarChanged);
    _setupRequestsSubscription();
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    DoctorPresenceService.instance.removeListener(_onPresenceChanged);
    DoctorSidebarController.instance.removeListener(_onSidebarChanged);
    super.dispose();
  }

  void _onPresenceChanged() {
    if (mounted) {
      setState(() {});
      // Refresh requests stream to reflect current presence eligibility
      _setupRequestsSubscription(showLoading: false);
    }
  }

  void _onSidebarChanged() {
    if (mounted) setState(() {});
  }

  void _setupRequestsSubscription({bool showLoading = true}) {
    _requestsSub?.cancel();
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final department =
          DoctorSessionService.instance.activeDepartment ?? 'Cardiology';
      _requestsSub = DoctorPatientRequestService.instance
          .watchPendingRequests(domain: department)
          .listen(
        (results) {
          if (!mounted) return;
          setState(() {
            _requests = results;
            _isLoading = false;
            _errorMessage = null;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Unable to load patient requests. ($e)';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load patient requests. ($e)';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await DoctorPatientRequestService.instance.refreshRequests();
    _setupRequestsSubscription(showLoading: true);
  }

  Future<void> _handleAcceptRequest(DoctorPatientRequest request) async {
    final strings = DoctorLocalizations.of(context);
    final presence = DoctorPresenceService.instance;
    final session = DoctorSessionService.instance;

    if (!presence.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.doctorNotAvailableNotice),
          backgroundColor: DoctorColors.statusBusy,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _acceptingRequestId = request.requestId);

    final doctorId = session.activeDoctorId ?? 'DOC-101';
    final department = session.activeDepartment ?? 'Cardiology';

    try {
      final result =
          await DoctorPatientRequestService.instance.acceptPatientRequest(
        requestId: request.requestId,
        doctorId: doctorId,
        doctorDomain: department,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // 1. Transition presence state machine
        await presence.setInConsultation();
        if (!mounted) return;

        // 2. Feedback notice
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.patientAcceptedNotice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: DoctorColors.brandTeal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
          ),
        );

        // 3. Navigate to Patient Workspace with minimal non-sensitive identifiers
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.doctorPatientWorkspace,
          arguments: {
            'requestId': request.requestId,
            'appointmentId': request.appointmentId,
            'patientId': request.patientId,
            'caseId': request.caseId,
            'queueNumber': request.queueNumber,
            'domain': request.domain,
            'transferId': request.transferId,
            'sourceDepartment': request.sourceDepartment,
            'sourceDoctorName': request.sourceDoctorName,
            'transferReason': request.transferReason,
          },
        );
      } else if (result.isAlreadyAssigned) {
        // Immediately purge from local queue so card vanishes immediately
        setState(() {
          _requests.removeWhere((r) => r.requestId == request.requestId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              request.isTransferRequest
                  ? strings.transferAlreadyAcceptedNotice
                  : strings.patientAlreadyAssignedNotice,
            ),
            backgroundColor: DoctorColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Resync queue with background refresh
        _setupRequestsSubscription(showLoading: false);
        if (!mounted) return;
      } else if (result.isIneligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.notEligibleNotice),
            backgroundColor: DoctorColors.brandOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.isUnavailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.doctorNotAvailableNotice),
            backgroundColor: DoctorColors.statusBusy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? strings.unableToAcceptNotice),
            backgroundColor: DoctorColors.statusBusy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.unableToAcceptNotice),
          backgroundColor: DoctorColors.statusBusy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _acceptingRequestId = null);
      }
    }
  }

  void _onNavigationSelected(DoctorNavigationItem item) {
    if (item.routeName != AppRoutes.doctorPatientRequest) {
      Navigator.of(context).pushReplacementNamed(item.routeName);
    }
  }

  Future<void> _handleLogout() async {
    await DoctorSessionService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.doctorStandby);
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed(AppRoutes.doctorProfile);
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.of(context);
    final presence = DoctorPresenceService.instance;
    final session = DoctorSessionService.instance;

    final doctorName = session.activeDoctorName ??
        session.activeProfile?.name ??
        'Dr. Rajesh Sharma';
    final department = session.activeDepartment ??
        session.activeProfile?.department ??
        'Cardiology';

    return DoctorDesktopScaffold(
      header: DoctorHeader(
        title: strings.patientRequestsTitle,
        subtitle: strings.patientRequestsSubtitle,
        doctorName: doctorName,
        doctorDepartment: department,
        onBack: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard),
        onLogout: _handleLogout,
        onProfileTap: _navigateToProfile,
      ),
      sidebar: DoctorSidebar(
        items: _navItems,
        activeRoute: AppRoutes.doctorPatientRequest,
        isCollapsed: DoctorSidebarController.instance.isCollapsed,
        onToggleCollapse: DoctorSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DoctorTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Department & Queue Control Banner
            _buildQueueControlBar(department: department, strings: strings),

            // 2. Presence Status Advisory Banner (if not Available)
            if (!presence.isAvailable) ...[
              const SizedBox(height: DoctorTheme.space16),
              _buildPresenceAdvisoryBanner(presence: presence, strings: strings),
            ],

            const SizedBox(height: DoctorTheme.space20),

            // 3. Content State (Loading, Error, Empty, or Loaded Grid/List)
            _buildBodyContent(presence: presence, strings: strings),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueControlBar({
    required String department,
    required DoctorStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space20,
        vertical: DoctorTheme.space16,
      ),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius16),
        border: Border.all(color: DoctorColors.borderSubtle),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DoctorColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: DoctorColors.brandTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: DoctorTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Department of $department',
                      style: DoctorTheme.headline2.copyWith(
                        fontSize: 18,
                        color: DoctorColors.brandNavy,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DoctorTheme.space8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DoctorColors.brandOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                      ),
                      child: Text(
                        '${_requests.length} ${strings.pendingRequestsCountLabel}',
                        style: DoctorTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DoctorColors.brandOrange,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Live FIFO queue of waiting patients awaiting physician acceptance.',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DoctorTheme.space16),
          DoctorOutlineButton(
            label: strings.refreshRequestsButton,
            icon: Icons.refresh_rounded,
            height: 38,
            onPressed: _isLoading ? null : _handleRefresh,
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceAdvisoryBanner({
    required DoctorPresenceService presence,
    required DoctorStrings strings,
  }) {
    final isOffline = presence.isOffline;

    final bannerBg = isOffline
        ? DoctorColors.statusOffline.withValues(alpha: 0.08)
        : DoctorColors.statusInConsultation.withValues(alpha: 0.08);

    final bannerBorder = isOffline
        ? DoctorColors.statusOffline.withValues(alpha: 0.3)
        : DoctorColors.statusInConsultation.withValues(alpha: 0.3);

    final bannerIcon = isOffline
        ? Icons.power_settings_new_rounded
        : Icons.video_call_rounded;

    final bannerTone = isOffline
        ? DoctorColors.statusOffline
        : DoctorColors.statusInConsultation;

    final bannerText = isOffline
        ? strings.workstationOfflineNotice
        : strings.workstationInConsultationNotice;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space16,
        vertical: DoctorTheme.space12,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: bannerBorder),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerTone, size: 20),
          const SizedBox(width: DoctorTheme.space12),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                color: bannerTone,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (isOffline) ...[
            const SizedBox(width: DoctorTheme.space12),
            DoctorPrimaryButton(
              label: 'GO AVAILABLE',
              icon: Icons.check_circle_outline_rounded,
              height: 32,
              onPressed: () async {
                await presence.setAvailable();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyContent({
    required DoctorPresenceService presence,
    required DoctorStrings strings,
  }) {
    if (_isLoading) {
      return Container(
        height: 320,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
            ),
            const SizedBox(height: DoctorTheme.space16),
            Text(
              strings.loadingTitle,
              style: DoctorTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: DoctorColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(DoctorTheme.space32),
        decoration: BoxDecoration(
          color: DoctorColors.surface,
          borderRadius: BorderRadius.circular(DoctorTheme.radius16),
          border: Border.all(color: DoctorColors.statusBusy.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DoctorColors.statusBusy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: DoctorColors.statusBusy,
                size: 36,
              ),
            ),
            const SizedBox(height: DoctorTheme.space16),
            Text(
              strings.unableToLoadRequestsTitle,
              style: DoctorTheme.headline2.copyWith(
                fontSize: 18,
                color: DoctorColors.brandNavy,
              ),
            ),
            const SizedBox(height: DoctorTheme.space8),
            Text(
              _errorMessage!,
              style: DoctorTheme.caption.copyWith(
                color: DoctorColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DoctorTheme.space20),
            DoctorPrimaryButton(
              label: strings.retryButton,
              icon: Icons.refresh_rounded,
              onPressed: () => _setupRequestsSubscription(showLoading: true),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return DoctorEmptyView(
        icon: Icons.people_outline_rounded,
        title: strings.noPatientRequestsTitle,
        subtitle: strings.noPatientRequestsSubtitle,
        actionLabel: strings.refreshRequestsButton,
        onAction: _handleRefresh,
      );
    }

    // Loaded State: Responsive list / grid
    final isAcceptEnabled = presence.isAvailable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;

        if (isWide) {
          // 2-column layout
          final halfWidth = (constraints.maxWidth - DoctorTheme.space16) / 2;
          return Wrap(
            spacing: DoctorTheme.space16,
            runSpacing: DoctorTheme.space16,
            children: _requests.map((request) {
              return SizedBox(
                width: halfWidth,
                child: DoctorPatientRequestCard(
                  request: request,
                  isAcceptEnabled: isAcceptEnabled,
                  isLoading: _acceptingRequestId == request.requestId,
                  onAccept: () => _handleAcceptRequest(request),
                ),
              );
            }).toList(),
          );
        } else {
          // Single-column list
          return Column(
            children: _requests.map((request) {
              return Padding(
                padding: const EdgeInsets.only(bottom: DoctorTheme.space16),
                child: DoctorPatientRequestCard(
                  request: request,
                  isAcceptEnabled: isAcceptEnabled,
                  isLoading: _acceptingRequestId == request.requestId,
                  onAccept: () => _handleAcceptRequest(request),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
}
