import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../controllers/admin_escalated_patient_workspace_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../localization/admin_strings.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_escalated_workspace_widgets.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_higher_authority_assignment_dialog.dart';
import '../widgets/admin_sidebar.dart';

/// Full screen desktop workstation for Administrative Inspection & Governance
/// of physician-escalated patient clinical cases (Phase A9 & A10).
///
/// Permitted Permissions:
/// - Full longitudinal inspection of patient identity, case summary, timeline,
///   multi-visit consultation history, vitals, doctor-approved summaries,
///   investigations, report files, and inter-department transfers.
/// - Transactional review state transition (`START REVIEW` -> `UNDER REVIEW`).
/// - Higher-Authority Doctor Assignment & Transfer (Phase A10).
///
/// Safeguards & Invariants:
/// - Strictly READ-ONLY for all clinical fields.
/// - ZERO patient/visit/vital/medication/assessment/plan editing.
/// - ZERO visit completion, ZERO case closure/reopening.
class AdminEscalatedPatientWorkspaceScreen extends StatefulWidget {
  final String? patientId;
  final String? caseId;

  const AdminEscalatedPatientWorkspaceScreen({
    super.key,
    this.patientId,
    this.caseId,
  });

  @override
  State<AdminEscalatedPatientWorkspaceScreen> createState() =>
      _AdminEscalatedPatientWorkspaceScreenState();
}

