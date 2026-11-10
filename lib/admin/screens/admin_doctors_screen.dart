import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/opd_domain.dart';
import '../controllers/admin_manage_doctors_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_doctor_details_dialog.dart';
import '../widgets/admin_doctor_status_dialogs.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';

/// Central Administrative Doctor Management Screen (Phase A5).
///
/// Route: `/admin/doctors`
/// Features:
/// - Real-time physician directory with instant multi-column search & filtering
/// - Department and active/inactive status filters
/// - Sorting by newest, name, department, status
/// - Physician inspection modal with masked contact privacy
/// - Active consultation safeguard protection against deactivation / department changes
/// - Direct navigation to Add New Doctor provisioning (`/admin/doctors/add`)
class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> {
  final AdminManageDoctorsController _controller = AdminManageDoctorsController.instance;
  late final TextEditingController _searchTextController;

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

    _searchTextController = TextEditingController(text: _controller.searchQuery);
    _controller.init();

    AdminSidebarController.instance.addListener(_onStateChanged);
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AdminSidebarController.instance.removeListener(_onStateChanged);
    _controller.removeListener(_onStateChanged);
    _searchTextController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    if (item.routeName != AppRoutes.adminDoctors) {
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

  void _handleViewDetails(DoctorProfile doctor) {
    AdminDoctorDetailsDialog.show(
      context,
      doctor: doctor,
      onEdit: () => _handleEditDoctor(doctor),
    );
  }

  Future<void> _handleEditDoctor(DoctorProfile doctor) async {
    final updated = await AdminEditDoctorDialog.show(
      context,
      doctor: doctor,
      controller: _controller,
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor profile updated successfully.'),
          backgroundColor: AdminColors.statusAvailable,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleToggleStatus(DoctorProfile doctor) async {
    if (doctor.isActive) {
      final deactivated = await AdminDeactivateDoctorDialog.show(
        context,
        doctor: doctor,
        controller: _controller,
      );
      if (deactivated == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor account deactivated successfully.'),
            backgroundColor: AdminColors.statusCritical,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final activated = await AdminActivateDoctorDialog.show(
        context,
        doctor: doctor,
        controller: _controller,
      );
      if (activated == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor account activated successfully.'),
            backgroundColor: AdminColors.statusAvailable,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final doctors = _controller.filteredDoctors;

    return AdminDesktopScaffold(
      header: AdminHeader(
        title: strings.manageDoctorsHeaderTitle,
        subtitle: strings.manageDoctorsHeaderSubtitle,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: AppRoutes.adminDoctors,
        isCollapsed: AdminSidebarController.instance.isCollapsed,
        onToggleCollapse: AdminSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Metrics Summary Banner
            _buildMetricsStrip(strings),
            const SizedBox(height: AdminTheme.space20),

            // 2. Main Registry Table Card
            AdminCard(
              title: strings.manageDoctorsTitle,
              subtitle: 'Comprehensive physician registry, access governance, and department allocations.',
              trailing: AdminPrimaryButton(
                label: 'ADD NEW DOCTOR',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: _navigateToAddDoctor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter and Search Toolbar
                  _buildToolbar(strings),
                  const SizedBox(height: AdminTheme.space16),

                  // Table Content
                  if (_controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: AdminColors.brandTeal),
                      ),
                    )
                  else if (_controller.errorMessage != null)
                    _buildErrorView()
                  else if (doctors.isEmpty)
                    _buildEmptyView(strings)
                  else
                    _buildDoctorsTable(doctors, strings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // METRICS SUMMARY STRIP
  // =========================================================================
  Widget _buildMetricsStrip(dynamic strings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final totalCard = _buildMetricCard(
          title: strings.totalDoctorsCount,
          value: '${_controller.totalCount}',
          subtitle: 'Certified physicians provisioned',
          icon: Icons.people_outline_rounded,
          color: AdminColors.brandNavy,
        );

        final activeCard = _buildMetricCard(
          title: strings.activeDoctorsCount,
          value: '${_controller.activeCount}',
          subtitle: 'Eligible for patient consultations',
          icon: Icons.check_circle_outline_rounded,
          color: AdminColors.statusAvailable,
        );

        final inactiveCard = _buildMetricCard(
          title: strings.inactiveDoctorsCount,
          value: '${_controller.inactiveCount}',
          subtitle: 'Deactivated accounts (history intact)',
          icon: Icons.pause_circle_outline_rounded,
          color: AdminColors.statusCritical,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: totalCard),
              const SizedBox(width: AdminTheme.space16),
              Expanded(child: activeCard),
              const SizedBox(width: AdminTheme.space16),
              Expanded(child: inactiveCard),
            ],
          );
        } else {
          return Column(
            children: [
              totalCard,
              const SizedBox(height: AdminTheme.space12),
              Row(
                children: [
                  Expanded(child: activeCard),
                  const SizedBox(width: AdminTheme.space12),
                  Expanded(child: inactiveCard),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space20, vertical: AdminTheme.space16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AdminTheme.radius10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AdminTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AdminTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AdminTheme.headline1.copyWith(
                    color: AdminColors.brandNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AdminTheme.caption.copyWith(
                    fontSize: 11,
                    color: AdminColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TOOLBAR (SEARCH + FILTERS + SORT)
  // =========================================================================
  Widget _buildToolbar(dynamic strings) {
    final domains = AdminDomainAvailability.standardDomains;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        final searchField = TextField(
          controller: _searchTextController,
          onChanged: _controller.setSearchQuery,
          style: AdminTheme.bodyRegular.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: strings.searchDoctorPlaceholder,
            hintStyle: AdminTheme.bodyRegular.copyWith(color: AdminColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.brandTeal),
            suffixIcon: _searchTextController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: AdminColors.textMuted),
                    onPressed: () {
                      _searchTextController.clear();
                      _controller.setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AdminColors.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              borderSide: const BorderSide(color: AdminColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              borderSide: const BorderSide(color: AdminColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              borderSide: const BorderSide(color: AdminColors.brandTeal, width: 1.5),
            ),
          ),
        );

        final departmentDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AdminColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AdminTheme.radius8),
            border: Border.all(color: AdminColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _controller.selectedDepartment,
              hint: Text(strings.filterAllDepartments, style: const TextStyle(fontSize: 12)),
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AdminColors.brandTeal),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(strings.filterAllDepartments, style: const TextStyle(fontSize: 12)),
                ),
                ...domains.map((d) => DropdownMenuItem<String?>(
                      value: d['id'],
                      child: Text(d['name']!, style: const TextStyle(fontSize: 12)),
                    )),
              ],
              onChanged: _controller.setSelectedDepartment,
            ),
          ),
        );

        final statusDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AdminColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AdminTheme.radius8),
            border: Border.all(color: AdminColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _controller.selectedStatus,
              hint: Text(strings.filterAllStatuses, style: const TextStyle(fontSize: 12)),
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AdminColors.brandTeal),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(strings.filterAllStatuses, style: const TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem<String?>(
                  value: 'active',
                  child: Text(strings.statusActive, style: const TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem<String?>(
                  value: 'inactive',
                  child: Text(strings.statusInactive, style: const TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: _controller.setSelectedStatus,
            ),
          ),
        );

        final sortDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AdminColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AdminTheme.radius8),
            border: Border.all(color: AdminColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DoctorSortOption>(
              value: _controller.sortOption,
              icon: const Icon(Icons.sort_rounded, size: 18, color: AdminColors.brandNavy),
              items: [
                DropdownMenuItem(
                  value: DoctorSortOption.newest,
                  child: Text(strings.sortNewest, style: const TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: DoctorSortOption.nameAsc,
                  child: Text(strings.sortNameAsc, style: const TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: DoctorSortOption.department,
                  child: Text(strings.sortDepartment, style: const TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: DoctorSortOption.status,
                  child: Text(strings.sortStatus, style: const TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: (val) {
                if (val != null) _controller.setSortOption(val);
              },
            ),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AdminTheme.space12),
              departmentDropdown,
              const SizedBox(width: AdminTheme.space12),
              statusDropdown,
              const SizedBox(width: AdminTheme.space12),
              sortDropdown,
            ],
          );
        } else {
          return Column(
            children: [
              searchField,
              const SizedBox(height: AdminTheme.space10),
              Row(
                children: [
                  Expanded(child: departmentDropdown),
                  const SizedBox(width: AdminTheme.space8),
                  Expanded(child: statusDropdown),
                  const SizedBox(width: AdminTheme.space8),
                  Expanded(child: sortDropdown),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  // =========================================================================
  // MAIN DOCTORS TABLE
  // =========================================================================
  Widget _buildDoctorsTable(List<DoctorProfile> doctors, dynamic strings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AdminColors.backgroundSecondary),
              horizontalMargin: 16,
              columnSpacing: 24,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 64,
              columns: [
                DataColumn(
                  label: Text(
                    strings.tableColDoctorId.toUpperCase(),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    strings.tableColName.toUpperCase(),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    strings.tableColDepartment.toUpperCase(),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    strings.tableColPhone.toUpperCase(),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    strings.tableColStatus.toUpperCase(),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                DataColumn(
                  label: Text(
                    strings.tableColActions.toUpperCase(),
                    style: AdminTheme.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
              rows: doctors.map((doctor) => _buildDataRow(doctor, strings)).toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(DoctorProfile doctor, dynamic strings) {
    final domainName = AdminDomainAvailability.standardDomains.firstWhere(
      (d) => d['id'] == doctor.department,
      orElse: () => {'name': doctor.department},
    )['name']!;

    final opdDomain = OpdDomain.findById(doctor.department);
    final isInConsultation =
        doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation;

    return DataRow(
      cells: [
        // 1. Doctor Unique Code
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.brandNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AdminTheme.radius6),
            ),
            child: Text(
              doctor.doctorUniqueCode,
              style: AdminTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AdminColors.brandNavy,
                fontSize: 12,
              ),
            ),
          ),
        ),

        // 2. Name & Qualification
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                doctor.name,
                style: AdminTheme.bodyRegular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: doctor.isActive ? AdminColors.textPrimary : AdminColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                doctor.qualification,
                style: AdminTheme.caption.copyWith(
                  fontSize: 11,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // 3. Department
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                opdDomain?.icon ?? Icons.medical_services_outlined,
                size: 16,
                color: AdminColors.brandTeal,
              ),
              const SizedBox(width: 8),
              Text(
                domainName,
                style: AdminTheme.bodyRegular.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // 4. Phone (Masked)
        DataCell(
          Text(
            doctor.maskedPhone,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AdminColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 5. Account & Presence Status
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AdminTheme.radius6),
                  border: Border.all(
                    color: (doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  doctor.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: AdminTheme.badgeText.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Presence Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: doctor.availabilityStatus.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AdminTheme.radius6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      doctor.availabilityStatus.icon,
                      size: 11,
                      color: doctor.availabilityStatus.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.availabilityStatus.label,
                      style: AdminTheme.badgeText.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: doctor.availabilityStatus.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 6. Action Buttons
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Inspect / Details
              IconButton(
                tooltip: strings.actionViewDetails,
                icon: const Icon(Icons.visibility_outlined, size: 18, color: AdminColors.brandNavy),
                onPressed: () => _handleViewDetails(doctor),
              ),

              // Edit
              IconButton(
                tooltip: strings.actionEditDoctor,
                icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.brandTeal),
                onPressed: () => _handleEditDoctor(doctor),
              ),

              // Toggle Active/Inactive
              IconButton(
                tooltip: isInConsultation
                    ? strings.consultationBlockedWarning
                    : (doctor.isActive ? strings.actionDeactivate : strings.actionActivate),
                icon: Icon(
                  doctor.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                  size: 26,
                  color: isInConsultation
                      ? AdminColors.brandOrange
                      : (doctor.isActive ? AdminColors.statusAvailable : AdminColors.textMuted),
                ),
                onPressed: () => _handleToggleStatus(doctor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // EMPTY & ERROR STATES
  // =========================================================================
  Widget _buildEmptyView(dynamic strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.brandNavy.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 40,
              color: AdminColors.brandTeal,
            ),
          ),
          const SizedBox(height: AdminTheme.space16),
          Text(
            strings.noDoctorsFound,
            style: AdminTheme.headline2.copyWith(
              color: AdminColors.brandNavy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.noDoctorsFoundSubtitle,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AdminTheme.space16),
          AdminSecondaryButton(
            label: 'RESET FILTERS',
            icon: Icons.refresh_rounded,
            onPressed: () {
              _searchTextController.clear();
              _controller.resetFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AdminColors.statusCritical,
          ),
          const SizedBox(height: AdminTheme.space16),
          Text(
            _controller.errorMessage ?? 'Failed to load doctors.',
            style: AdminTheme.bodyRegular.copyWith(
              color: AdminColors.statusCritical,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AdminTheme.space16),
          AdminPrimaryButton(
            label: 'RETRY',
            icon: Icons.refresh_rounded,
            onPressed: _controller.refresh,
          ),
        ],
      ),
    );
  }
}
