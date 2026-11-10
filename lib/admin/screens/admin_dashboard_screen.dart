import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_active_cases_card.dart';
import '../widgets/admin_availability_table.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_escalation_empty_state.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_waiting_appointments_card.dart';

/// Admin Clinical Operational Governance Dashboard Screen (Phase A3).
///
/// Designed as a clean, responsive desktop administrative portal containing:
/// 1. System Overview (Live Real-Time KPI cards)
/// 2. Doctor Management Action Cards (Add Doctor, Manage Doctors)
/// 3. Waiting Appointments Queue (Privacy-Safe Summary) & Active Cases Breakdown
/// 4. Doctor Specialty Availability Table (8 OPD domains with presence telemetry)
/// 5. Escalation Safeguard Monitoring
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardController _dashboardController =
      AdminDashboardController.instance;

  final List<AdminNavigationItem> _navItems = const [
    AdminNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      routeName: AppRoutes.adminDashboard,
    ),
    AdminNavigationItem(
      id: 'doctors',
      label: 'Doctors',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      routeName: AppRoutes.adminDoctors,
    ),
    AdminNavigationItem(
      id: 'availability',
      label: 'Availability',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available_rounded,
      routeName: AppRoutes.adminAvailability,
    ),
    AdminNavigationItem(
      id: 'appointment_escalations',
      label: 'Appointment Escalations',
      icon: Icons.notification_important_outlined,
      selectedIcon: Icons.notification_important_rounded,
      routeName: AppRoutes.adminAppointmentEscalations,
    ),
    AdminNavigationItem(
      id: 'case_escalations',
      label: 'Case Escalations',
      icon: Icons.warning_amber_rounded,
      selectedIcon: Icons.warning_rounded,
      routeName: AppRoutes.adminCaseEscalations,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!AdminAuthService.instance.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
        }
      });
      return;
    }
    AdminSidebarController.instance.addListener(_onStateChanged);
    _dashboardController.addListener(_onStateChanged);
    _dashboardController.initialize();
  }

  @override
  void dispose() {
    AdminSidebarController.instance.removeListener(_onStateChanged);
    _dashboardController.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    if (item.routeName != AppRoutes.adminDashboard) {
      Navigator.of(context).pushReplacementNamed(item.routeName);
    }
  }

  Future<void> _handleLogout() async {
    await AdminAuthService.instance.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.adminStandby,
        (route) => false,
      );
    }
  }

  void _navigateToAddDoctor() {
    Navigator.of(context).pushNamed(AppRoutes.adminDoctorsAdd);
  }

  void _navigateToManageDoctors() {
    Navigator.of(context).pushNamed(AppRoutes.adminDoctors);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final overview = _dashboardController.overview;
    final isLoading = _dashboardController.isLoading;

    return AdminDesktopScaffold(
      header: AdminHeader(
        title: strings.adminPortalTitle,
        subtitle: strings.centralAdminConsole,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: AppRoutes.adminDashboard,
        isCollapsed: AdminSidebarController.instance.isCollapsed,
        onToggleCollapse: AdminSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome & Governance Banner with Live Telemetry Status
            _buildWelcomeBanner(strings, overview?.lastUpdated),
            const SizedBox(height: AdminTheme.space16),

            // 2. Error Banner (if stream/fetch encountered issues)
            if (_dashboardController.hasError) ...[
              _buildErrorBanner(strings),
              const SizedBox(height: AdminTheme.space16),
            ],

            // 3. System Overview (Real-time KPI Cards)
            _buildSystemOverviewSection(strings, overview, isLoading),
            const SizedBox(height: AdminTheme.space24),

            // 4. Doctor Action Cards (Add Doctor & Manage Doctors)
            _buildDoctorActionsSection(strings),
            const SizedBox(height: AdminTheme.space24),

            // 5. Waiting Appointments (Queue) & Active Cases Summary
            _buildOperationalTelemetrySection(strings, overview, isLoading),
            const SizedBox(height: AdminTheme.space24),

            // 6. Doctor Availability Section (8 Specialties)
            _buildAvailabilitySection(strings, overview?.domainAvailability, isLoading),
            const SizedBox(height: AdminTheme.space24),

            // 7. Escalation Safeguard Monitoring
            _buildEscalationsSection(strings, overview),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(dynamic strings, DateTime? lastUpdated) {
    final isRefreshing = _dashboardController.isRefreshing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space24,
        vertical: AdminTheme.space20,
      ),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AdminColors.brandTeal,
              size: 28,
            ),
          ),
          const SizedBox(width: AdminTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: AdminTheme.headline2.copyWith(color: AdminColors.brandNavy),
                ),
                const SizedBox(height: AdminTheme.space4),
                Text(
                  'Hospital Governance Console • System Administration & Telemetry Oversight',
                  style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminTheme.space12),

          // Live Telemetry Sync Pill & Refresh Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminColors.statusAvailable,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lastUpdated != null
                      ? 'SYNCED ${_formatTime(lastUpdated)}'
                      : 'LIVE TELEMETRY',
                  style: AdminTheme.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.brandNavy,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: 'Refresh Telemetry',
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AdminColors.brandTeal,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: AdminColors.textSecondary,
                          ),
                    onPressed: isRefreshing
                        ? null
                        : () => _dashboardController.refresh(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminTheme.space12),

          // Active Session Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AdminColors.brandTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(
                color: AdminColors.brandTeal.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 14,
                  color: AdminColors.brandTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE SESSION',
                  style: AdminTheme.badgeText.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.brandTeal,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(dynamic strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space16,
        vertical: AdminTheme.space12,
      ),
      decoration: BoxDecoration(
        color: AdminColors.statusCritical.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(
          color: AdminColors.statusCritical.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AdminColors.statusCritical,
            size: 20,
          ),
          const SizedBox(width: AdminTheme.space12),
          Expanded(
            child: Text(
              _dashboardController.errorMessage ??
                  'Live data stream interrupted. Click retry to reconnect.',
              style: AdminTheme.bodyRegular.copyWith(
                fontSize: 13,
                color: AdminColors.statusCritical,
              ),
            ),
          ),
          const SizedBox(width: AdminTheme.space12),
          AdminSecondaryButton(
            label: 'RETRY',
            height: 32,
            icon: Icons.refresh_rounded,
            onPressed: () => _dashboardController.retry(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverviewSection(
    dynamic strings,
    dynamic overview,
    bool isLoading,
  ) {
    final registeredDocs = overview?.registeredDoctors ?? 0;
    final onlineDocs = overview?.onlineDoctors ?? 0;
    final waitingAppts = overview?.waitingAppointments ?? 0;
    final activeCases = overview?.activeCases ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 18, color: AdminColors.brandTeal),
            const SizedBox(width: AdminTheme.space8),
            Text(
              strings.systemOverview,
              style: AdminTheme.headline2.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminColors.brandNavy,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminTheme.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1150;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: AdminKpiCard(
                      title: strings.totalDoctors,
                      value: '$registeredDocs',
                      subtitle: strings.totalDoctorsDesc,
                      icon: Icons.people_outline_rounded,
                      accentColor: AdminColors.brandTeal,
                      badgeText: 'Active Roster',
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: AdminKpiCard(
                      title: strings.availableDoctors,
                      value: '$onlineDocs',
                      subtitle: strings.availableDoctorsDesc,
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: AdminColors.statusAvailable,
                      badgeText: onlineDocs > 0 ? 'Online' : 'Offline',
                      badgeColor: onlineDocs > 0
                          ? AdminColors.statusAvailable
                          : AdminColors.textMuted,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: AdminKpiCard(
                      title: strings.pendingAppointments,
                      value: '$waitingAppts',
                      subtitle: strings.pendingAppointmentsDesc,
                      icon: Icons.hourglass_top_rounded,
                      accentColor: AdminColors.brandOrange,
                      badgeText: waitingAppts > 0 ? 'In Queue' : 'Clear',
                      badgeColor: waitingAppts > 0
                          ? AdminColors.brandOrange
                          : AdminColors.statusNormal,
                      isLoading: isLoading,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: AdminKpiCard(
                      title: strings.activeEscalations,
                      value: '$activeCases',
                      subtitle: strings.activeCasesDesc,
                      icon: Icons.folder_shared_outlined,
                      accentColor: AdminColors.brandNavy,
                      badgeText: activeCases > 0 ? 'Open Cases' : 'Resolved',
                      badgeColor: AdminColors.brandNavy,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminKpiCard(
                          title: strings.totalDoctors,
                          value: '$registeredDocs',
                          subtitle: strings.totalDoctorsDesc,
                          icon: Icons.people_outline_rounded,
                          accentColor: AdminColors.brandTeal,
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space16),
                      Expanded(
                        child: AdminKpiCard(
                          title: strings.availableDoctors,
                          value: '$onlineDocs',
                          subtitle: strings.availableDoctorsDesc,
                          icon: Icons.check_circle_outline_rounded,
                          accentColor: AdminColors.statusAvailable,
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AdminTheme.space16),
                  Row(
                    children: [
                      Expanded(
                        child: AdminKpiCard(
                          title: strings.pendingAppointments,
                          value: '$waitingAppts',
                          subtitle: strings.pendingAppointmentsDesc,
                          icon: Icons.hourglass_top_rounded,
                          accentColor: AdminColors.brandOrange,
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space16),
                      Expanded(
                        child: AdminKpiCard(
                          title: strings.activeEscalations,
                          value: '$activeCases',
                          subtitle: strings.activeCasesDesc,
                          icon: Icons.folder_shared_outlined,
                          accentColor: AdminColors.brandNavy,
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDoctorActionsSection(dynamic strings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        final addDoctorCard = AdminCard(
          title: strings.addNewDoctorTitle,
          subtitle: strings.addNewDoctorDesc,
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminColors.brandTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AdminColors.brandTeal,
              size: 20,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provision credentials and assign specialty department for a new medical officer.',
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AdminTheme.space16),
              SizedBox(
                width: double.infinity,
                child: AdminPrimaryButton(
                  label: strings.addNewDoctorButton,
                  icon: Icons.add_rounded,
                  onPressed: _navigateToAddDoctor,
                ),
              ),
            ],
          ),
        );

        final manageDoctorsCard = AdminCard(
          title: strings.manageDoctorsTitle,
          subtitle: strings.manageDoctorsDesc,
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminColors.brandNavy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: AdminColors.brandNavy,
              size: 20,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review physician profiles, verify department assignments, and manage system access.',
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AdminTheme.space16),
              SizedBox(
                width: double.infinity,
                child: AdminSecondaryButton(
                  label: strings.manageDoctorsButton,
                  icon: Icons.list_alt_rounded,
                  onPressed: _navigateToManageDoctors,
                ),
              ),
            ],
          ),
        );


        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: addDoctorCard),
              const SizedBox(width: AdminTheme.space20),
              Expanded(child: manageDoctorsCard),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addDoctorCard,
              const SizedBox(height: AdminTheme.space16),
              manageDoctorsCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildOperationalTelemetrySection(
    dynamic strings,
    dynamic overview,
    bool isLoading,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;

        final waitingCard = AdminWaitingAppointmentsCard(
          appointments: overview?.waitingAppointmentsList ?? const [],
          isLoading: isLoading,
        );

        final activeCasesCard = AdminActiveCasesCard(
          totalActiveCases: overview?.activeCases ?? 0,
          casesByDomain: overview?.activeCasesByDomain ?? const {},
          isLoading: isLoading,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: waitingCard),
              const SizedBox(width: AdminTheme.space20),
              Expanded(flex: 2, child: activeCasesCard),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              waitingCard,
              const SizedBox(height: AdminTheme.space20),
              activeCasesCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildAvailabilitySection(
    dynamic strings,
    List<AdminDomainAvailability>? items,
    bool isLoading,
  ) {
    final displayItems = items ?? AdminDomainAvailability.defaultEightDomains;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: AdminColors.brandTeal,
                ),
                const SizedBox(width: AdminTheme.space8),
                Text(
                  strings.doctorAvailabilityTitle,
                  style: AdminTheme.headline2.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.brandNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              '8 Specialties Monitored',
              style: AdminTheme.caption.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminTheme.space12),
        AdminAvailabilityTable(
          items: displayItems,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildEscalationsSection(dynamic strings, dynamic overview) {
    final escalatedCount = overview?.escalatedAppointments ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final appointmentEscalationArea = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notification_important_outlined,
                  size: 18,
                  color: AdminColors.brandOrange,
                ),
                const SizedBox(width: AdminTheme.space8),
                Text(
                  strings.appointmentEscalationsTitle,
                  style: AdminTheme.headline2.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.brandNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.space12),
            if (escalatedCount > 0)
              InkWell(
                key: const ValueKey('dashboard_escalation_alert_card'),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminAppointmentEscalations),
                borderRadius: BorderRadius.circular(AdminTheme.radius16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AdminTheme.space20),
                  decoration: BoxDecoration(
                    color: AdminColors.statusCritical.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AdminTheme.radius16),
                    border: Border.all(
                      color: AdminColors.statusCritical.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdminColors.statusCritical.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AdminTheme.radius12),
                        ),
                        child: const Icon(
                          Icons.notification_important_rounded,
                          color: AdminColors.statusCritical,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '$escalatedCount Escalated Appointment${escalatedCount > 1 ? "s" : ""}',
                                  style: AdminTheme.headline2.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.brandNavy,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AdminColors.statusCritical,
                                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                                  ),
                                  child: const Text(
                                    'ACTION REQUIRED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Waiting > 20 min without doctor. Click to review and assign.',
                              style: AdminTheme.caption.copyWith(
                                color: AdminColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AdminColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              )
            else
              AdminEscalationEmptyState(
                title: strings.noAppointmentEscalations,
                description: strings.noAppointmentEscalationsDesc,
                icon: Icons.timer_off_outlined,
                iconColor: AdminColors.statusNormal,
              ),
          ],
        );

        final caseEscalatedCount = overview?.escalatedCases ?? 0;

        final caseEscalationArea = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AdminColors.statusCritical,
                ),
                const SizedBox(width: AdminTheme.space8),
                Text(
                  strings.caseEscalationsTitle,
                  style: AdminTheme.headline2.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.brandNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.space12),
            if (caseEscalatedCount > 0)
              InkWell(
                key: const ValueKey('dashboard_case_escalation_alert_card'),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCaseEscalations),
                borderRadius: BorderRadius.circular(AdminTheme.radius16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AdminTheme.space20),
                  decoration: BoxDecoration(
                    color: AdminColors.statusCritical.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AdminTheme.radius16),
                    border: Border.all(
                      color: AdminColors.statusCritical.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AdminColors.statusCritical.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AdminTheme.radius12),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AdminColors.statusCritical,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '$caseEscalatedCount Escalated Case${caseEscalatedCount > 1 ? "s" : ""}',
                                  style: AdminTheme.headline2.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.brandNavy,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AdminColors.statusCritical,
                                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                                  ),
                                  child: const Text(
                                    'ACTION REQUIRED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Physician-escalated clinical cases. Click to review escalation queue.',
                              style: AdminTheme.caption.copyWith(
                                color: AdminColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AdminColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              )
            else
              AdminEscalationEmptyState(
                title: strings.noCaseEscalations,
                description: strings.noCaseEscalationsDesc,
                icon: Icons.shield_outlined,
                iconColor: AdminColors.statusNormal,
              ),
          ],
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: appointmentEscalationArea),
              const SizedBox(width: AdminTheme.space20),
              Expanded(child: caseEscalationArea),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              appointmentEscalationArea,
              const SizedBox(height: AdminTheme.space20),
              caseEscalationArea,
            ],
          );
        }
      },
    );
  }
}
