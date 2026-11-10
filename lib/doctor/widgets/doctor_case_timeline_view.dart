import 'package:flutter/material.dart';
import '../../core/localization/kiosk_locale.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/case_timeline_event.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/patient_transfer_request.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_visit_detail_dialog.dart';

/// Interactive chronological case timeline component (Phase D14 & D15).
///
/// Visualizes the clinical progression of a Case across multiple visits,
/// consultations, inter-department referrals, and final Case Closure.
class DoctorCaseTimelineView extends StatefulWidget {
  final ClinicalCase clinicalCase;
  final List<ClinicalVisit> visits;
  final List<PatientTransferRequest> transfers;
  final ValueChanged<ClinicalVisit>? onViewVisit;
  final KioskLocale locale;

  const DoctorCaseTimelineView({
    super.key,
    required this.clinicalCase,
    required this.visits,
    this.transfers = const [],
    this.onViewVisit,
    this.locale = KioskLocale.english,
  });

  @override
  State<DoctorCaseTimelineView> createState() => _DoctorCaseTimelineViewState();
}

class _DoctorCaseTimelineViewState extends State<DoctorCaseTimelineView> {
  String _activeFilter = 'All';

  List<CaseTimelineEvent> _buildSortedEvents() {
    final events = <CaseTimelineEvent>[];

    for (final v in widget.visits) {
      events.add(
        CaseTimelineEvent.fromClinicalVisit(
          v,
          defaultDepartment: widget.clinicalCase.domain,
        ),
      );
    }

    for (final trf in widget.transfers) {
      if (trf.caseId == widget.clinicalCase.caseId) {
        events.add(CaseTimelineEvent.fromTransferRequest(trf));
      }
    }

    if (widget.clinicalCase.isClosed) {
      events.add(CaseTimelineEvent.fromCaseClosure(widget.clinicalCase));
    }

    // Sort chronologically ascending (oldest to newest)
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Apply Filter
    if (_activeFilter == 'Completed') {
      return events
          .where((e) =>
              e.eventType == CaseTimelineEventType.visitCompleted ||
              e.eventType == CaseTimelineEventType.caseClosed)
          .toList();
    } else if (_activeFilter == 'Transferred') {
      return events
          .where((e) =>
              e.eventType == CaseTimelineEventType.transferRequested ||
              e.eventType == CaseTimelineEventType.transferAccepted ||
              e.statusLabel == 'TRANSFERRED')
          .toList();
    } else if (_activeFilter == 'Active') {
      return events
          .where((e) =>
              e.eventType == CaseTimelineEventType.visitCreated &&
              e.statusLabel == 'ACTIVE')
          .toList();
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(widget.locale);
    final events = _buildSortedEvents();

    return Column(
      key: const ValueKey('DoctorCaseTimelineView_Root'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips Row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildFilterChip('All', strings.timelineFilterAll),
            _buildFilterChip('Completed', strings.timelineFilterCompleted),
            _buildFilterChip('Transferred', strings.timelineFilterTransferred),
            _buildFilterChip('Active', strings.timelineFilterActive),
          ],
        ),
        const SizedBox(height: DoctorTheme.space16),

        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                'No events found for this filter.',
                style: DoctorTheme.bodyMuted.copyWith(color: DoctorColors.textMuted),
              ),
            ),
          )
        else
          ListView.builder(
            key: const PageStorageKey('Timeline_Events_List'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isFirst = index == 0;
              final isLast = index == events.length - 1;
              return _buildTimelineItem(event, isFirst, isLast, strings);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: DoctorTheme.caption.copyWith(
          color: isSelected ? Colors.white : DoctorColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      selectedColor: DoctorColors.brandTeal,
      backgroundColor: DoctorColors.background,
      side: BorderSide(
        color: isSelected ? DoctorColors.brandTeal : DoctorColors.border,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilter = key;
          });
        }
      },
    );
  }

  Widget _buildTimelineItem(
    CaseTimelineEvent event,
    bool isFirst,
    bool isLast,
    DoctorStrings strings,
  ) {
    final date = event.timestamp;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    Color nodeColor;
    IconData nodeIcon;

    switch (event.eventType) {
      case CaseTimelineEventType.visitCompleted:
        nodeColor = DoctorColors.statusAvailable;
        nodeIcon = Icons.check_circle_outline_rounded;
        break;
      case CaseTimelineEventType.transferRequested:
      case CaseTimelineEventType.transferAccepted:
        nodeColor = DoctorColors.brandTeal;
        nodeIcon = Icons.swap_horiz_rounded;
        break;
      case CaseTimelineEventType.transferCancelled:
        nodeColor = DoctorColors.statusOffline;
        nodeIcon = Icons.cancel_outlined;
        break;
      case CaseTimelineEventType.visitCreated:
        nodeColor = DoctorColors.brandOrange;
        nodeIcon = Icons.play_circle_outline_rounded;
        break;
      case CaseTimelineEventType.caseClosed:
        nodeColor = DoctorColors.brandNavy;
        nodeIcon = Icons.lock_outline_rounded;
        break;
    }

    // Match corresponding visit if any
    final matchedVisit = widget.visits.cast<ClinicalVisit?>().firstWhere(
          (v) => v?.visitId == event.visitId,
          orElse: () => null,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Timestamp indicator (fixed stable width)
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                formattedDate,
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Middle: Timeline Node Marker
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: nodeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: nodeColor, width: 2),
              ),
              child: Center(
                child: Icon(nodeIcon, size: 12, color: nodeColor),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Content Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DoctorColors.background,
                borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                border: Border.all(
                  color: event.eventType == CaseTimelineEventType.caseClosed
                      ? DoctorColors.brandNavy.withValues(alpha: 0.3)
                      : DoctorColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: DoctorTheme.bodyBold.copyWith(
                            color: DoctorColors.brandNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (event.statusLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: nodeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                          ),
                          child: Text(
                            event.statusLabel!,
                            style: DoctorTheme.caption.copyWith(
                              color: nodeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (event.doctorName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${event.doctorName}${event.doctorQualification != null ? " • ${event.doctorQualification}" : ""}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textMuted,
                      ),
                    ),
                  ],
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description!,
                      style: DoctorTheme.body.copyWith(
                        color: DoctorColors.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (matchedVisit != null && matchedVisit.isCompleted) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        if (widget.onViewVisit != null) {
                          widget.onViewVisit!(matchedVisit);
                        } else {
                          showDialog(
                            context: context,
                            builder: (ctx) => DoctorVisitDetailDialog(
                              visit: matchedVisit,
                              domain: widget.clinicalCase.domain,
                              locale: widget.locale,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: DoctorColors.brandTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              strings.viewVisitDetailsButton,
                              style: DoctorTheme.caption.copyWith(
                                color: DoctorColors.brandTeal,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
