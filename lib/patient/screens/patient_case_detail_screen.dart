import 'package:flutter/material.dart';
import '../../core/backend/backend_mode.dart';
import '../../doctor/models/clinical_case.dart';
import '../../doctor/models/clinical_visit.dart';
import '../localization/patient_localizations.dart';
import '../services/patient_session_service.dart';
import '../theme/patient_colors.dart';
import '../widgets/patient_empty_state.dart';
import '../widgets/patient_loading_state.dart';
import '../widgets/patient_top_bar.dart';
import '../widgets/patient_visit_card.dart';

/// Senior-accessible Case Detail Screen (`/patient/cases/:caseId`).
///
/// Features:
/// - Authenticated Patient-scoped Firestore queries.
/// - Detailed Case metadata (domain, status, dates, description).
/// - Chronological Visit Timeline / History (Visit 3, Visit 2, Visit 1...).
/// - Read-only guardrails: zero editing or modification allowed.
/// - Graceful loading, empty, and retry error states.
class PatientCaseDetailScreen extends StatefulWidget {
  final String caseId;
  final ClinicalCase? preloadedCase;

  const PatientCaseDetailScreen({
    super.key,
    required this.caseId,
    this.preloadedCase,
  });

  @override
  State<PatientCaseDetailScreen> createState() => _PatientCaseDetailScreenState();
}

class _PatientCaseDetailScreenState extends State<PatientCaseDetailScreen> {
  ClinicalCase? _clinicalCase;
  List<ClinicalVisit> _visits = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _clinicalCase = widget.preloadedCase;
    _loadCaseDetails();
  }

  Future<void> _loadCaseDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final patientId = PatientSessionService.instance.authenticatedPatientId;
    if (patientId == null || patientId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    try {
      final caseRepo = BackendProvider.instance.caseRepository;
      final visitRepo = BackendProvider.instance.clinicalVisitRepository;

      final fetchedCase = (_clinicalCase != null && _clinicalCase!.patientId == patientId)
          ? _clinicalCase
          : await caseRepo.getCaseById(
              patientId: patientId,
              caseId: widget.caseId,
            );

      if (fetchedCase == null || fetchedCase.patientId != patientId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      final fetchedVisits = await visitRepo.getVisitsForCase(
        patientId: patientId,
        caseId: widget.caseId,
      );

      // Sort in reverse chronological order (latest visit first)
      final sortedVisits = List<ClinicalVisit>.from(fetchedVisits)
        ..sort((a, b) => b.visitNumber.compareTo(a.visitNumber));

      if (mounted) {
        setState(() {
          _clinicalCase = fetchedCase;
          _visits = sortedVisits;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('[PatientCaseDetailScreen] Error loading case details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        title: strings.caseDetailTitle,
        showBackButton: true,
      ),
      body: _isLoading
          ? const PatientLoadingState()
          : _hasError
              ? _buildErrorView(strings)
              : _clinicalCase == null
                  ? PatientEmptyState(
                      icon: Icons.folder_off_rounded,
                      title: strings.noData,
                      message: 'Case #${widget.caseId} could not be found.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCaseDetails,
                      color: PatientColors.teal,
                      backgroundColor: PatientColors.surface,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 24.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCaseHeaderCard(strings),
                                const SizedBox(height: 28),
                                _buildVisitTimelineSection(strings),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildCaseHeaderCard(dynamic strings) {
    final cCase = _clinicalCase!;
    final isClosed = cCase.isClosed;

    return Container(
      padding: const EdgeInsets.all(22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Domain Tag + Case Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: PatientColors.tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cCase.displayDepartment,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PatientColors.tealDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isClosed
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isClosed ? strings.caseStatusClosed : strings.caseStatusOngoing,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isClosed
                        ? const Color(0xFF2E7D32)
                        : PatientColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Case Title
          Text(
            cCase.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: PatientColors.navy,
            ),
          ),
          const SizedBox(height: 6),

          // Case ID Display
          Text(
            'Case #${cCase.caseId}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PatientColors.textMuted,
            ),
          ),

          // Relevant Medical History / Description if available
          if (cCase.relevantHistory != null &&
              cCase.relevantHistory!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PatientColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PatientColors.borderSubtle),
              ),
              child: Text(
                cCase.relevantHistory!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: PatientColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const Divider(color: PatientColors.borderSubtle, height: 28),

          // Metadata Grid: Started On, Last Visit / Updated, Visits Count
          Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  label: strings.caseStartedDate,
                  value: _formatDate(cCase.createdAt),
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaItem(
                  label: isClosed ? strings.caseCompletedDate : strings.caseLastVisit,
                  value: _formatDate(cCase.updatedAt),
                  icon: Icons.update_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetaItem(
            label: strings.caseVisitsCount,
            value: strings.formatVisits(_visits.length > cCase.visitCount ? _visits.length : cCase.visitCount),
            icon: Icons.people_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: PatientColors.teal),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PatientColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PatientColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitTimelineSection(dynamic strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.visitHistoryTitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PatientColors.navy,
              ),
            ),
            if (_visits.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: PatientColors.tealLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_visits.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PatientColors.tealDark,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (_visits.isEmpty)
          PatientEmptyState(
            icon: Icons.event_note_outlined,
            title: strings.noVisitsYet,
            message: strings.noVisitsYetDesc,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final visit = _visits[index];
              return PatientVisitCard(
                visit: visit,
                department: _clinicalCase?.displayDepartment,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/patient/cases/${_clinicalCase!.caseId}/visits/${visit.visitId}',
                    arguments: {
                      'caseId': _clinicalCase!.caseId,
                      'visitId': visit.visitId,
                      'visit': visit,
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildErrorView(dynamic strings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientColors.border, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: PatientColors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                strings.unableToLoadCaseDetails,
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
                  onPressed: _loadCaseDetails,
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
        ),
      ),
    );
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year;
    return '$day $month $year';
  }
}
