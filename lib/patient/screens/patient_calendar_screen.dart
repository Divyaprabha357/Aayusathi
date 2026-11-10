import 'package:flutter/material.dart';
import '../../doctor/models/clinical_case.dart';
import '../controllers/patient_calendar_controller.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_app_state.dart';
import '../models/patient_calendar_item.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_calendar_widget.dart';

/// Senior-accessible Health Calendar Screen (`/patient/calendar`).
///
/// Features:
/// - Clean monthly calendar with large cells and 48dp+ touch targets
/// - Real Doctor-recorded follow-up events derived from canonical ClinicalVisit records
/// - Clear distinction between Upcoming and Past follow-ups
/// - Polished event card with case context and direct "View Details" navigation
/// - Accessible healthcare empty-state when no follow-ups are scheduled for the selected date
/// - Fully localized across English, Hindi, and Marathi
class PatientCalendarScreen extends StatefulWidget {
  final PatientCalendarController? controller;

  const PatientCalendarScreen({
    super.key,
    this.controller,
  });

  @override
  State<PatientCalendarScreen> createState() => _PatientCalendarScreenState();
}

class _PatientCalendarScreenState extends State<PatientCalendarScreen> {
  late final PatientCalendarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientCalendarController();
    if (widget.controller == null) {
      _controller.loadEvents();
    }

    _handleTargetDate();
    PatientAppState.instance.addListener(_handleTargetDate);
  }

  @override
  void dispose() {
    PatientAppState.instance.removeListener(_handleTargetDate);
    super.dispose();
  }

  void _handleTargetDate() {
    final target = PatientAppState.instance.targetCalendarDate;
    if (target != null && mounted) {
      _controller.selectDate(target);
      PatientAppState.instance.clearTargetCalendarDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final selectedEvents = _controller.selectedDateEvents;
        final selectedDate = _controller.selectedDate;
        final monthName = strings.monthName(selectedDate.month);

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
                Text(
                  strings.calendarScreenTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PatientColors.navy,
                  ),
                ),
                const SizedBox(height: PatientSpacing.sectionGap),

                // Calendar Grid Widget
                PatientCalendarWidget(
                  visibleMonth: _controller.visibleMonth,
                  selectedDate: _controller.selectedDate,
                  events: _controller.events,
                  onDateSelected: _controller.selectDate,
                  onPreviousMonth: _controller.previousMonth,
                  onNextMonth: _controller.nextMonth,
                ),
                const SizedBox(height: 24),

                // Selected Date Events Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedDate.day} $monthName, ${selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isToday(selectedDate)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: PatientColors.tealLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          strings.calendarToday,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: PatientColors.tealDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Events List for Date or Empty State
                if (selectedEvents.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: PatientColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PatientColors.border, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: PatientColors.textMuted,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          strings.noFollowUpScheduled,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PatientColors.navy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.noFollowUpScheduledDesc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PatientColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedEvents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final isUpcoming = event.isUpcoming;

                      return Container(
                        decoration: BoxDecoration(
                          color: PatientColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUpcoming ? PatientColors.teal : PatientColors.border,
                            width: isUpcoming ? 1.8 : 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: PatientColors.shadow,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Pill Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUpcoming ? PatientColors.tealLight : const Color(0xFFF1F6F3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isUpcoming ? Icons.event_available_rounded : Icons.history_rounded,
                                    size: 18,
                                    color: isUpcoming ? PatientColors.tealDark : PatientColors.navy,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isUpcoming ? strings.upcomingFollowUp.toUpperCase() : strings.pastFollowUp.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: isUpcoming ? PatientColors.tealDark : PatientColors.navy,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${event.date.day} $monthName ${event.date.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isUpcoming ? PatientColors.tealDark : PatientColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Card Body
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ClinicalCase.normalizeDepartment(event.department),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: PatientColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.type == PatientCalendarEventType.followUp
                                        ? strings.followUpVisit
                                        : strings.calendarEventVisit,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: PatientColors.teal,
                                    ),
                                  ),
                                  if (event.doctorName != null && event.doctorName!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      event.doctorName!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: PatientColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (event.caseTitle != null && event.caseTitle!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      event.caseTitle!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: PatientColors.textMuted,
                                      ),
                                    ),
                                  ],

                                  // View Details Action Button
                                  if (event.caseId != null && event.visitId != null) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed(
                                            '/patient/cases/${event.caseId}/visits/${event.visitId}',
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: PatientColors.teal,
                                          side: const BorderSide(color: PatientColors.teal, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          strings.viewDetails,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
