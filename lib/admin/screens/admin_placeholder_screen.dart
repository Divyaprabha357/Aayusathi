import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../models/admin_navigation_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';

import '../services/admin_auth_service.dart';

/// Shell-compatible placeholder screen for future administrative routes.
/// Allows seamless sidebar navigation in Phase A1/A2 without whole-page reloads.
class AdminPlaceholderScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String currentRoute;
  final String featureDescription;
  final IconData featureIcon;

  const AdminPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentRoute,
    required this.featureDescription,
    required this.featureIcon,
  });

  @override
  State<AdminPlaceholderScreen> createState() => _AdminPlaceholderScreenState();
}

class _AdminPlaceholderScreenState extends State<AdminPlaceholderScreen> {
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
    AdminSidebarController.instance.addListener(_onSidebarChanged);
  }

  @override
  void dispose() {
    AdminSidebarController.instance.removeListener(_onSidebarChanged);
    super.dispose();
  }

  void _onSidebarChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    if (item.routeName != widget.currentRoute) {
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

  @override
  Widget build(BuildContext context) {
    return AdminDesktopScaffold(
      header: AdminHeader(
        title: widget.title,
        subtitle: widget.subtitle,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: widget.currentRoute,
        isCollapsed: AdminSidebarController.instance.isCollapsed,
        onToggleCollapse: AdminSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminTheme.space32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(AdminTheme.space32),
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(AdminTheme.radius16),
                border: Border.all(color: AdminColors.borderSubtle),
                boxShadow: AdminTheme.shadowCard,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AdminColors.brandTeal.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.featureIcon,
                      size: 32,
                      color: AdminColors.brandTeal,
                    ),
                  ),
                  const SizedBox(height: AdminTheme.space20),
                  Text(
                    widget.title,
                    style: AdminTheme.headline1.copyWith(
                      color: AdminColors.brandNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AdminTheme.space8),
                  Text(
                    widget.subtitle,
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.brandTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AdminTheme.space16),
                  Text(
                    widget.featureDescription,
                    style: AdminTheme.bodyRegular.copyWith(
                      color: AdminColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AdminTheme.space24),
                  AdminPrimaryButton(
                    label: 'Return to Dashboard',
                    icon: Icons.dashboard_rounded,
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboard);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
