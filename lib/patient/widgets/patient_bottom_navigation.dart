import 'package:flutter/material.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_navigation_tab.dart';
import '../theme/patient_colors.dart';

/// Senior-accessible bottom navigation bar for the AAYUSATHI Patient App.
///
/// Features:
/// - Exactly FOUR tabs: [ Home ] [ Cases ] [ Reports ] [ Calendar ]
/// - Both Icon AND Text label displayed on every tab
/// - Visually distinct active indicator pill with high-contrast colors
/// - Generous touch targets (min 60dp height, 48dp+ tap areas)
class PatientBottomNavigation extends StatelessWidget {
  final PatientNavigationTab currentTab;
  final ValueChanged<PatientNavigationTab> onTabSelected;

  const PatientBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: PatientColors.surface,
        border: Border(
          top: BorderSide(color: PatientColors.border, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: PatientColors.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: PatientNavigationTab.values.map((tab) {
              final isSelected = tab == currentTab;
              final label = _getTabLabel(tab, strings);

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTabSelected(tab),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? PatientColors.activeTabBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tab.icon,
                                size: 22,
                                color: isSelected ? PatientColors.teal : PatientColors.inactiveTab,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? PatientColors.teal : PatientColors.inactiveTab,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getTabLabel(PatientNavigationTab tab, dynamic strings) {
    switch (tab) {
      case PatientNavigationTab.dashboard:
        return strings.tabHome;
      case PatientNavigationTab.cases:
        return strings.tabCases;
      case PatientNavigationTab.reports:
        return strings.tabReports;
      case PatientNavigationTab.calendar:
        return strings.tabCalendar;
    }
  }
}
