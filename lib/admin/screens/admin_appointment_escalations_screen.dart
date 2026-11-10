import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../models/appointment_request.dart';
import '../../services/appointment_escalation_policy.dart';
import '../controllers/admin_appointment_escalation_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_appointment_escalation_dialogs.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_kpi_card.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Appointment Escalation Governance Screen (Phase A7).
///
/// Implements real-time monitoring of OPD queue response SLAs, automatically
/// identifies appointments waiting >=20 minutes without physician allocation,
/// and empowers administrators to manually assign eligible available doctors.
class AdminAppointmentEscalationsScreen extends StatefulWidget {
  const AdminAppointmentEscalationsScreen({super.key});

  @override
  State<AdminAppointmentEscalationsScreen> createState() =>
      _AdminAppointmentEscalationsScreenState();
}

class _AdminAppointmentEscalationsScreenState
    extends State<AdminAppointmentEscalationsScreen> {
  final AdminAppointmentEscalationController _controller =
      AdminAppointmentEscalationController.instance;

  final TextEditingController _searchController = TextEditingController();

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
    _controller.addListener(_onStateChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    AdminSidebarController.instance.removeListener(_onStateChanged);
    _controller.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    if (item.routeName != AppRoutes.adminAppointmentEscalations) {
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final appointments = _controller.filteredAppointments;
    final isLoading = _controller.isLoading;

    return AdminDesktopScaffold(
      header: AdminHeader(
        title: strings.adminPortalTitle,
        subtitle: strings.centralAdminConsole,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: AppRoutes.adminAppointmentEscalations,
        isCollapsed: AdminSidebarController.instance.isCollapsed,
        onToggleCollapse: AdminSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Banner
            _buildHeaderBanner(strings),
            const SizedBox(height: AdminTheme.space20),

            // 2. Summary KPI Metric Cards
            _buildSummaryKpiSection(strings, isLoading),
            const SizedBox(height: AdminTheme.space20),

            // 3. Search & Filter Bar
            _buildFilterBar(strings),
            const SizedBox(height: AdminTheme.space20),

            // 4. Escalation Table
            _buildEscalationTable(strings, appointments, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(dynamic strings) {
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
              color: AdminColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
            ),
            child: const Icon(
              Icons.notification_important_rounded,
              color: AdminColors.brandOrange,
              size: 28,
            ),
          ),
          const SizedBox(width: AdminTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.appointmentEscalationsHeaderTitle,
                  style: AdminTheme.headline2.copyWith(color: AdminColors.brandNavy),
                ),
                const SizedBox(height: AdminTheme.space4),
                Text(
                  strings.appointmentEscalationsHeaderSubtitle,
                  style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AdminTheme.space12),

          // 20-Minute Policy SLA Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AdminColors.brandOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'SLA THRESHOLD: 20 MIN',
                  style: AdminTheme.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.brandNavy,
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

  Widget _buildSummaryKpiSection(dynamic strings, bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final escalatedCount = _controller.escalatedCount;
        final waitingCount = _controller.waitingCount;
        final resolvedTodayCount = _controller.resolvedTodayCount;

        final cards = [
          AdminKpiCard(
            title: strings.summaryEscalatedAppointments,
            value: '$escalatedCount',
            subtitle: 'Waiting > 20 min without doctor',
            icon: Icons.notification_important_rounded,
            accentColor: AdminColors.statusCritical,
            badgeText: escalatedCount > 0 ? 'ACTION REQUIRED' : 'CLEAR',
            badgeColor: escalatedCount > 0
                ? AdminColors.statusCritical
                : AdminColors.statusAvailable,
            isLoading: isLoading,
          ),
          AdminKpiCard(
            title: strings.summaryWaitingAppointments,
            value: '$waitingCount',
            subtitle: 'Total active OPD queue requests',
            icon: Icons.hourglass_top_rounded,
            accentColor: AdminColors.brandOrange,
            badgeText: waitingCount > 0 ? 'IN QUEUE' : 'ZERO QUEUE',
            badgeColor: waitingCount > 0
                ? AdminColors.brandOrange
                : AdminColors.statusAvailable,
            isLoading: isLoading,
          ),
          AdminKpiCard(
            title: strings.summaryResolvedToday,
            value: '$resolvedTodayCount',
            subtitle: 'Assigned / completed today',
            icon: Icons.task_alt_rounded,
            accentColor: AdminColors.brandTeal,
            badgeText: 'RESOLVED',
            badgeColor: AdminColors.brandTeal,
            isLoading: isLoading,
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildFilterBar(dynamic strings) {
    final hasActiveFilters = _controller.hasActiveFilters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.space16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AdminTheme.space12,
            runSpacing: AdminTheme.space10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Input
              SizedBox(
                width: 280,
                height: 42,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _controller.setSearchQuery(val),
                  style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: strings.searchEscalationPlaceholder,
                    hintStyle: AdminTheme.caption.copyWith(
                      color: AdminColors.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AdminColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _controller.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    filled: true,
                    fillColor: AdminColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.brandTeal, width: 1.5),
                    ),
                  ),
                ),
              ),

              // Department Dropdown
              SizedBox(
                width: 200,
                height: 42,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _controller.selectedDepartment,
                  onChanged: (val) {
                    if (val != null) _controller.setDepartment(val);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: AdminColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        strings.filterAllDepartments,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...AdminDomainAvailability.standardDomains.map(
                      (d) => DropdownMenuItem(
                        value: d['id'],
                        child: Text(
                          d['name']!,
                          style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Dropdown
              SizedBox(
                width: 170,
                height: 42,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _controller.selectedStatus,
                  onChanged: (val) {
                    if (val != null) _controller.setStatus(val);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: AdminColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        strings.filterStatusAll,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'escalated',
                      child: Text(
                        strings.filterStatusEscalated,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'waiting',
                      child: Text(
                        strings.filterStatusWaiting,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text(
                        strings.filterStatusResolved,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Sorting Dropdown
              SizedBox(
                width: 200,
                height: 42,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _controller.selectedSort,
                  onChanged: (val) {
                    if (val != null) _controller.setSort(val);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: AdminColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                      borderSide: const BorderSide(color: AdminColors.borderSubtle),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'oldestWaiting',
                      child: Text(
                        strings.sortOldestWaiting,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text(
                        strings.sortNewest,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'department',
                      child: Text(
                        strings.sortDepartment,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'escalationTime',
                      child: Text(
                        strings.sortEscalationTime,
                        style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Reset Filters Button
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _controller.resetFilters();
                  },
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16, color: AdminColors.brandTeal),
                  label: const Text(
                    'RESET FILTERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.brandTeal,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationTable(
    dynamic strings,
    List<AppointmentRequest> appointments,
    bool isLoading,
  ) {
    if (isLoading && appointments.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.borderSubtle),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AdminColors.brandTeal),
        ),
      );
    }

    if (appointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AdminTheme.space40),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.borderSubtle),
          boxShadow: AdminTheme.shadowSubtle,
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AdminColors.brandTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 32,
                color: AdminColors.brandTeal,
              ),
            ),
            const SizedBox(height: AdminTheme.space16),
            Text(
              strings.emptyEscalationsTitle,
              style: AdminTheme.headline2.copyWith(
                fontSize: 16,
                color: AdminColors.brandNavy,
              ),
            ),
            const SizedBox(height: AdminTheme.space8),
            Text(
              strings.emptyEscalationsSubtitle,
              textAlign: TextAlign.center,
              style: AdminTheme.caption.copyWith(
                fontSize: 13,
                color: AdminColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Column Headers
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminTheme.space20,
                    vertical: AdminTheme.space14,
                  ),
                  decoration: const BoxDecoration(
                    color: AdminColors.backgroundSecondary,
                    border: Border(bottom: BorderSide(color: AdminColors.borderSubtle)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: _buildTableHeader(strings.tableColQueue)),
                      SizedBox(width: 160, child: _buildTableHeader(strings.tableColAppointmentId)),
                      SizedBox(width: 140, child: _buildTableHeader(strings.tableColDepartmentA7)),
                      SizedBox(width: 110, child: _buildTableHeader(strings.tableColWaitingSince)),
                      SizedBox(width: 140, child: _buildTableHeader(strings.tableColWaitingDuration)),
                      SizedBox(width: 110, child: _buildTableHeader(strings.tableColEscalatedAt)),
                      SizedBox(width: 110, child: _buildTableHeader(strings.tableColCurrentStatus)),
                      SizedBox(width: 260, child: _buildTableHeader(strings.tableColAction, align: TextAlign.end)),
                    ],
                  ),
                ),

                // Table Rows
                Column(
                  children: appointments.map((appointment) {
                    return _buildTableRow(strings, appointment);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, {TextAlign align = TextAlign.start}) {
    return Text(
      text,
      textAlign: align,
      style: AdminTheme.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AdminColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTableRow(dynamic strings, AppointmentRequest appointment) {
    final now = _controller.nowProvider();
    final isEscalated = appointment.isEscalated ||
        AppointmentEscalationPolicy.shouldEscalate(appointment, now);
    final isResolved = appointment.isEscalationResolved ||
        appointment.status == AppointmentStatus.accepted ||
        appointment.status == AppointmentStatus.completed;

    final waitDuration = AppointmentEscalationPolicy.calculateWaitDuration(appointment.createdAt, now);
    final durationFormatted = AppointmentEscalationPolicy.formatWaitDuration(waitDuration);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminTheme.space20,
        vertical: AdminTheme.space14,
      ),
      decoration: BoxDecoration(
        color: isEscalated && !isResolved
            ? AdminColors.statusCritical.withValues(alpha: 0.03)
            : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AdminColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          // Queue Number
          SizedBox(
            width: 100,
            child: Text(
              appointment.queueNumber,
              style: AdminTheme.bodyRegular.copyWith(
                fontWeight: FontWeight.w700,
                color: AdminColors.brandNavy,
              ),
            ),
          ),

          // Appointment ID (Masked for privacy)
          SizedBox(
            width: 160,
            child: Text(
              appointment.requestId,
              style: AdminTheme.caption.copyWith(
                color: AdminColors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),

          // Department
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminColors.brandTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.domainId.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AdminTheme.bodyRegular.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.brandNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Waiting Since
          SizedBox(
            width: 110,
            child: Text(
              _formatTime(appointment.createdAt),
              style: AdminTheme.bodyRegular.copyWith(
                fontSize: 12,
                color: AdminColors.brandNavy,
              ),
            ),
          ),

          // Waiting Duration
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(
                  isEscalated ? Icons.timer_outlined : Icons.hourglass_bottom_rounded,
                  size: 14,
                  color: isEscalated ? AdminColors.statusCritical : AdminColors.brandTeal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    durationFormatted,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTheme.bodyRegular.copyWith(
                      fontSize: 12,
                      fontWeight: isEscalated ? FontWeight.w700 : FontWeight.w500,
                      color: isEscalated ? AdminColors.statusCritical : AdminColors.brandNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Escalated At
          SizedBox(
            width: 110,
            child: Text(
              appointment.escalatedAt != null ? _formatTime(appointment.escalatedAt!) : '--',
              style: AdminTheme.caption.copyWith(
                fontSize: 12,
                color: AdminColors.textSecondary,
              ),
            ),
          ),

          // Status Badge
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(strings, appointment, isEscalated, isResolved),
            ),
          ),

          // Actions
          SizedBox(
            width: 260,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Assign Doctor Action (if escalated and unassigned)
                if (isEscalated && !isResolved) ...[
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      key: ValueKey('assign_btn_${appointment.requestId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.brandTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AdminTheme.radius8),
                        ),
                      ),
                      onPressed: () => AdminAssignDoctorDialog.show(context, appointment),
                      child: Text(
                        strings.actionAssignDoctor,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // View Details Action
                IconButton(
                  key: ValueKey('view_btn_${appointment.requestId}'),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  color: AdminColors.brandNavy,
                  tooltip: strings.actionInspectDetails,
                  onPressed: () => AdminAppointmentEscalationDialog.show(context, appointment),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    dynamic strings,
    AppointmentRequest appointment,
    bool isEscalated,
    bool isResolved,
  ) {
    if (isResolved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.brandNavy.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AdminTheme.radius8),
        ),
        child: Text(
          strings.statusBadgeResolved,
          textAlign: TextAlign.center,
          style: AdminTheme.badgeText.copyWith(
            color: AdminColors.brandNavy,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isEscalated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AdminColors.statusCritical.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AdminTheme.radius8),
        ),
        child: Text(
          strings.statusBadgeEscalated,
          textAlign: TextAlign.center,
          style: AdminTheme.badgeText.copyWith(
            color: AdminColors.statusCritical,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.brandTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AdminTheme.radius8),
      ),
      child: Text(
        strings.statusBadgeWaiting,
        textAlign: TextAlign.center,
        style: AdminTheme.badgeText.copyWith(
          color: AdminColors.brandTeal,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
