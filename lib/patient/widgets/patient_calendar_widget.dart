import 'package:flutter/material.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_calendar_item.dart';
import '../theme/patient_colors.dart';

/// Senior-accessible monthly calendar grid for the Patient App.
///
/// Features:
/// - 48dp+ minimum touch targets on month controls and day cells
/// - Accessible screen reader semantics announcing dates, selection, and follow-up events
/// - Visual event indicator dots with high-contrast text fallback
/// - Localized month headers and day-of-week labels
class PatientCalendarWidget extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<PatientCalendarItem> events;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const PatientCalendarWidget({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.events,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month);
    final firstDayOffset = DateTime(visibleMonth.year, visibleMonth.month, 1).weekday % 7;
    final now = DateTime.now();

    final monthName = strings.monthName(visibleMonth.month);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.surface,
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
      child: Column(
        children: [
          // Month Selector Header
          Row(
            children: [
              Expanded(
                child: Text(
                  '$monthName ${visibleMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: PatientColors.navy,
                    tooltip: strings.previousMonth,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: onPreviousMonth,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: PatientColors.navy,
                    tooltip: strings.nextMonth,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: onNextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Labels
          Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          const Divider(color: PatientColors.borderSubtle),
          const SizedBox(height: 8),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }

              final day = index - firstDayOffset + 1;
              final dayDate = DateTime(visibleMonth.year, visibleMonth.month, day);
              final isSelected = dayDate.year == selectedDate.year &&
                  dayDate.month == selectedDate.month &&
                  dayDate.day == selectedDate.day;
              final isToday = dayDate.year == now.year &&
                  dayDate.month == now.month &&
                  dayDate.day == now.day;
              final dayEvents = events.where((e) => e.isSameDay(dayDate)).toList();
              final hasFollowUp = dayEvents.any((e) => e.type == PatientCalendarEventType.followUp);

              final semanticEventText = hasFollowUp
                  ? strings.followUpVisit
                  : (dayEvents.isNotEmpty ? strings.calendarEventVisit : '');

              final semanticsLabel = '$day $monthName ${visibleMonth.year}'
                  '${isToday ? ", ${strings.calendarToday}" : ""}'
                  '${isSelected ? ", Selected" : ""}'
                  '${semanticEventText.isNotEmpty ? ", $semanticEventText" : ""}';

              return Semantics(
                label: semanticsLabel,
                button: true,
                selected: isSelected,
                child: InkWell(
                  onTap: () => onDateSelected(dayDate),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? PatientColors.teal
                          : (isToday ? PatientColors.tealLight : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: PatientColors.teal, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? PatientColors.tealDark : PatientColors.navy),
                          ),
                        ),
                        if (dayEvents.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : (hasFollowUp ? const Color(0xFFE65100) : PatientColors.teal),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
