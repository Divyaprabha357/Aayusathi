import 'package:flutter/material.dart';
import '../models/patient_app_state.dart';
import '../models/patient_navigation_tab.dart';
import '../theme/patient_colors.dart';
import '../widgets/patient_bottom_navigation.dart';
import '../widgets/patient_top_bar.dart';
import 'patient_calendar_screen.dart';
import 'patient_cases_screen.dart';
import 'patient_dashboard_screen.dart';
import 'patient_reports_screen.dart';

/// Main container shell for the AAYUSATHI Patient App.
///
/// Houses:
/// - Consistent PatientTopBar with official logo and profile avatar
/// - IndexedStack content views for [Dashboard, Cases, Reports, Calendar]
/// - Stationary PatientBottomNavigation
class PatientMainShellScreen extends StatefulWidget {
  final PatientNavigationTab initialTab;

  const PatientMainShellScreen({
    super.key,
    this.initialTab = PatientNavigationTab.dashboard,
  });

  @override
  State<PatientMainShellScreen> createState() => _PatientMainShellScreenState();
}

class _PatientMainShellScreenState extends State<PatientMainShellScreen> {
  late PatientNavigationTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    PatientAppState.instance.setTab(_activeTab);
    PatientAppState.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    PatientAppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (_activeTab != PatientAppState.instance.currentTab && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeTab != PatientAppState.instance.currentTab) {
          setState(() {
            _activeTab = PatientAppState.instance.currentTab;
          });
        }
      });
    }
  }

  void _onTabSelected(PatientNavigationTab tab) {
    if (_activeTab != tab) {
      setState(() {
        _activeTab = tab;
      });
      PatientAppState.instance.setTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        onProfileTap: () {
          Navigator.of(context).pushNamed('/patient/profile');
        },
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Responsive desktop containment
          child: IndexedStack(
            index: _activeTab.index,
            children: const [
              PatientDashboardScreen(),
              PatientCasesScreen(),
              PatientReportsScreen(),
              PatientCalendarScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: PatientBottomNavigation(
            currentTab: _activeTab,
            onTabSelected: _onTabSelected,
          ),
        ),
      ),
    );
  }
}
