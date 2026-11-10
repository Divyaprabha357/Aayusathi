import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../models/doctor_navigation_item.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_sidebar.dart';
import '../widgets/doctor_state_views.dart';

/// Doctor Consultation Screen with direct redirection to active Patient Workspace.
class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
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
    DoctorSidebarController.instance.addListener(_onSidebarChanged);
  }

  @override
  void dispose() {
    DoctorSidebarController.instance.removeListener(_onSidebarChanged);
    super.dispose();
  }

  void _onSidebarChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(DoctorNavigationItem item) {
    if (item.routeName != AppRoutes.doctorConsultation) {
      Navigator.of(context).pushReplacementNamed(item.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoctorDesktopScaffold(
      header: DoctorHeader(
        title: 'Active Consultation',
        subtitle: 'Live Clinical Documentation Desk',
        onBack: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard),
        onLogout: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorStandby),
      ),
      sidebar: DoctorSidebar(
        items: _navItems,
        activeRoute: AppRoutes.doctorConsultation,
        isCollapsed: DoctorSidebarController.instance.isCollapsed,
        onToggleCollapse: DoctorSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: DoctorEmptyView(
        icon: Icons.medical_information_outlined,
        title: 'Active Consultation Workspace',
        subtitle:
            'Consultation encounters and clinical documentation are conducted within the active Patient Workspace for each assigned patient.',
        actionLabel: 'OPEN PATIENT WORKSPACE',
        onAction: () => Navigator.of(context)
            .pushReplacementNamed(AppRoutes.doctorPatientWorkspace),
      ),
    );
  }
}
