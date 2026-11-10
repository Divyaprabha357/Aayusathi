import 'package:flutter/material.dart';
import '../controllers/patient_cases_controller.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_app_state.dart';
import '../models/patient_navigation_tab.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_case_card.dart';
import '../widgets/patient_empty_state.dart';
import '../widgets/patient_empty_state_visual.dart';
import '../widgets/patient_loading_state.dart';
import '../widgets/patient_segmented_control.dart';

/// Senior-accessible Cases Screen displaying Active and Completed clinical cases.
class PatientCasesScreen extends StatefulWidget {
  final PatientCasesController? controller;

  const PatientCasesScreen({
    super.key,
    this.controller,
  });

  @override
  State<PatientCasesScreen> createState() => _PatientCasesScreenState();
}

class _PatientCasesScreenState extends State<PatientCasesScreen> {
  late final PatientCasesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientCasesController();
    _controller.loadCases();
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const PatientLoadingState();
        }

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          color: PatientColors.teal,
          backgroundColor: PatientColors.surface,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PatientSpacing.maxContentWidth),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: PatientSpacing.pageHorizontal,
                  vertical: PatientSpacing.pageTop,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Screen Title
                    Text(
                      strings.casesScreenTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PatientColors.navy,
                      ),
                    ),
                    const SizedBox(height: PatientSpacing.sectionGap),

                    // Standard Zero-Jitter Segmented Control (Active / Completed)
                    PatientSegmentedControl<PatientCasesTab>(
                      selectedValue: _controller.selectedTab,
                      items: [
                        PatientSegmentItem(
                          value: PatientCasesTab.active,
                          label: strings.casesTabActive,
                        ),
                        PatientSegmentItem(
                          value: PatientCasesTab.completed,
                          label: strings.casesTabCompleted,
                        ),
                      ],
                      onValueChanged: (tab) => _controller.selectTab(tab),
                    ),
                    const SizedBox(height: PatientSpacing.largeGap),

                    // Main Content: Error / Empty / List
                    if (_controller.hasError)
                      _buildErrorCard(strings)
                    else if (_controller.displayedCases.isEmpty)
                      _buildEmptyState(strings)
                    else
                      _buildCasesList(context),

                    const SizedBox(height: PatientSpacing.bottomSafeSpace),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCasesList(BuildContext context) {
    final cases = _controller.displayedCases;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cases.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = cases[index];
        return PatientCaseCard(
          clinicalCase: item,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/patient/cases/${item.caseId}',
              arguments: {
                'caseId': item.caseId,
                'clinicalCase': item,
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(dynamic strings) {
    final isActiveTab = _controller.selectedTab == PatientCasesTab.active;

    return PatientEmptyState(
      visualType: isActiveTab
          ? PatientEmptyStateVisualType.noActiveCases
          : PatientEmptyStateVisualType.noCompletedCases,
      title: isActiveTab ? strings.casesEmptyActive : strings.casesEmptyCompleted,
      message: isActiveTab
          ? strings.casesEmptyActiveDesc
          : strings.casesEmptyCompletedDesc,
      actionText: isActiveTab ? strings.viewDashboardAction : null,
      onActionTap: isActiveTab
          ? () {
              PatientAppState.instance.setTab(PatientNavigationTab.dashboard);
            }
          : null,
    );
  }

  Widget _buildErrorCard(dynamic strings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatientColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: PatientColors.orange,
          ),
          const SizedBox(height: 12),
          Text(
            strings.casesErrorLoading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: PatientColors.navy,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _controller.loadCases(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                strings.retry,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PatientColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
