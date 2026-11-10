import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/opd_domain.dart';
import '../controllers/admin_availability_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../localization/admin_strings.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_availability_dialogs.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_doctor_details_dialog.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';

/// Central Administrative Doctor Availability Screen (Phase A6).
///
/// Route: `/admin/availability`
/// Features:
/// - Real-time physician presence monitoring via Firestore streams
/// - 4 KPI metrics (Total Active, Available, In Consultation, Offline)
/// - 8-Domain capacity distribution breakdown
/// - Multi-parameter search & combinable filtering
/// - Operational availability controls (Set Available, Set Offline)
/// - Active consultation safeguard protection (hard-blocked)
/// - Doctor profile inspection modal with masked contact privacy
class AdminAvailabilityScreen extends StatefulWidget {
  const AdminAvailabilityScreen({super.key});

  @override
  State<AdminAvailabilityScreen> createState() => _AdminAvailabilityScreenState();
}

class _AdminAvailabilityScreenState extends State<AdminAvailabilityScreen> {
  final AdminAvailabilityController _controller = AdminAvailabilityController.instance;
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

  void _onNavItemSelected(AdminNavigationItem item) {
    if (item.routeName == AppRoutes.adminAvailability) return;
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

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AdminLocalizations.of(context);
    final isSidebarCollapsed = AdminSidebarController.instance.isCollapsed;

    return AdminDesktopScaffold(
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: AppRoutes.adminAvailability,
        onItemSelected: _onNavItemSelected,
        isCollapsed: isSidebarCollapsed,
        onToggleCollapse: () => AdminSidebarController.instance.toggle(),
      ),
      header: AdminHeader(
        title: l10n.availabilityHeaderTitle,
        subtitle: l10n.availabilityHeaderSubtitle,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AdminStrings l10n) {
    if (_controller.isLoading && _controller.allDoctors.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AdminColors.brandTeal),
      );
    }

