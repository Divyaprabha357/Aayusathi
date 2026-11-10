import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/doctor_navigation_item.dart';
import '../models/doctor_profile.dart';
import '../services/doctor_dashboard_metrics_service.dart';
import '../services/doctor_presence_service.dart';
import '../services/doctor_profile_service.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_card.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_sidebar.dart';
import '../widgets/doctor_status_indicator.dart';

/// Doctor Clinical Operational Dashboard Screen.
///
/// Designed as a clean, spacious operational hub containing strictly:
/// 1. Patients Attended Today (KPI card)
/// 2. Workstation Availability (operational console)
/// 3. Patient Requests (shortcut card)
///
/// Detailed physician credentials and workstation telemetry are housed on
/// the dedicated Doctor Profile/Details screen accessed via the top-right menu.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  DoctorProfile? _profile;
  bool _isLoadingProfile = true;
  int _patientsAttendedToday = 0;
  int _pendingRequestsCount = 0;
  bool _isLoadingMetrics = true;
  String? _metricsErrorMessage;

  StreamSubscription<int>? _attendedSubscription;
  StreamSubscription<int>? _pendingSubscription;

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
    _loadProfile();
    _subscribeMetrics();
  }

  @override
  void dispose() {
    _attendedSubscription?.cancel();
    _pendingSubscription?.cancel();
    DoctorPresenceService.instance.removeListener(_onPresenceChanged);
    DoctorSidebarController.instance.removeListener(_onSidebarChanged);
    super.dispose();
  }

  void _onPresenceChanged() {
    if (mounted) {
      setState(() {});
      _subscribeMetrics();
    }
  }

  void _onSidebarChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final sessionProfile = DoctorSessionService.instance.activeProfile;
    if (sessionProfile != null) {
      if (mounted) {
        setState(() {
          _profile = sessionProfile;
          _isLoadingProfile = false;
        });
        _subscribeMetrics();
      }
      return;
    }
    final profile = await DoctorProfileService.instance.getDoctorProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
      _subscribeMetrics();
    }
  }

  void _subscribeMetrics() {
    _attendedSubscription?.cancel();
    _pendingSubscription?.cancel();

    setState(() {
      _isLoadingMetrics = true;
      _metricsErrorMessage = null;
    });

    final session = DoctorSessionService.instance;
    final doctorId = _profile?.doctorId ?? session.activeDoctorId ?? 'DOC-101';
    final department = _profile?.department ?? session.activeDepartment ?? 'Cardiology';
    final metricsService = DoctorDashboardMetricsService.instance;

    _attendedSubscription = metricsService
        .watchPatientsAttendedTodayCount(doctorId: doctorId)
        .listen(
      (count) {
        if (mounted) {
          setState(() {
            _patientsAttendedToday = count;
            _isLoadingMetrics = false;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _metricsErrorMessage = 'Unable to load live dashboard data.';
            _isLoadingMetrics = false;
          });
        }
      },
    );

    _pendingSubscription = metricsService
        .watchPendingRequestsCount(domain: department)
        .listen(
      (count) {
        if (mounted) {
          setState(() {
            _pendingRequestsCount = count;
            _isLoadingMetrics = false;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _metricsErrorMessage = 'Unable to load live dashboard data.';
            _isLoadingMetrics = false;
          });
        }
      },
    );
  }

  void _onNavigationSelected(DoctorNavigationItem item) {
    if (item.routeName != AppRoutes.doctorDashboard) {
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
    final presence = DoctorPresenceService.instance;
    final strings = DoctorLocalizations.of(context);
    final session = DoctorSessionService.instance;

    final doctorName = _profile?.name ?? session.activeDoctorName ?? 'Dr. Rajesh Sharma';
    final department = _profile?.department ?? session.activeDepartment ?? 'Cardiology';

    return DoctorDesktopScaffold(
      header: DoctorHeader(
        title: strings.doctorPortalTitle,
        subtitle: strings.clinicalWorkstation,
        doctorName: doctorName,
        doctorDepartment: department,
        onLogout: _handleLogout,
        onProfileTap: _navigateToProfile,
      ),
      sidebar: DoctorSidebar(
        items: _navItems,
        activeRoute: AppRoutes.doctorDashboard,
        isCollapsed: DoctorSidebarController.instance.isCollapsed,
        onToggleCollapse: DoctorSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DoctorTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(doctorName, department),
                  const SizedBox(height: DoctorTheme.space24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      if (isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildPatientsAttendedCard(strings),
                                ),
                                const SizedBox(width: DoctorTheme.space20),
                                Expanded(
                                  child: _buildPatientRequestsCard(strings),
                                ),
                              ],
                            ),
                            const SizedBox(height: DoctorTheme.space20),
                            _buildAvailabilityCard(presence: presence, strings: strings),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPatientsAttendedCard(strings),
                            const SizedBox(height: DoctorTheme.space20),
                            _buildAvailabilityCard(presence: presence, strings: strings),
                            const SizedBox(height: DoctorTheme.space20),
                            _buildPatientRequestsCard(strings),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner(String doctorName, String department) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space24,
        vertical: DoctorTheme.space20,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DoctorColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: DoctorColors.brandTeal,
              size: 28,
            ),
          ),
          const SizedBox(width: DoctorTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doctor Dashboard',
                  style: DoctorTheme.headline2.copyWith(color: DoctorColors.brandNavy),
                ),
                const SizedBox(height: DoctorTheme.space4),
                Text(
                  'Welcome, $doctorName • Department of $department',
                  style: DoctorTheme.caption.copyWith(color: DoctorColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: DoctorTheme.space12),
          if (DoctorSessionService.instance.isDevelopmentMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DoctorColors.brandOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                border: Border.all(
                  color: DoctorColors.brandOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.code_rounded, size: 12, color: DoctorColors.brandOrange),
                  const SizedBox(width: 4),
                  Text(
                    'DEVELOPMENT MODE',
                    style: DoctorTheme.badgeText.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: DoctorColors.brandOrange,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DoctorTheme.space12),
          ],
          DoctorStatusBadge.fromAvailabilityStatus(
            DoctorPresenceService.instance.status,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsAttendedCard(DoctorStrings strings) {
    return DoctorCard(
      title: 'PATIENTS ATTENDED TODAY',
      subtitle: 'Completed consultations today',
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DoctorColors.brandTeal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.how_to_reg_rounded,
          color: DoctorColors.brandTeal,
          size: 20,
        ),
      ),
      child: _metricsErrorMessage != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: DoctorColors.statusCritical, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _metricsErrorMessage!,
                        style: DoctorTheme.bodyRegular.copyWith(
                          color: DoctorColors.statusCritical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DoctorTheme.space16),
                DoctorSecondaryButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: _subscribeMetrics,
                ),
              ],
            )
          : _isLoadingMetrics
              ? const SizedBox(
                  height: 90,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(DoctorColors.brandTeal),
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_patientsAttendedToday',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: DoctorColors.brandNavy,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: DoctorTheme.space12),
                    Text(
                      'Patients',
                      style: DoctorTheme.bodyBold.copyWith(
                        color: DoctorColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DoctorTheme.space12),
                Text(
                  'Total outpatient consultations completed during this terminal shift.',
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textMuted,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvailabilityCard({
    required DoctorPresenceService presence,
    required DoctorStrings strings,
  }) {
    final isAvailable = presence.isAvailable;
    final isInConsultation = presence.isInConsultation;
    final isOffline = presence.isOffline;

    String statusDescription;
    IconData statusIcon;
    Color statusTone;

    if (isInConsultation) {
      statusDescription = strings.currentlyInConsultation;
      statusIcon = Icons.video_call_rounded;
      statusTone = DoctorColors.statusInConsultation;
    } else if (isAvailable) {
      statusDescription = strings.readyForPatients;
      statusIcon = Icons.check_circle_outline_rounded;
      statusTone = DoctorColors.statusAvailable;
    } else if (isOffline) {
      statusDescription = 'Workstation is offline. Not accepting OPD requests.';
      statusIcon = Icons.power_settings_new_rounded;
      statusTone = DoctorColors.statusOffline;
    } else {
      statusDescription = 'Workstation is online. Ready to accept patient requests.';
      statusIcon = Icons.wifi_rounded;
      statusTone = DoctorColors.statusOnline;
    }

    return DoctorCard(
      title: 'WORKSTATION AVAILABILITY',
      subtitle: 'Live terminal queue acceptance',
      trailing: DoctorStatusBadge.fromAvailabilityStatus(presence.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusTone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
              border: Border.all(color: statusTone.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusTone, size: 22),
                const SizedBox(width: DoctorTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presence.status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusTone,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDescription,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),
          // OPD Patient Acceptance Toggle
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorTheme.space16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: DoctorColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
              border: Border.all(color: DoctorColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OPD Patient Acceptance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: DoctorColors.brandNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isInConsultation
                            ? 'Locked during consultation'
                            : (isAvailable ? 'Currently accepting requests' : 'Workstation offline'),
                        style: DoctorTheme.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAvailable || isInConsultation,
                  activeThumbColor: DoctorColors.brandTeal,
                  activeTrackColor: DoctorColors.backgroundSecondary,
                  onChanged: isInConsultation
                      ? null
                      : (val) async {
                          if (val) {
                            await presence.setAvailable();
                          } else {
                            await presence.goOffline();
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),
          // Appropriate availability action: GO OFFLINE or GO AVAILABLE
          SizedBox(
            width: double.infinity,
            child: DoctorOutlineButton(
              label: isAvailable ? 'GO OFFLINE' : 'GO AVAILABLE',
              icon: isAvailable ? Icons.power_settings_new_rounded : Icons.check_circle_outline_rounded,
              color: isAvailable ? DoctorColors.statusBusy : DoctorColors.brandTeal,
              onPressed: isInConsultation
                  ? null
                  : () async {
                      if (isAvailable) {
                        await presence.goOffline();
                      } else {
                        await presence.setAvailable();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientRequestsCard(DoctorStrings strings) {
    return DoctorCard(
      title: 'PATIENT REQUESTS',
      subtitle: 'OPD consultation requests',
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DoctorColors.brandOrange.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.people_alt_outlined,
          color: DoctorColors.brandOrange,
          size: 20,
        ),
      ),
      child: _metricsErrorMessage != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: DoctorColors.statusCritical, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _metricsErrorMessage!,
                        style: DoctorTheme.bodyRegular.copyWith(
                          color: DoctorColors.statusCritical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DoctorTheme.space16),
                DoctorSecondaryButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: _subscribeMetrics,
                ),
              ],
            )
          : _isLoadingMetrics
              ? const SizedBox(
                  height: 120,
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(DoctorColors.brandOrange),
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_pendingRequestsCount',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: DoctorColors.brandOrange,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: DoctorTheme.space12),
                    Text(
                      'Pending Requests',
                      style: DoctorTheme.bodyBold.copyWith(
                        color: DoctorColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DoctorTheme.space16),
                SizedBox(
                  width: double.infinity,
                  child: DoctorPrimaryButton(
                    label: 'VIEW REQUESTS →',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.doctorPatientRequest);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
