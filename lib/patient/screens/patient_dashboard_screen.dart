import 'package:flutter/material.dart';
import '../controllers/patient_dashboard_controller.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_app_state.dart';
import '../models/patient_calendar_item.dart';
import '../models/patient_navigation_tab.dart';
import '../services/patient_follow_up_service.dart';
import '../services/patient_notification_service.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_error_state.dart';
import '../widgets/patient_loading_state.dart';
import '../widgets/patient_next_visit_card.dart';
import '../widgets/patient_notification_permission_banner.dart';
import '../widgets/patient_quick_access_card.dart';
import '../widgets/patient_section_header.dart';

/// Senior-accessible Patient Dashboard Screen (`/patient/dashboard`).
///
/// Houses:
/// - Sourced time-based greeting with authenticated patient name
/// - Next scheduled visit card or clean empty state
/// - Ongoing medical cases card with live count
/// - Quick access navigation cards (Cases, Reports, Calendar)
/// - Authorized non-diagnostic health profile summary
/// - Polished loading and error/retry states
class PatientDashboardScreen extends StatefulWidget {
  final PatientDashboardController? controller;

  const PatientDashboardScreen({
    super.key,
    this.controller,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late final PatientDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientDashboardController();
    _controller.loadDashboardData();
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    try {
      final pid = PatientAppState.instance.authenticatedPatientId;
      if (pid != null && pid.isNotEmpty) {
        await PatientNotificationService.instance.initialize();
        final followUps = await PatientFollowUpService()
            .getFollowUpsAndAppointmentsForPatient(patientId: pid);
        await PatientNotificationService.instance.syncFollowUpReminders(
          patientId: pid,
          followUps: followUps,
        );
      }
    } catch (e) {
      debugPrint('[PatientDashboardScreen] Notification sync safe fallback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.patient == null) {
          return const PatientLoadingState();
        }

        if (_controller.hasError && _controller.patient == null) {
          return Center(
            child: PatientErrorState(
              message: _controller.errorMessage ?? strings.unableToLoadData,
              onRetry: _controller.refresh,
            ),
          );
        }

        final greetingText = _controller.getGreeting(strings);

        return RefreshIndicator(
          color: PatientColors.teal,
          backgroundColor: PatientColors.surface,
          onRefresh: _controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: PatientSpacing.pageHorizontal,
              vertical: PatientSpacing.pageTop,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. WELCOME & GREETING CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5F2), Color(0xFFF6FBF9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PatientColors.border, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: PatientColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingText,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: PatientColors.navy,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.dashboardSubtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: PatientColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: PatientColors.border, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.waving_hand_rounded,
                          color: PatientColors.teal,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Educational Notification Permission Banner (if not dismissed & reminders not enabled)
                if (!PatientAppState.instance.notificationPromptDismissed)
                  FutureBuilder<bool>(
                    future: PatientNotificationService.instance.areRemindersEnabled(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data == false &&
                          !PatientAppState.instance.notificationPromptDismissed) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: PatientNotificationPermissionBanner(
                            onDismiss: () {
                              setState(() {
                                PatientAppState.instance.dismissNotificationPrompt();
                              });
                            },
                            onPermissionGranted: () {
                              setState(() {});
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Error banner if refresh fails while existing data is shown
                if (_controller.hasError) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: PatientColors.statusCriticalLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 18, color: PatientColors.statusCritical),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.errorMessage ?? strings.unableToLoadData,
                            style: const TextStyle(fontSize: 13, color: PatientColors.statusCritical),
                          ),
                        ),
                        TextButton(
                          onPressed: _controller.refresh,
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  ),
                ],

                // 2. NEXT VISIT CARD
                () {
                  final upcoming = _controller.nearestUpcomingVisit;
                  final apt = _controller.nextVisit;
                  final visitDate = upcoming?.date ?? apt?.createdAt;
                  final dept = upcoming?.department ?? apt?.domainId;
                  final status = (upcoming != null && upcoming.type == PatientCalendarEventType.followUp)
                      ? strings.followUpVisit
                      : (apt != null ? apt.status.name : (upcoming != null ? strings.calendarEventVisit : null));
                  final doctor = upcoming?.doctorName;
                  final token = (upcoming == null || upcoming.id.startsWith('appointment_')) ? apt?.queueNumber : null;

                  return PatientNextVisitCard(
                    appointmentDate: visitDate,
                    department: dept,
                    doctorName: doctor,
                    status: status,
                    tokenNumber: token,
                    hasError: _controller.hasAppointmentsError,
                    onRetry: _controller.retryAppointments,
                    onTap: () {
                      if (visitDate != null) {
                        PatientAppState.instance.navigateToCalendarWithDate(visitDate);
                      } else {
                        PatientAppState.instance.setTab(PatientNavigationTab.calendar);
                      }
                    },
                  );
                }(),
                const SizedBox(height: 20),

                // 3. ONGOING CASES SUMMARY CARD
                Material(
                  color: PatientColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      PatientAppState.instance.setTab(PatientNavigationTab.cases);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: PatientColors.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: PatientColors.shadow,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _controller.ongoingCasesCount > 0
                                  ? PatientColors.tealLight
                                  : const Color(0xFFF1F6F3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '${_controller.ongoingCasesCount}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _controller.ongoingCasesCount > 0
                                      ? PatientColors.tealDark
                                      : PatientColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _controller.ongoingCasesCount > 0
                                      ? strings.ongoingCasesTitle
                                      : strings.noOngoingCasesTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: PatientColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _controller.ongoingCasesCount > 0
                                      ? strings.ongoingCasesLabel
                                      : strings.noOngoingCasesSubtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: PatientColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: PatientColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. QUICK ACCESS SECTION
                PatientSectionHeader(
                  title: strings.quickAccessTitle,
                ),
                const SizedBox(height: 10),

                Column(
                  children: [
                    PatientQuickAccessCard(
                      icon: Icons.folder_shared_rounded,
                      title: strings.quickAccessCases,
                      description: strings.quickAccessCasesDesc,
                      onTap: () {
                        PatientAppState.instance.setTab(PatientNavigationTab.cases);
                      },
                    ),
                    const SizedBox(height: 12),
                    PatientQuickAccessCard(
                      icon: Icons.description_rounded,
                      title: strings.quickAccessReports,
                      description: strings.quickAccessReportsDesc,
                      iconColor: PatientColors.orange,
                      iconBgColor: PatientColors.orangeLight,
                      onTap: () {
                        PatientAppState.instance.setTab(PatientNavigationTab.reports);
                      },
                    ),
                    const SizedBox(height: 12),
                    PatientQuickAccessCard(
                      icon: Icons.calendar_month_rounded,
                      title: strings.quickAccessCalendar,
                      description: strings.quickAccessCalendarDesc,
                      iconColor: PatientColors.teal,
                      iconBgColor: PatientColors.tealLight,
                      onTap: () {
                        PatientAppState.instance.setTab(PatientNavigationTab.calendar);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. HEALTH PROFILE SUMMARY (AUTHORIZED & NON-DIAGNOSTIC)
                PatientSectionHeader(
                  title: strings.healthSummaryTitle.toUpperCase(),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: PatientColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PatientColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          label: 'PATIENT ID',
                          value: _controller.patientIdDisplay,
                        ),
                      ),
                      Container(width: 1, height: 36, color: PatientColors.border),
                      Expanded(
                        child: _buildSummaryItem(
                          label: 'AGE / GENDER',
                          value: _controller.ageGenderDisplay,
                        ),
                      ),
                      Container(width: 1, height: 36, color: PatientColors.border),
                      Expanded(
                        child: _buildSummaryItem(
                          label: 'BLOOD GROUP',
                          value: _controller.bloodGroupDisplay,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: PatientColors.textMuted,
            letterSpacing: 0.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: PatientColors.navy,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