    if (_controller.errorMessage != null && _controller.allDoctors.isEmpty) {
      return Center(
        child: AdminCard(
          padding: const EdgeInsets.all(AdminTheme.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AdminColors.statusCritical),
              const SizedBox(height: AdminTheme.space16),
              Text(
                l10n.errorLoadingAvailability,
                style: AdminTheme.headline2.copyWith(color: AdminColors.brandNavy),
              ),
              const SizedBox(height: AdminTheme.space8),
              Text(
                _controller.errorMessage!,
                style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AdminTheme.space24),
              AdminPrimaryButton(
                label: l10n.retry,
                icon: Icons.refresh_rounded,
                onPressed: () => _controller.refresh(),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header Banner
              _buildPageHeader(l10n),
              const SizedBox(height: AdminTheme.space20),

              // KPI Metrics Summary Strip
              _buildKpiMetricsStrip(l10n),
              const SizedBox(height: AdminTheme.space20),

              // 8-Domain Capacity Matrix
              _buildDomainCapacitySection(l10n),
              const SizedBox(height: AdminTheme.space20),

              // Search, Filter & Sort Controls
              _buildFiltersBar(l10n),
              const SizedBox(height: AdminTheme.space16),

              // Doctor Availability Data Table
              _buildAvailabilityTable(context, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(AdminStrings l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.availabilityHeaderTitle,
                style: AdminTheme.headline1.copyWith(
                  color: AdminColors.brandNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.availabilityHeaderSubtitle,
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AdminTheme.space16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AdminColors.brandTeal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
                border: Border.all(color: AdminColors.brandTeal.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    'REAL-TIME STREAM ACTIVE',
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AdminTheme.space8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AdminColors.brandNavy, size: 20),
              tooltip: l10n.refresh,
              onPressed: _controller.isLoading ? null : () => _controller.refresh(),
            ),
            const SizedBox(width: AdminTheme.space8),
            AdminSecondaryButton(
              label: l10n.viewAllDoctors,
              icon: Icons.list_alt_rounded,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminDoctors),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiMetricsStrip(AdminStrings l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (AdminTheme.space16 * 3)) / 4;

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: l10n.totalActiveDoctors,
                count: '${_controller.totalActiveDoctors}',
                subtitle: 'Active Physician Workstations',
                icon: Icons.people_alt_rounded,
                color: AdminColors.brandNavy,
              ),
            ),
            const SizedBox(width: AdminTheme.space16),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: l10n.onlineAvailable,
                count: '${_controller.onlineAvailableDoctors}',
                subtitle: 'Eligible for Queue Intake',
                icon: Icons.check_circle_rounded,
                color: AdminColors.statusAvailable,
              ),
            ),
            const SizedBox(width: AdminTheme.space16),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: l10n.inConsultation,
                count: '${_controller.inConsultationDoctors}',
                subtitle: 'Active Clinical Consultations',
                icon: Icons.record_voice_over_rounded,
                color: AdminColors.brandOrange,
              ),
            ),
            const SizedBox(width: AdminTheme.space16),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                title: l10n.offline,
                count: '${_controller.offlineDoctors}',
                subtitle: 'Inactive on Workstation',
                icon: Icons.circle_outlined,
                color: AdminColors.textMuted,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AdminCard(
      padding: const EdgeInsets.all(AdminTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AdminTheme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: AdminColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.space12),
          Text(
            count,
            style: AdminTheme.headline1.copyWith(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDomainCapacitySection(AdminStrings l10n) {
    final summaries = _controller.domainSummaries;

    return AdminCard(
      padding: const EdgeInsets.all(AdminTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined, size: 18, color: AdminColors.brandNavy),
                  const SizedBox(width: 8),
                  Text(
                    l10n.domainCapacityTitle,
                    style: AdminTheme.headline2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.brandNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '8 Clinical Specialty Domains',
                style: AdminTheme.caption.copyWith(
                  fontSize: 11,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.space12),
          const Divider(height: 1, color: AdminColors.borderSubtle),
          const SizedBox(height: AdminTheme.space12),

          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - (AdminTheme.space12 * 3)) / 4;

              return Wrap(
                spacing: AdminTheme.space12,
                runSpacing: AdminTheme.space12,
                children: summaries.map((summary) {
                  final opdDomain = OpdDomain.findById(summary.domainId);

                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(AdminTheme.space10),
                    decoration: BoxDecoration(
                      color: AdminColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AdminTheme.radius8),
                      border: Border.all(color: AdminColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              opdDomain?.icon ?? Icons.medical_services_outlined,
                              size: 15,
                              color: AdminColors.brandNavy,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                summary.domainName,
                                style: AdminTheme.bodyBold.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.brandNavy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildDomainBadge(
                              label: 'Avail: ${summary.available}',
                              color: AdminColors.statusAvailable,
                            ),
                            _buildDomainBadge(
                              label: 'Consult: ${summary.inConsultation}',
                              color: AdminColors.brandOrange,
                            ),
                            _buildDomainBadge(
                              label: 'Off: ${summary.offline}',
                              color: AdminColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDomainBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AdminTheme.radius4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFiltersBar(AdminStrings l10n) {
    return AdminCard(
      padding: const EdgeInsets.all(AdminTheme.space14),
      child: Wrap(
        spacing: AdminTheme.space12,
        runSpacing: AdminTheme.space10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Input
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchTextController,
              onChanged: (val) => _controller.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: l10n.searchAvailabilityPlaceholder,
                hintStyle: AdminTheme.bodyRegular.copyWith(
                  color: AdminColors.textMuted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AdminColors.textSecondary),
                suffixIcon: _searchTextController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchTextController.clear();
                          _controller.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: AdminColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  borderSide: const BorderSide(color: AdminColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  borderSide: const BorderSide(color: AdminColors.borderSubtle),
                ),
              ),
            ),
          ),

          // Department Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _controller.selectedDepartment ?? 'all',
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AdminColors.brandTeal),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 12, color: AdminColors.textPrimary),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Departments')),
                  ...AdminDomainAvailability.standardDomains.map((d) {
                    return DropdownMenuItem(value: d['id'], child: Text(d['name']!));
                  }),
                ],
                onChanged: (val) => _controller.setSelectedDepartment(val == 'all' ? null : val),
              ),
            ),
          ),

          // Account Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _controller.selectedAccountStatus ?? 'all',
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AdminColors.brandTeal),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 12, color: AdminColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Accounts')),
                  DropdownMenuItem(value: 'active', child: Text('Active Only')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive Only')),
                ],
                onChanged: (val) => _controller.setSelectedAccountStatus(val == 'all' ? null : val),
              ),
            ),
          ),