class _AdminEscalatedPatientWorkspaceScreenState
    extends State<AdminEscalatedPatientWorkspaceScreen> {
  late final AdminEscalatedPatientWorkspaceController _controller;
  bool _isControllerInitialized = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isControllerInitialized) {
      _extractArgsAndInitController();
    }
  }

  void _extractArgsAndInitController() {
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final pId = widget.patientId ?? routeArgs?['patientId'] as String? ?? 'PAT-MOCK-001';
    final cId = widget.caseId ?? routeArgs?['caseId'] as String? ?? 'CASE-PAT-001-01';

    _controller = AdminEscalatedPatientWorkspaceController(
      patientId: pId,
      caseId: cId,
    );
    _controller.addListener(_onStateChanged);
    _controller.initialize();
    _isControllerInitialized = true;
  }

  @override
  void dispose() {
    AdminSidebarController.instance.removeListener(_onStateChanged);
    if (_isControllerInitialized) {
      _controller.removeListener(_onStateChanged);
      _controller.dispose();
    }
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    Navigator.of(context).pushReplacementNamed(item.routeName);
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

  void _handleBackToEscalations() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.adminCaseEscalations);
    }
  }

  Future<void> _handleStartReview() async {
    try {
      await _controller.startReview();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AdminLocalizations.of(context).reviewStartedSuccess),
            backgroundColor: AdminColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start review: $e'),
            backgroundColor: AdminColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAssignHigherAuthority() async {
    final c = _controller.clinicalCase;
    if (c == null) return;
    final assigned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AdminHigherAuthorityAssignmentDialog(
        clinicalCase: c,
        sourceDoctorName: c.escalatedByDoctorName ?? c.escalatedByDoctorId,
      ),
    );
    if (assigned == true && mounted) {
      final successMsg = AdminLocalizations.of(context).assignmentSuccessMessage;
      await _controller.loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: AdminColors.brandTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final isCollapsed = AdminSidebarController.instance.isCollapsed;

    return AdminDesktopScaffold(
      header: AdminHeader(
        title: strings.adminPortalTitle,
        subtitle: strings.escalatedWorkspaceSubtitle,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: AppRoutes.adminCaseEscalations,
        isCollapsed: isCollapsed,
        onToggleCollapse: AdminSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Navigation & Review Action Bar
            _buildTopActionBar(strings),
            const SizedBox(height: AdminTheme.space16),

            // 2. Body State Rendering (Loading / Error / Content)
            if (_controller.isLoading)
              _buildLoadingState()
            else if (_controller.hasError)
              _buildErrorState(strings)
            else if (_controller.clinicalCase == null)
              _buildCaseNotFoundState(strings)
            else
              _buildWorkspaceContent(strings),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActionBar(AdminStrings strings) {
    final c = _controller.clinicalCase;
    final isUnderReview = c?.isUnderReview ?? false;

    return Container(
      key: const ValueKey('AdminWorkspaceTopActionBar'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  flex: 0,
                  child: AdminSecondaryButton(
                    key: const ValueKey('back_to_escalations_button'),
                    label: strings.backToCaseEscalations,
                    icon: Icons.arrow_back_rounded,
                    height: 36,
                    onPressed: _handleBackToEscalations,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 1,
                  color: AdminColors.borderSubtle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.escalatedWorkspaceTitle,
                        style: AdminTheme.headline2.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandNavy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Clinical Record Inspection • Case: ${_controller.caseId}',
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (c != null) ...[
            Row(
              children: [
                if (isUnderReview)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.brandTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AdminTheme.radius8),
                      border: Border.all(
                        color: AdminColors.brandTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.rate_review_rounded,
                          size: 16,
                          color: AdminColors.brandTeal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          strings.statusBadgeUnderReview,
                          style: const TextStyle(
                            color: AdminColors.brandTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AdminSecondaryButton(
                    key: const ValueKey('start_review_workspace_button'),
                    label: _controller.isStartingReview
                        ? strings.startingReviewButton
                        : strings.startReviewButton,
                    icon: Icons.rate_review_rounded,
                    height: 36,
                    onPressed: _controller.isStartingReview ? () {} : _handleStartReview,
                  ),
                const SizedBox(width: 12),
                AdminPrimaryButton(
                  key: const ValueKey('top_assign_higher_authority_button'),
                  label: c.isAssignedToHigherAuthority
                      ? strings.reassignHigherAuthorityButton
                      : strings.assignHigherAuthorityButton,
                  icon: Icons.person_add_alt_1_rounded,
                  height: 36,
                  onPressed: _handleAssignHigherAuthority,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(color: AdminColors.brandTeal),
          SizedBox(height: 16),
          Text(
            'Loading complete longitudinal patient record...',
            style: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AdminStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.space24),
      decoration: BoxDecoration(
        color: AdminColors.statusCritical.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.statusCritical.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AdminColors.statusCritical, size: 28),
              const SizedBox(width: 12),
              Text(
                strings.errorLoadingClinicalRecord,
                style: AdminTheme.headline2.copyWith(
                  color: AdminColors.statusCritical,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _controller.errorMessage ?? 'An unexpected error occurred while loading clinical records.',
            style: AdminTheme.bodyRegular.copyWith(color: AdminColors.textPrimary),
          ),
          const SizedBox(height: 16),
          AdminPrimaryButton(
            label: strings.retry,
            icon: Icons.refresh_rounded,
            height: 34,
            onPressed: _controller.loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseNotFoundState(AdminStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.space24),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(Icons.folder_off_outlined, color: AdminColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            strings.caseNotFoundTitle,
            style: AdminTheme.headline2.copyWith(color: AdminColors.brandNavy, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            strings.caseNotFoundSubtitle,
            style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 16),
          AdminSecondaryButton(
            label: strings.backToCaseEscalations,
            onPressed: _handleBackToEscalations,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(AdminStrings strings) {
    final c = _controller.clinicalCase!;
    final p = _controller.patient;
    final selectedVisit = _controller.selectedVisit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Escalation Alert Banner
        AdminEscalationBanner(
          clinicalCase: c,
          onAssignHigherAuthority: _handleAssignHigherAuthority,
        ),
        const SizedBox(height: AdminTheme.space16),

        // 2. Active Consultation Notice (if applicable)
        if (_controller.isConsultationActive && _controller.activeConsultationVisit != null) ...[
          AdminActiveConsultationNotice(activeVisit: _controller.activeConsultationVisit!),
          const SizedBox(height: AdminTheme.space16),
        ],

        // 3. Authorized Patient Identity Card
        AdminPatientIdentityCard(patient: p, clinicalCase: c),
        const SizedBox(height: AdminTheme.space16),

        // 4. Case Summary & Current Vitals
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: AdminCaseSummaryCard(clinicalCase: c)),
            const SizedBox(width: AdminTheme.space16),
            Expanded(flex: 2, child: AdminCurrentVitalsCard(latestVital: _controller.latestVital)),
          ],
        ),
        const SizedBox(height: AdminTheme.space24),

        // 5. Chronological Case Timeline
        AdminCaseTimelineView(
          clinicalCase: c,
          visits: _controller.visits,
          transfers: _controller.transfers,
          onSelectVisit: (visitId) => _controller.selectVisitById(visitId),
        ),
        const SizedBox(height: AdminTheme.space24),

        // 6. Multi-Visit Selection Tabs
        if (_controller.visits.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, color: AdminColors.brandTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.visitHistorySection,
                style: AdminTheme.headline2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.brandNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AdminVisitSelectorBar(
            visits: _controller.visits,
            selectedIndex: _controller.selectedVisitIndex,
            onSelectIndex: (idx) => _controller.selectVisitIndex(idx),
          ),
          const SizedBox(height: AdminTheme.space16),
        ],

        // 7. Full 9-Section Read-Only Visit Detail Record
        if (selectedVisit != null) ...[
          AdminVisitDetailView(
            visit: selectedVisit,
            patient: p,
            clinicalCase: c,
            investigations: _controller.getInvestigationsForVisit(selectedVisit.visitId),
            reports: _controller.getReportsForVisit(selectedVisit.visitId),
          ),
          const SizedBox(height: AdminTheme.space24),
        ],

        // 8. Inter-Department Transfer History Card
        AdminTransferHistoryCard(transfers: _controller.transfers),
        const SizedBox(height: AdminTheme.space24),

        // 9. Escalation & Governance History Card
        AdminEscalationGovernanceHistoryCard(
          clinicalCase: c,
          onAssignHigherAuthority: _handleAssignHigherAuthority,
        ),
      ],
    );
  }
}
