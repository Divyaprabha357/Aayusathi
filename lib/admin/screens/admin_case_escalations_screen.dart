import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../doctor/models/clinical_case.dart';
import '../controllers/admin_case_escalation_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_case_escalation_dialogs.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_escalation_empty_state.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/admin_sidebar.dart';

/// Full screen desktop workstation for administrative monitoring of physician-escalated clinical cases (Phase A8).
class AdminCaseEscalationsScreen extends StatefulWidget {
  const AdminCaseEscalationsScreen({super.key});

  @override
  State<AdminCaseEscalationsScreen> createState() =>
      _AdminCaseEscalationsScreenState();
}

class _AdminCaseEscalationsScreenState
    extends State<AdminCaseEscalationsScreen> {
  final AdminCaseEscalationController _controller =
      AdminCaseEscalationController.instance;
  late final TextEditingController _searchController;

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

    _searchController = TextEditingController();
    AdminSidebarController.instance.addListener(_onStateChanged);
    _controller.addListener(_onStateChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    AdminSidebarController.instance.removeListener(_onStateChanged);
    _controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    if (item.routeName != AppRoutes.adminCaseEscalations) {
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

  void _openReviewDialog(ClinicalCase c) {
    showDialog(
      context: context,
      builder: (ctx) => AdminCaseEscalationReviewDialog(
        clinicalCase: c,
        controller: _controller,
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  String _getReasonLabel(dynamic strings, CaseEscalationReason? reason) {
    if (reason == null) return 'N/A';
    switch (reason) {
      case CaseEscalationReason.clinicalDeterioration:
        return strings.filterReasonDeterioration;
      case CaseEscalationReason.repeatedVisitsNoResolution:
        return strings.filterReasonRepeatedVisits;
      case CaseEscalationReason.higherAuthorityReview:
        return strings.filterReasonHigherAuthority;
      case CaseEscalationReason.doctorConcern:
        return strings.filterReasonDoctorConcern;
      case CaseEscalationReason.other:
        return strings.filterReasonOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final isCollapsed = AdminSidebarController.instance.isCollapsed;
    final totalEscalations = _controller.totalEscalatedCases;
    final pendingReview = _controller.pendingReviewCount;
    final underReview = _controller.underReviewCount;
    final repeatedVisits = _controller.repeatedVisitsCount;
    final items = _controller.filteredEscalations;
    final isLoading = _controller.isLoading;

    return AdminDesktopScaffold(
      header: AdminHeader(
        title: strings.adminPortalTitle,
        subtitle: strings.caseEscalationsHeaderSubtitle,
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
            // 1. Top Section Banner
            _buildTopBanner(strings),
            const SizedBox(height: AdminTheme.space16),

            // 2. Error Banner if any
            if (_controller.hasError) ...[
              _buildErrorBanner(strings),
              const SizedBox(height: AdminTheme.space16),
            ],

            // 3. KPI Overview Cards
            _buildKpiSection(
              strings: strings,
              total: totalEscalations,
              pending: pendingReview,
              underReview: underReview,
              repeated: repeatedVisits,
              isLoading: isLoading,
              hasError: _controller.hasError,
            ),
            const SizedBox(height: AdminTheme.space24),

            // 4. Filter & Search Toolbar
            _buildFilterToolbar(strings),
            const SizedBox(height: AdminTheme.space24),

            // 5. Case Escalations Table
            _buildEscalationsTable(strings, items, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(dynamic strings) {
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
              color: AdminColors.statusCritical.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AdminColors.statusCritical,
              size: 28,
            ),
          ),
          const SizedBox(width: AdminTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.caseEscalationsHeaderTitle,
                  style: AdminTheme.headline2.copyWith(color: AdminColors.brandNavy),
                ),
                const SizedBox(height: AdminTheme.space4),
                Text(
                  strings.caseEscalationsHeaderSubtitle,
                  style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminTheme.space12),

          // Live Stream Pill
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
                  'LIVE STREAM',
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
                    tooltip: 'Refresh Escalations',
                    icon: const Icon(Icons.refresh_rounded, color: AdminColors.brandTeal),
                    onPressed: () => _controller.refresh(),
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
              _controller.errorMessage ?? strings.errorLoadingCaseEscalations,
              style: AdminTheme.bodyRegular.copyWith(
                fontSize: 13,
                color: AdminColors.statusCritical,
              ),
            ),
          ),
          const SizedBox(width: AdminTheme.space12),
          AdminSecondaryButton(
            label: strings.retry,
            height: 32,
            icon: Icons.refresh_rounded,
            onPressed: () => _controller.refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection({
    required dynamic strings,
    required int total,
    required int pending,
    required int underReview,
    required int repeated,
    required bool isLoading,
    bool hasError = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1150;
        final card1 = AdminKpiCard(
          key: const Key('card_kpi_total_case_escalations'),
          title: strings.summaryTotalCaseEscalations,
          value: hasError ? '--' : '$total',
          subtitle: hasError ? 'Escalation data unavailable' : 'Active Clinical Escalations',
          icon: Icons.folder_shared_outlined,
          accentColor: AdminColors.statusCritical,
          badgeText: hasError ? 'Error' : (total > 0 ? 'Action Required' : 'All Clear'),
          badgeColor: hasError ? AdminColors.statusCritical : (total > 0 ? AdminColors.statusCritical : AdminColors.statusAvailable),
          isLoading: isLoading,
        );

        final card2 = AdminKpiCard(
          key: const Key('card_kpi_deterioration'),
          title: strings.summaryPendingReview,
          value: hasError ? '--' : '$pending',
          subtitle: hasError ? 'Escalation data unavailable' : 'Awaiting Admin Assessment',
          icon: Icons.warning_amber_rounded,
          accentColor: AdminColors.brandOrange,
          badgeText: hasError ? 'Error' : (pending > 0 ? 'Pending' : 'None'),
          badgeColor: hasError ? AdminColors.statusCritical : (pending > 0 ? AdminColors.brandOrange : AdminColors.textMuted),
          isLoading: isLoading,
        );

        final card3 = AdminKpiCard(
          key: const Key('card_kpi_under_review'),
          title: strings.summaryUnderReview,
          value: hasError ? '--' : '$underReview',
          subtitle: hasError ? 'Escalation data unavailable' : 'Under Administrative Review',
          icon: Icons.rate_review_outlined,
          accentColor: AdminColors.brandTeal,
          badgeText: hasError ? 'Error' : 'Reviewing',
          badgeColor: hasError ? AdminColors.statusCritical : AdminColors.brandTeal,
          isLoading: isLoading,
        );

        final card4 = AdminKpiCard(
          key: const Key('card_kpi_repeated_visits'),
          title: strings.summaryRepeatedVisits,
          value: hasError ? '--' : '$repeated',
          subtitle: hasError ? 'Escalation data unavailable' : 'Unresolved Multi-Visit Cases',
          icon: Icons.repeat_rounded,
          accentColor: AdminColors.brandNavy,
          badgeText: hasError ? 'Error' : 'Recurring',
          badgeColor: hasError ? AdminColors.statusCritical : AdminColors.brandNavy,
          isLoading: isLoading,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: AdminTheme.space16),
              Expanded(child: card2),
              const SizedBox(width: AdminTheme.space16),
              Expanded(child: card3),
              const SizedBox(width: AdminTheme.space16),
              Expanded(child: card4),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: AdminTheme.space16),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildFilterToolbar(dynamic strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.space16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Input
          SizedBox(
            width: 260,
            height: 40,
            child: TextField(
              key: const ValueKey('case_escalation_search_field'),
              controller: _searchController,
              onChanged: (val) => _controller.setSearchQuery(val),
              style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: strings.searchCaseEscalationPlaceholder,
                hintStyle: AdminTheme.caption.copyWith(color: AdminColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.brandTeal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AdminColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  borderSide: const BorderSide(color: AdminColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  borderSide: const BorderSide(color: AdminColors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),

          // Department Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const ValueKey('case_escalation_dept_dropdown'),
                value: _controller.selectedDepartment,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AdminColors.brandNavy),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 13, color: AdminColors.brandNavy),
                items: [
                  DropdownMenuItem(value: 'ALL', child: Text(strings.filterAllDepartments)),
                  ...AdminDomainAvailability.standardDomains.map(
                    (d) => DropdownMenuItem(value: d['id']!.toUpperCase(), child: Text(d['name']!)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) _controller.setSelectedDepartment(val);
                },
              ),
            ),
          ),

          // Reason Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CaseEscalationReason?>(
                key: const ValueKey('case_escalation_reason_dropdown'),
                value: _controller.selectedReason,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AdminColors.brandNavy),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 13, color: AdminColors.brandNavy),
                items: [
                  DropdownMenuItem(value: null, child: Text(strings.filterReasonAll)),
                  ...CaseEscalationReason.values.map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(_getReasonLabel(strings, r)),
                    ),
                  ),
                ],
                onChanged: (val) => _controller.setSelectedReason(val),
              ),
            ),
          ),

          // Review Status Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CaseEscalationStatus?>(
                key: const ValueKey('case_escalation_status_dropdown'),
                value: _controller.selectedReviewStatus,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AdminColors.brandNavy),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 13, color: AdminColors.brandNavy),
                items: [
                  DropdownMenuItem(value: null, child: Text(strings.filterReviewStatusAll)),
                  DropdownMenuItem(
                    value: CaseEscalationStatus.escalated,
                    child: Text(strings.filterReviewStatusEscalated),
                  ),
                  DropdownMenuItem(
                    value: CaseEscalationStatus.underReview,
                    child: Text(strings.filterReviewStatusUnderReview),
                  ),
                ],
                onChanged: (val) => _controller.setSelectedReviewStatus(val),
              ),
            ),
          ),

          // Sorting Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AdminCaseSortOption>(
                key: const ValueKey('case_escalation_sort_dropdown'),
                value: _controller.sortOption,
                icon: const Icon(Icons.sort_rounded, size: 18, color: AdminColors.brandNavy),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 13, color: AdminColors.brandNavy),
                items: [
                  DropdownMenuItem(value: AdminCaseSortOption.oldestEscalation, child: Text(strings.sortCaseOldest)),
                  DropdownMenuItem(value: AdminCaseSortOption.newestEscalation, child: Text(strings.sortCaseNewest)),
                  DropdownMenuItem(value: AdminCaseSortOption.department, child: Text(strings.sortCaseDepartment)),
                  DropdownMenuItem(value: AdminCaseSortOption.visitCount, child: Text(strings.sortCaseVisitCount)),
                  DropdownMenuItem(value: AdminCaseSortOption.reason, child: Text(strings.sortCaseReason)),
                ],
                onChanged: (val) {
                  if (val != null) _controller.setSortOption(val);
                },
              ),
            ),
          ),

          // Reset Filters Button
          AdminSecondaryButton(
            key: const ValueKey('case_escalation_reset_filters_btn'),
            label: 'RESET',
            icon: Icons.filter_alt_off_rounded,
            height: 40,
            onPressed: () {
              _searchController.clear();
              _controller.resetFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationsTable(
    dynamic strings,
    List<ClinicalCase> items,
    bool isLoading,
  ) {
    if (isLoading) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AdminColors.brandTeal),
            const SizedBox(height: 12),
            Text('Loading escalated cases...', style: AdminTheme.caption),
          ],
        ),
      );
    }

    if (_controller.hasError) {
      return Container(
        key: const Key('admin_case_escalations_error_state'),
        padding: const EdgeInsets.all(AdminTheme.space32),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.statusCritical.withValues(alpha: 0.3)),
          boxShadow: AdminTheme.shadowSubtle,
        ),
        child: AdminEscalationEmptyState(
          title: strings.errorLoadingCaseEscalations,
          description: _controller.errorMessage ?? 'Unable to load clinical case escalations from Firebase.',
          icon: Icons.cloud_off_rounded,
          iconColor: AdminColors.statusCritical,
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        key: const Key('admin_case_escalations_empty_state'),
        padding: const EdgeInsets.all(AdminTheme.space32),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.borderSubtle),
          boxShadow: AdminTheme.shadowSubtle,
        ),
        child: AdminEscalationEmptyState(
          title: strings.emptyCaseEscalationsTitle,
          description: strings.emptyCaseEscalationsSubtitle,
          icon: Icons.folder_shared_outlined,
          iconColor: AdminColors.statusNormal,
        ),
      );
    }

    return Container(
      key: const Key('admin_case_escalations_table'),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1160),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AdminColors.backgroundSecondary),
              headingTextStyle: AdminTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AdminColors.brandNavy,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: 20,
              columnSpacing: 18,
              columns: [
                DataColumn(label: Text(strings.tableColCaseId)),
                DataColumn(label: Text(strings.tableColPatientId)),
                DataColumn(label: Text(strings.tableColDepartmentA8)),
                DataColumn(label: Text(strings.tableColReason)),
                DataColumn(label: Text(strings.tableColSourceVisit)),
                DataColumn(label: Text(strings.tableColEscalatedAtA8)),
                DataColumn(label: Text(strings.tableColEscalatedBy)),
                DataColumn(label: Text(strings.tableColCaseStatus)),
                DataColumn(label: Text(strings.tableColReviewStatus)),
                DataColumn(label: Text(strings.tableColActionA8)),
              ],
              rows: items.map((c) {
                final isUnderReview = c.isUnderReview;
                final reasonLabel = _getReasonLabel(strings, c.escalationReason);

                return DataRow(
                  key: ValueKey('case_row_${c.caseId}'),
                  cells: [
                    // Case ID
                    DataCell(
                      Text(
                        c.caseId,
                        style: AdminTheme.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandNavy,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Patient ID
                    DataCell(
                      Text(
                        c.patientId,
                        style: AdminTheme.bodyRegular.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AdminColors.brandTeal,
                        ),
                      ),
                    ),

                    // Department
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AdminColors.brandNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.domain,
                          style: AdminTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AdminColors.brandNavy,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),

                    // Reason
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.escalationReason == CaseEscalationReason.clinicalDeterioration
                                ? Icons.trending_down_rounded
                                : (c.escalationReason == CaseEscalationReason.repeatedVisitsNoResolution
                                    ? Icons.repeat_rounded
                                    : Icons.warning_amber_rounded),
                            size: 14,
                            color: AdminColors.statusCritical,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reasonLabel,
                            style: AdminTheme.bodyRegular.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AdminColors.brandNavy,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Source Visit
                    DataCell(
                      Text(
                        c.escalationSourceVisitId ?? 'Visit ${c.visitCount}',
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Escalated At
                    DataCell(
                      Text(
                        _formatDateTime(c.escalatedAt),
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    // Escalated By
                    DataCell(
                      Text(
                        c.escalatedByDoctorName ?? c.escalatedByDoctorId ?? 'Doctor',
                        style: AdminTheme.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AdminColors.brandNavy,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Case Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.isOpen
                              ? AdminColors.statusAvailable.withValues(alpha: 0.12)
                              : AdminColors.textMuted.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.isOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: c.isOpen ? AdminColors.statusAvailable : AdminColors.textMuted,
                          ),
                        ),
                      ),
                    ),

                    // Review Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isUnderReview
                              ? AdminColors.brandTeal.withValues(alpha: 0.12)
                              : AdminColors.statusCritical.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AdminTheme.radius8),
                        ),
                        child: Text(
                          isUnderReview ? strings.statusBadgeUnderReview : strings.statusBadgePendingReview,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUnderReview ? AdminColors.brandTeal : AdminColors.statusCritical,
                          ),
                        ),
                      ),
                    ),

                    // Action: Review Button
                    DataCell(
                      AdminPrimaryButton(
                        key: ValueKey('review_btn_${c.caseId}'),
                        label: strings.actionReviewCase,
                        height: 32,
                        icon: Icons.rate_review_rounded,
                        onPressed: () => _openReviewDialog(c),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