          // Availability Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _controller.selectedAvailabilityStatus ?? 'all',
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AdminColors.brandTeal),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 12, color: AdminColors.textPrimary),
                items: [
                  DropdownMenuItem(value: 'all', child: Text(l10n.filterAvailabilityAll)),
                  DropdownMenuItem(value: 'available', child: Text(l10n.filterAvailabilityAvailable)),
                  DropdownMenuItem(value: 'inconsultation', child: Text(l10n.filterAvailabilityInConsultation)),
                  DropdownMenuItem(value: 'offline', child: Text(l10n.filterAvailabilityOffline)),
                ],
                onChanged: (val) => _controller.setSelectedAvailabilityStatus(val == 'all' ? null : val),
              ),
            ),
          ),

          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(AdminTheme.radius8),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DoctorAvailabilitySortOption>(
                value: _controller.sortOption,
                icon: const Icon(Icons.sort_rounded, size: 18, color: AdminColors.brandTeal),
                style: AdminTheme.bodyRegular.copyWith(fontSize: 12, color: AdminColors.textPrimary),
                items: const [
                  DropdownMenuItem(
                    value: DoctorAvailabilitySortOption.nameAsc,
                    child: Text('Sort: Name'),
                  ),
                  DropdownMenuItem(
                    value: DoctorAvailabilitySortOption.department,
                    child: Text('Sort: Department'),
                  ),
                  DropdownMenuItem(
                    value: DoctorAvailabilitySortOption.availability,
                    child: Text('Sort: Availability'),
                  ),
                  DropdownMenuItem(
                    value: DoctorAvailabilitySortOption.lastActivity,
                    child: Text('Sort: Last Activity'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) _controller.setSortOption(val);
                },
              ),
            ),
          ),

          // Reset Filters Button
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: AdminColors.textSecondary),
            tooltip: 'Reset Filters',
            onPressed: () {
              _searchTextController.clear();
              _controller.resetFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTable(BuildContext context, AdminStrings l10n) {
    final doctors = _controller.filteredDoctors;

    if (doctors.isEmpty) {
      if (_controller.allDoctors.isEmpty) {
        return AdminCard(
          padding: const EdgeInsets.all(AdminTheme.space40),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.person_search_rounded, size: 48, color: AdminColors.textMuted),
                const SizedBox(height: AdminTheme.space16),
                Text(
                  l10n.noActiveDoctorsTitle,
                  style: AdminTheme.headline2.copyWith(color: AdminColors.brandNavy),
                ),
                const SizedBox(height: AdminTheme.space8),
                Text(
                  l10n.noActiveDoctorsSubtitle,
                  style: AdminTheme.caption.copyWith(color: AdminColors.textSecondary),
                ),
                const SizedBox(height: AdminTheme.space20),
                AdminPrimaryButton(
                  label: l10n.addNewDoctorButton,
                  icon: Icons.person_add_rounded,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminDoctorsAdd),
                ),
              ],
            ),
          ),
        );
      }

      return AdminCard(
        padding: const EdgeInsets.all(AdminTheme.space32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.filter_list_off_rounded, size: 40, color: AdminColors.textMuted),
              const SizedBox(height: AdminTheme.space12),
              Text(
                'No Doctors Match Filter Criteria',
                style: AdminTheme.bodyBold.copyWith(color: AdminColors.brandNavy),
              ),
              const SizedBox(height: AdminTheme.space8),
              AdminSecondaryButton(
                label: 'RESET ALL FILTERS',
                onPressed: () {
                  _searchTextController.clear();
                  _controller.resetFilters();
                },
              ),
            ],
          ),
        ),
      );
    }

    return AdminCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        child: Column(
          children: [
            // Table Header Row
            Container(
              color: AdminColors.backgroundSecondary,
              padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16, vertical: AdminTheme.space12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildTableHeader(l10n.tableColDoctor)),
                  Expanded(flex: 2, child: _buildTableHeader(l10n.tableColDoctorIdA6)),
                  Expanded(flex: 2, child: _buildTableHeader(l10n.tableColDepartmentA6)),
                  Expanded(flex: 2, child: _buildTableHeader(l10n.tableColAccount)),
                  Expanded(flex: 3, child: _buildTableHeader(l10n.tableColAvailability)),
                  Expanded(flex: 2, child: _buildTableHeader(l10n.tableColLastActivity)),
                  Expanded(flex: 5, child: Align(alignment: Alignment.centerRight, child: _buildTableHeader('OPERATIONAL ACTION'))),
                ],
              ),
            ),
            const Divider(height: 1, color: AdminColors.borderSubtle),

            // Doctor Rows
            Column(
              children: [
                for (int i = 0; i < doctors.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AdminColors.borderSubtle),
                  _buildDoctorRow(context, doctors[i], l10n),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: AdminTheme.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: AdminColors.brandNavy,
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDoctorRow(BuildContext context, DoctorProfile doctor, AdminStrings l10n) {
    final domainName = AdminDomainAvailability.standardDomains.firstWhere(
      (d) => d['id'] == doctor.department,
      orElse: () => {'name': doctor.department.toUpperCase()},
    )['name']!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AdminTheme.space16, vertical: AdminTheme.space12),
      child: Row(
        children: [
          // 1. DOCTOR (Name & Qualification)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => AdminDoctorDetailsDialog.show(context, doctor: doctor),
              borderRadius: BorderRadius.circular(AdminTheme.radius6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: AdminTheme.bodyBold.copyWith(
                      color: AdminColors.brandNavy,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor.qualification.isNotEmpty ? doctor.qualification : 'Clinical Physician',
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // 2. DOCTOR ID
          Expanded(
            flex: 2,
            child: Text(
              doctor.doctorUniqueCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AdminColors.brandTeal,
                ),
              ),
            ),

            // 3. DEPARTMENT
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    OpdDomain.findById(doctor.department)?.icon ?? Icons.medical_services_outlined,
                    size: 14,
                    color: AdminColors.brandNavy,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      domainName,
                      style: AdminTheme.bodyRegular.copyWith(
                        fontSize: 12,
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 4. ACCOUNT STATUS (Active / Inactive)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AdminTheme.radius4),
                    border: Border.all(
                      color: (doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    doctor.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: doctor.isActive ? AdminColors.statusAvailable : AdminColors.statusCritical,
                    ),
                  ),
                ),
              ),
            ),

            // 5. AVAILABILITY STATUS (Counting rule: Inactive is OFFLINE)
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildAvailabilityBadge(doctor),
              ),
            ),

            // 6. LAST ACTIVITY
            Expanded(
              flex: 2,
              child: Text(
                _formatTimeAgo(doctor.updatedAt),
                style: AdminTheme.caption.copyWith(
                  fontSize: 11,
                  color: AdminColors.textSecondary,
                ),
              ),
            ),

            // 7. OPERATIONAL ACTION
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildActionButtons(context, doctor, l10n),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildAvailabilityBadge(DoctorProfile doctor) {
    if (!doctor.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AdminColors.textMuted.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AdminTheme.radius4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle_outlined, size: 10, color: AdminColors.textMuted),
            SizedBox(width: 4),
            Text(
              'OFFLINE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AdminColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final status = doctor.availabilityStatus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AdminTheme.radius4),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DoctorProfile doctor, AdminStrings l10n) {
    // 1. Inactive Doctor: Must activate via Manage Doctors
    if (!doctor.isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'INACTIVE ACCOUNT',
            style: AdminTheme.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.brandTeal),
            tooltip: 'View Profile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => AdminDoctorDetailsDialog.show(context, doctor: doctor),
          ),
        ],
      );
    }

    // 2. Active Doctor in Consultation: Locked safeguard
    if (doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const ValueKey('consultation_lock_action_btn'),
            onTap: () => AdminConsultationLockedDialog.show(context, doctor: doctor),
            borderRadius: BorderRadius.circular(AdminTheme.radius6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AdminColors.brandOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AdminTheme.radius6),
                border: Border.all(color: AdminColors.brandOrange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: AdminColors.brandOrange),
                  SizedBox(width: 4),
                  Text(
                    'IN CONSULTATION',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.brandOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.brandTeal),
            tooltip: 'View Profile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => AdminDoctorDetailsDialog.show(context, doctor: doctor),
          ),
        ],
      );
    }

    // 3. Active Doctor: OFFLINE -> SET AVAILABLE
    if (doctor.availabilityStatus == DoctorAvailabilityStatus.offline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.statusAvailable,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radius6),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 12),
            label: const Text(
              'SET AVAILABLE',
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
            ),
            onPressed: () => AdminSetAvailableDialog.show(
              context,
              doctor: doctor,
              controller: _controller,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.brandTeal),
            tooltip: 'View Profile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => AdminDoctorDetailsDialog.show(context, doctor: doctor),
          ),
        ],
      );
    }

    // 4. Active Doctor: AVAILABLE / ONLINE -> SET OFFLINE
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.brandNavy,
            side: const BorderSide(color: AdminColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radius6),
            ),
          ),
          icon: const Icon(Icons.power_settings_new_rounded, size: 12, color: AdminColors.textSecondary),
          label: const Text(
            'SET OFFLINE',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
          onPressed: () => AdminSetOfflineDialog.show(
            context,
            doctor: doctor,
            controller: _controller,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 16, color: AdminColors.brandTeal),
          tooltip: 'View Profile',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          onPressed: () => AdminDoctorDetailsDialog.show(context, doctor: doctor),
        ),
      ],
    );
  }
}
