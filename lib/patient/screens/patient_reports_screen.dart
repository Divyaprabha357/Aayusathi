import 'package:flutter/material.dart';
import '../controllers/patient_reports_controller.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_app_state.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_empty_state.dart';
import '../widgets/patient_empty_state_visual.dart';
import '../widgets/patient_error_state.dart';
import '../widgets/patient_loading_state.dart';
import '../widgets/patient_report_card.dart';
import '../widgets/patient_segmented_control.dart';

/// Senior-accessible Medical Reports Screen shell (`/patient/reports`).
class PatientReportsScreen extends StatefulWidget {
  final PatientReportsController? controller;

  const PatientReportsScreen({
    super.key,
    this.controller,
  });

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  late final PatientReportsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientReportsController();
    _controller.loadReports();
    PatientAppState.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    PatientAppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    final targetId = PatientAppState.instance.targetInvestigationId;
    if (targetId != null && targetId.isNotEmpty) {
      _controller.focusInvestigation(targetId);
    }
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

        if (_controller.hasError && _controller.displayedReports.isEmpty) {
          return Center(
            child: PatientErrorState(
              message: _controller.errorMessage ?? strings.unableToLoadReports,
              onRetry: _controller.refresh,
            ),
          );
        }

        final reports = _controller.displayedReports;
        final isSubmittedTab = _controller.selectedTab == PatientReportsTab.submitted;

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
                    Text(
                      strings.reportsScreenTitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PatientColors.navy,
                      ),
                    ),
                    const SizedBox(height: PatientSpacing.sectionGap),

                    // Standard Zero-Jitter Segmented Control (SUBMITTED / YET TO SUBMIT)
                    PatientSegmentedControl<PatientReportsTab>(
                      selectedValue: _controller.selectedTab,
                      items: [
                        PatientSegmentItem(
                          value: PatientReportsTab.submitted,
                          label: strings.reportsTabSubmitted,
                        ),
                        PatientSegmentItem(
                          value: PatientReportsTab.yetToSubmit,
                          label: strings.reportsTabYetToSubmit,
                        ),
                      ],
                      onValueChanged: (tab) => _controller.selectTab(tab),
                    ),
                    const SizedBox(height: PatientSpacing.largeGap),

                    // Reports List or Healthcare-Themed Empty State
                    if (reports.isEmpty)
                      PatientEmptyState(
                        visualType: isSubmittedTab
                            ? PatientEmptyStateVisualType.noSubmittedReports
                            : PatientEmptyStateVisualType.noPendingReports,
                        title: isSubmittedTab
                            ? strings.reportsEmptySubmitted
                            : strings.reportsEmptyYetToSubmit,
                        message: isSubmittedTab
                            ? strings.reportsEmptySubmittedDesc
                            : strings.reportsEmptyYetToSubmitDesc,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          final isHighlighted =
                              report.requestId == _controller.highlightedInvestigationId;
                          final caseTitle = _controller.getCaseTitle(report.caseId);
                          final visitDate = _controller.getVisitDate(report.visitId);

                          return PatientReportCard(
                            report: report,
                            caseTitle: caseTitle,
                            visitDate: visitDate,
                            isHighlighted: isHighlighted,
                            onTap: () async {
                              final res = await Navigator.of(context).pushNamed(
                                '/patient/reports/${report.requestId}',
                                arguments: {
                                  'reportId': report.requestId,
                                  'report': report,
                                  'caseTitle': caseTitle,
                                  'visitDate': visitDate,
                                },
                              );
                              if (res == true) {
                                await _controller.refresh();
                              }
                            },
                          );
                        },
                      ),
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
}
