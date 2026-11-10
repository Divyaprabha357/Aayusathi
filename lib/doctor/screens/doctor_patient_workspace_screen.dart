import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/routes/app_routes.dart';
import '../../models/appointment_request.dart';
import '../../models/audit_log.dart';
import '../../models/patient.dart';
import '../../models/vital_reading.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/clinical_case.dart';
import '../models/clinical_visit.dart';
import '../models/documentation_input.dart';
import '../models/investigation_request.dart';
import '../models/patient_transfer_request.dart';
import '../models/prescription_item.dart';
import '../models/report_document.dart';
import '../models/visit_report_data.dart';
import '../services/doctor_patient_workspace_service.dart';
import '../services/doctor_presence_service.dart';
import '../services/doctor_session_service.dart';
import '../services/gemini_documentation_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/visit_report_pdf_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_active_visit_exists_dialog.dart';
import '../widgets/doctor_case_closed_dialog.dart';
import '../widgets/doctor_case_escalation_dialog.dart';
import '../widgets/doctor_close_case_dialog.dart';
import '../widgets/doctor_complete_visit_dialog.dart';
import '../widgets/doctor_consultation_widgets.dart';
import '../widgets/doctor_gemini_widgets.dart';
import '../widgets/doctor_patient_workspace_widgets.dart';
import '../widgets/doctor_pdf_success_dialog.dart';
import '../widgets/doctor_prescription_widgets.dart';
import '../widgets/doctor_reports_review_widget.dart';
import '../widgets/doctor_request_investigation_dialog.dart';
import '../widgets/doctor_speech_widgets.dart';
import '../widgets/doctor_start_new_visit_dialog.dart';
import '../widgets/doctor_state_views.dart';
import '../widgets/doctor_transcript_cleanup_dialog.dart';
import '../widgets/doctor_transfer_context_banner.dart';
import '../widgets/doctor_transfer_patient_dialog.dart';
import '../widgets/doctor_report_viewer_dialog.dart';
import '../widgets/doctor_visit_completed_dialog.dart';
import '../widgets/doctor_visit_report_preview_dialog.dart';

/// Full-screen clinical workstation screen for an authorized Doctor
/// consulting an assigned OPD patient with structured clinical documentation
/// and speech-to-text consultation transcription assistant.
class DoctorPatientWorkspaceScreen extends StatefulWidget {
  final Map<String, dynamic>? initialArguments;

  const DoctorPatientWorkspaceScreen({
    super.key,
    this.initialArguments,
  });

  @override
  State<DoctorPatientWorkspaceScreen> createState() =>
      _DoctorPatientWorkspaceScreenState();
}

class _DoctorPatientWorkspaceScreenState
    extends State<DoctorPatientWorkspaceScreen> {
  final KioskLocale _locale = KioskLocale.english;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUnauthorized = false;

  Patient? _patient;
  AppointmentRequest? _appointment;
  VitalReading? _vitals;
  List<ClinicalCase> _cases = [];
  List<ClinicalVisit> _visits = [];
  ClinicalCase? _selectedCase;
  ClinicalVisit? _activeVisit;

  // Controllers for Structured Consultation
  late final TextEditingController _relevantHistoryController;
  late final TextEditingController _chiefComplaintController;
  late final TextEditingController _onsetDurationController;
  late final TextEditingController _associatedSymptomsController;
  late final TextEditingController _medicalHistoryController;
  late final TextEditingController _currentMedicationController;
  late final TextEditingController _clinicalObservationsController;
  late final TextEditingController _assessmentController;
  late final TextEditingController _planController;
  late final TextEditingController _summaryController;
  late final TextEditingController _followUpController;
  late final TextEditingController _patientInstructionsController;

  SummaryApprovalStatus _summaryApprovalStatus = SummaryApprovalStatus.draft;
  String? _approvedDoctorId;
  DateTime? _approvedAt;
  List<InvestigationRequest> _investigationRequests = [];
  List<ReportDocument> _reportDocuments = [];

  // Prescription State (Phase D9.1)
  List<PrescriptionRowControllers> _prescriptionRows = [];
  String? _prescriptionTranscript;

  // Gemini AI Documentation Assistant State (Phase D10)
  bool _isGeneratingDocumentation = false;
  String? _documentationErrorMessage;
  bool _hasGeneratedAiDraft = false;

  String _requestId = '';
  String _queueNumber = '';
  String _domain = '';
  bool _isPreviousDoctorRequested = false;

  // Inter-Department Transfer State (Phase D13)
  String? _sourceDepartment;
  String? _sourceDoctorName;
  String? _transferReason;

  // Speech-to-Text State
  String? _activeListeningField;
  SpeechRecognitionState _speechState = SpeechRecognitionState.idle;
  Duration _recordingDuration = Duration.zero;
  String _partialTranscript = '';
  String? _speechErrorMessage;
  StreamSubscription<SpeechRecognitionState>? _speechStateSubscription;
  StreamSubscription<Duration>? _speechDurationSubscription;
  StreamSubscription<String>? _speechPartialSubscription;

  String? _directCaseId;
  String? _directPatientId;
  bool _isStartingNewVisit = false;

  @override
  void initState() {
    super.initState();
    _relevantHistoryController = TextEditingController();
    _chiefComplaintController = TextEditingController();
    _onsetDurationController = TextEditingController();
    _associatedSymptomsController = TextEditingController();
    _medicalHistoryController = TextEditingController();
    _currentMedicationController = TextEditingController();
    _clinicalObservationsController = TextEditingController();
    _assessmentController = TextEditingController();
    _planController = TextEditingController();
    _summaryController = TextEditingController();
    _followUpController = TextEditingController();
    _patientInstructionsController = TextEditingController();

    _setupSpeechSubscriptions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractArgsAndLoadData();
    });
  }

  void _setupSpeechSubscriptions() {
    final speechService = SpeechToTextService.instance;
    _speechStateSubscription = speechService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _speechState = state;
          if (state == SpeechRecognitionState.error) {
            _speechErrorMessage =
                speechService.lastError ?? 'Speech recognition encountered an issue.';
            _activeListeningField = null;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.mic_off_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _speechErrorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: DoctorColors.statusCritical,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state == SpeechRecognitionState.idle) {
            _activeListeningField = null;
          }
        });
      }
    });

    _speechDurationSubscription = speechService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _recordingDuration = duration;
        });
      }
    });

    _speechPartialSubscription =
        speechService.partialResultStream.listen((partial) {
      if (mounted) {
        setState(() {
          _partialTranscript = partial;
        });
      }
    });
  }

  @override
  void dispose() {
    _speechStateSubscription?.cancel();
    _speechDurationSubscription?.cancel();
    _speechPartialSubscription?.cancel();

    _relevantHistoryController.dispose();
    _chiefComplaintController.dispose();
    _onsetDurationController.dispose();
    _associatedSymptomsController.dispose();
    _medicalHistoryController.dispose();
    _currentMedicationController.dispose();
    _clinicalObservationsController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _summaryController.dispose();
    _followUpController.dispose();
    _patientInstructionsController.dispose();

    for (final row in _prescriptionRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _extractArgsAndLoadData() {
    final modalRoute = ModalRoute.of(context);
    final routeArgs = widget.initialArguments ??
        (modalRoute?.settings.arguments as Map<String, dynamic>?);

    _requestId = routeArgs?['requestId'] as String? ??
        routeArgs?['appointmentId'] as String? ??
        'REQ-D5-001';
    _queueNumber = routeArgs?['queueNumber'] as String? ?? 'A-00027';
    _domain = routeArgs?['domain'] as String? ?? 'Cardiology';
    _isPreviousDoctorRequested =
        routeArgs?['requestType'] == 'previousDoctor' ||
        routeArgs?['isPreviousDoctor'] == true;

    _directCaseId = routeArgs?['caseId'] as String?;
    _directPatientId = routeArgs?['patientId'] as String?;

    _sourceDepartment = routeArgs?['sourceDepartment'] as String?;
    _sourceDoctorName = routeArgs?['sourceDoctorName'] as String?;
    _transferReason = routeArgs?['transferReason'] as String?;

    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUnauthorized = false;
    });

    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';
    final strings = DoctorLocalizations.forLocale(_locale);

    // Direct Case Access Authorization Check
    if (_directCaseId != null && _directPatientId != null) {
      final isAuthorized = await BackendProvider.instance.caseRepository
          .isDoctorAuthorizedForCase(
        doctorId: doctorId,
        caseId: _directCaseId!,
        patientId: _directPatientId!,
      );
      if (!isAuthorized) {
        if (mounted) {
          setState(() {
            _isUnauthorized = true;
            _errorMessage = strings.unauthorizedAccess;
            _isLoading = false;
          });
        }
        return;
      }
    }

    try {
      final workspaceService = DoctorPatientWorkspaceService.instance;
      final data = await workspaceService.loadWorkspaceData(
        requestId: _requestId,
        doctorId: doctorId,
      );

      if (data.isUnauthorized) {
        if (mounted) {
          setState(() {
            _isUnauthorized = true;
            _errorMessage = data.message;
            _isLoading = false;
          });
        }
        return;
      }

      var patient = data.patient;
      if (_directPatientId != null && (patient == null || patient.patientId != _directPatientId)) {
        patient = await BackendProvider.instance.patientRepository
            .getPatientById(_directPatientId!) ?? patient;
      }

      if (data.isNotFound || data.isError || patient == null) {
        if (mounted) {
          setState(() {
            _errorMessage = data.message ?? strings.unableToLoadClinicalRecords;
            _isLoading = false;
          });
        }
        return;
      }

      final appointment = data.appointment;
      if (appointment != null && appointment.domainId.trim().isNotEmpty) {
        _domain = ClinicalCase.normalizeDepartment(appointment.domainId);
      }
      final vitals = data.vitals;
      var cases = data.cases;
      if (_directPatientId != null) {
        cases = await BackendProvider.instance.caseRepository
            .getCasesForPatient(patient.patientId);
      }

      final visits = <ClinicalVisit>[];
      for (final c in cases) {
        final caseVisits = await BackendProvider.instance.clinicalVisitRepository
            .getVisitsForCase(
          patientId: patient.patientId,
          caseId: c.caseId,
        );
        visits.addAll(caseVisits);
      }

      ClinicalCase? defaultCase;
      if (_directCaseId != null && cases.any((c) => c.caseId == _directCaseId)) {
        defaultCase = cases.firstWhere((c) => c.caseId == _directCaseId);
      } else if (cases.isNotEmpty) {
        defaultCase = cases.firstWhere((c) => c.isOpen, orElse: () => cases.first);
      }

      if (defaultCase != null &&
          defaultCase.domain.trim().isNotEmpty &&
          defaultCase.domain != 'Department not available') {
        _domain = defaultCase.domain;
      }

      ClinicalVisit? activeVisit;
      final chosenCase = defaultCase;
      if (chosenCase != null) {
        final caseVisits = visits.where((v) => v.caseId == chosenCase.caseId).toList();
        try {
          activeVisit = caseVisits.firstWhere((v) => v.status == ClinicalVisitStatus.active);
        } catch (_) {
          activeVisit = null;
        }
      }

      List<ReportDocument> repDocs = [];
      try {
        if (defaultCase != null && activeVisit != null) {
          repDocs = await BackendProvider.instance.reportRepository.getReportsForVisit(
            patientId: patient.patientId,
            caseId: defaultCase.caseId,
            visitId: activeVisit.visitId,
          );
          final invs = await BackendProvider.instance.investigationRepository.getInvestigationRequests(
            patientId: patient.patientId,
            caseId: defaultCase.caseId,
            visitId: activeVisit.visitId,
          );
          if (invs.isNotEmpty) {
            activeVisit = activeVisit.copyWith(investigationRequests: invs);
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _patient = patient;
          _appointment = appointment;
          _vitals = vitals ??
              activeVisit?.vitals ??
              (visits.isNotEmpty
                  ? visits
                      .firstWhere(
                        (v) => v.vitals != null,
                        orElse: () => visits.first,
                      )
                      .vitals
                  : null);
          _cases = cases;
          _visits = visits;
          _reportDocuments = repDocs;
          _selectedCase = defaultCase;
          _activeVisit = activeVisit;
          _isLoading = false;
        });

        _populateControllersFromActiveVisit(activeVisit, defaultCase);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _populateControllersFromActiveVisit(
    ClinicalVisit? visit,
    ClinicalCase? clinicalCase,
  ) {
    if (clinicalCase != null) {
      _relevantHistoryController.text = clinicalCase.relevantHistory ?? '';
    }

    for (final row in _prescriptionRows) {
      row.dispose();
    }
    _prescriptionRows.clear();
    _prescriptionTranscript = null;
    _isGeneratingDocumentation = false;
    _documentationErrorMessage = null;
    _hasGeneratedAiDraft = false;

    if (visit != null) {
      _chiefComplaintController.text = visit.chiefComplaint ?? '';
      _onsetDurationController.text = visit.onsetDuration ?? '';
      _associatedSymptomsController.text = visit.associatedSymptoms ?? '';
      _medicalHistoryController.text = visit.medicalHistory ?? '';
      _currentMedicationController.text = visit.currentMedication ?? '';
      _clinicalObservationsController.text = visit.clinicalObservations ?? '';
      _assessmentController.text = visit.assessment ?? '';
      _planController.text = visit.plan ?? '';
      _summaryController.text = visit.summaryText ?? visit.summary ?? '';
      _summaryApprovalStatus = visit.summaryApprovalStatus;
      _approvedDoctorId = visit.approvedByDoctorId;
      _approvedAt = visit.approvedAt;
      _followUpController.text = visit.followUp ?? '';
      _patientInstructionsController.text = visit.patientInstructions ?? '';
      _investigationRequests = List.from(visit.investigationRequests);
      _hasGeneratedAiDraft = _summaryController.text.trim().isNotEmpty;

      if (visit.prescriptions.isNotEmpty) {
        _prescriptionRows = visit.prescriptions
            .map((p) => PrescriptionRowControllers.fromItem(p))
            .toList();
      }
    } else {
      _chiefComplaintController.clear();
      _onsetDurationController.clear();
      _associatedSymptomsController.clear();
      _medicalHistoryController.clear();
      _currentMedicationController.clear();
      _clinicalObservationsController.clear();
      _assessmentController.clear();
      _planController.clear();
      _summaryController.clear();
      _summaryApprovalStatus = SummaryApprovalStatus.draft;
      _approvedDoctorId = null;
      _approvedAt = null;
      _followUpController.clear();
      _patientInstructionsController.clear();
      _investigationRequests.clear();
      _hasGeneratedAiDraft = false;
    }
  }

  // Speech-to-Text Interaction Handlers
  TextEditingController? _getControllerForField(String fieldId) {
    switch (fieldId) {
      case 'chiefComplaint':
        return _chiefComplaintController;
      case 'onsetDuration':
        return _onsetDurationController;
      case 'associatedSymptoms':
        return _associatedSymptomsController;
      case 'medicalHistory':
        return _medicalHistoryController;
      case 'currentMedication':
        return _currentMedicationController;
      case 'clinicalObservations':
        return _clinicalObservationsController;
      case 'assessment':
        return _assessmentController;
      case 'plan':
        return _planController;
      case 'relevantHistory':
        return _relevantHistoryController;
      case 'summaryText':
        return _summaryController;
      case 'followUp':
        return _followUpController;
      case 'patientInstructions':
        return _patientInstructionsController;
      default:
        return null;
    }
  }

  String _getFieldLabel(String fieldId) {
    final strings = DoctorLocalizations.forLocale(_locale);
    switch (fieldId) {
      case 'chiefComplaint':
        return strings.chiefComplaint;
      case 'onsetDuration':
        return strings.onsetDuration;
      case 'associatedSymptoms':
        return strings.associatedSymptoms;
      case 'medicalHistory':
        return strings.medicalHistory;
      case 'currentMedication':
        return strings.currentMedication;
      case 'clinicalObservations':
        return strings.clinicalObservations;
      case 'assessment':
        return strings.assessment;
      case 'plan':
        return strings.plan;
      case 'relevantHistory':
        return strings.previousRelevantHistoryLabel;
      case 'summaryText':
        return strings.summaryLabel;
      case 'followUp':
        return strings.followUpLabel;
      case 'patientInstructions':
        return strings.patientInstructionsLabel;
      case 'prescription':
        return strings.prescription;
      default:
        return fieldId;
    }
  }

  void _onFieldUpdated(String fieldId) {
    if (fieldId == 'summaryText') {
      _onSummaryChanged(_summaryController.text);
    } else {
      setState(() {});
    }
  }

  Future<void> _handleSpeechTrigger(String fieldId) async {
    final speechService = SpeechToTextService.instance;

    // Prevent duplicate dictate requests while processing or initializing
    if (speechService.isProcessing ||
        _speechState == SpeechRecognitionState.processing ||
        _speechState == SpeechRecognitionState.initializing) {
      debugPrint('[DoctorWorkspace] Speech service is busy ($_speechState). Ignoring trigger on $fieldId');
      return;
    }

    // If already listening on this field -> stop and insert
    if (_activeListeningField == fieldId && speechService.isListening) {
      await _handleStopSpeech();
      return;
    }

    // If another field is active, stop it first or ignore
    if (speechService.isListening) {
      return;
    }

    // Check microphone hardware & permission
    final perm = await speechService.requestPermission();
    if (perm == MicrophonePermissionStatus.denied ||
        perm == MicrophonePermissionStatus.permanentlyDenied) {
      final strings = DoctorLocalizations.forLocale(_locale);
      setState(() {
        _speechErrorMessage = strings.micPermissionDenied;
      });
      return;
    }

    setState(() {
      _activeListeningField = fieldId;
      _partialTranscript = '';
      _speechErrorMessage = null;
      _recordingDuration = Duration.zero;
    });

    try {
      await speechService.startListening(
        fieldId: fieldId,
        locale: _locale,
        onPartialResult: (text) {
          if (mounted) {
            setState(() {
              _partialTranscript = text;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _speechErrorMessage = e.toString();
          _activeListeningField = null;
        });
      }
    }
  }

  Future<void> _handleStopSpeech() async {
    final fieldId = _activeListeningField;
    if (fieldId == null) return;

    final speechService = SpeechToTextService.instance;
    if (speechService.isProcessing) {
      debugPrint('[DoctorWorkspace] Stop already in progress for $fieldId.');
      return;
    }

    final transcript = await speechService.stopListening();

    if (mounted) {
      setState(() {
        _activeListeningField = null;
        _partialTranscript = '';
      });
    }

    if (transcript == null || transcript.trim().isEmpty) {
      return;
    }

    if (fieldId == 'prescription') {
      if (mounted) {
        setState(() {
          _prescriptionTranscript = transcript.trim();
        });
      }
      return;
    }

    final targetController = _getControllerForField(fieldId);
    if (targetController == null) return;

    final fieldLabel = _getFieldLabel(fieldId);
    if (!mounted) return;

    // Log AI cleanup request audit
    _logTranscriptCleanupAudit(
      action: 'AI_TRANSCRIPT_CLEANUP_REQUESTED',
      fieldId: fieldId,
      rawTranscriptLength: transcript.trim().length,
    );

    // Open Doctor Voice Transcript Review Modal (Phase D9.2)
    final reviewResult = await showDialog<DoctorTranscriptReviewResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DoctorVoiceTranscriptReviewDialog(
        fieldId: fieldId,
        fieldLabel: fieldLabel,
        originalTranscript: transcript.trim(),
        locale: _locale,
      ),
    );

    if (reviewResult == null) {
      // Doctor cancelled transcription review
      return;
    }

    final acceptedText = reviewResult.acceptedText.trim();
    if (acceptedText.isEmpty) return;

    // Log AI cleanup acceptance audit
    _logTranscriptCleanupAudit(
      action: 'AI_TRANSCRIPT_CLEANUP_ACCEPTED',
      fieldId: fieldId,
      rawTranscriptLength: reviewResult.originalTranscript.length,
      cleanedTranscriptLength: reviewResult.cleanedDraft.length,
      acceptedLength: acceptedText.length,
      choice: reviewResult.choiceType.name.toUpperCase(),
    );

    final existingText = targetController.text.trim();
    if (existingText.isEmpty) {
      targetController.text = acceptedText;
      _onFieldUpdated(fieldId);
      _logTranscriptionAudit(fieldId, acceptedText, 'DIRECT_INSERT');
    } else {
      // Show Append or Replace Dialog with doctor-accepted text
      if (!mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => DoctorSpeechAppendReplaceDialog(
          fieldLabel: fieldLabel,
          existingText: existingText,
          newTranscript: acceptedText,
          locale: _locale,
        ),
      );

      if (action == 'replace') {
        targetController.text = acceptedText;
        _onFieldUpdated(fieldId);
        _logTranscriptionAudit(fieldId, acceptedText, 'REPLACE');
      } else if (action == 'append') {
        targetController.text = '$existingText\n$acceptedText';
        _onFieldUpdated(fieldId);
        _logTranscriptionAudit(fieldId, acceptedText, 'APPEND');
      }
    }
  }

  // Prescription Workflow Methods (Phase D9.1)
  void _onAddPrescriptionMedicine() {
    setState(() {
      _prescriptionRows.add(PrescriptionRowControllers());
    });
  }

  void _onRemovePrescriptionMedicine(int index) {
    if (index >= 0 && index < _prescriptionRows.length) {
      setState(() {
        final removed = _prescriptionRows.removeAt(index);
        removed.dispose();
      });
    }
  }

  void _onCreatePrescriptionWithCount(int count) {
    for (final r in _prescriptionRows) {
      r.dispose();
    }
    setState(() {
      _prescriptionRows = List.generate(
        count,
        (_) => PrescriptionRowControllers(),
      );
    });
  }

  void _onPrescriptionDictate() {
    _handleSpeechTrigger('prescription');
  }

  void _onDiscardPrescriptionTranscript() {
    setState(() {
      _prescriptionTranscript = null;
    });
  }

  List<PrescriptionItem> _parsePrescriptionTranscript(String text) {
    if (text.trim().isEmpty) return [];
    final chunks = text
        .split(RegExp(r'[.\n;।]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final items = <PrescriptionItem>[];
    for (final chunk in chunks) {
      String medicineName = chunk;
      String duration = '';
      String timesPerDay = '';
      String remarks = '';

      final durMatch = RegExp(
        r'(?:for\s+)?(\d+\s*(?:days?|weeks?|months?|दिन|दिवस|आठवडे|महिने))',
        caseSensitive: false,
      ).firstMatch(chunk);
      if (durMatch != null) {
        duration = durMatch.group(1) ?? '';
      }

      final freqMatch = RegExp(
        r'(\d+\s*(?:times?\s*(?:a\s*day)?|वेळा|बार)|once\s*a\s*day|twice\s*a\s*day|thrice\s*a\s*day|दिन\s*में\s*\d+\s*बार|दिवसातून\s*\d+\s*वेळा)',
        caseSensitive: false,
      ).firstMatch(chunk);
      if (freqMatch != null) {
        timesPerDay = freqMatch.group(1) ?? '';
      }

      final remMatch = RegExp(
        r'(after\s*(?:food|meals|breakfast|dinner)|before\s*(?:food|meals|breakfast|dinner)|at\s*bedtime|भोजन\s*के\s*बाद|नाश्ते\s*से\s*पहले|जेवणानंतर|नाश्त्यापूर्वी)',
        caseSensitive: false,
      ).firstMatch(chunk);
      if (remMatch != null) {
        remarks = remMatch.group(1) ?? '';
      }

      if (durMatch != null || freqMatch != null || remMatch != null) {
        var cleaned = chunk;
        if (durMatch != null) {
          cleaned = cleaned.replaceAll(durMatch.group(0)!, '');
        }
        if (freqMatch != null) {
          cleaned = cleaned.replaceAll(freqMatch.group(0)!, '');
        }
        if (remMatch != null) {
          cleaned = cleaned.replaceAll(remMatch.group(0)!, '');
        }
        cleaned = cleaned
            .replaceAll(RegExp(r'[,]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'^\s*for\s+', caseSensitive: false), '')
            .trim();
        if (cleaned.isNotEmpty) {
          medicineName = cleaned;
        }
      }

      items.add(
        PrescriptionItem(
          medicineName: medicineName,
          duration: duration,
          timesPerDay: timesPerDay,
          remarks: remarks,
        ),
      );
    }
    return items;
  }

  Future<void> _onUsePrescriptionTranscript() async {
    if (_prescriptionTranscript == null || _prescriptionTranscript!.trim().isEmpty) return;

    final parsedItems = _parsePrescriptionTranscript(_prescriptionTranscript!);
    if (parsedItems.isEmpty) return;

    if (_prescriptionRows.isNotEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => DoctorPrescriptionAppendReplaceDialog(
          existingCount: _prescriptionRows.length,
          locale: _locale,
        ),
      );

      if (action == 'replace') {
        for (final r in _prescriptionRows) {
          r.dispose();
        }
        setState(() {
          _prescriptionRows = parsedItems
              .map((item) => PrescriptionRowControllers.fromItem(item))
              .toList();
          _prescriptionTranscript = null;
        });
        _logTranscriptionAudit(
          'prescription',
          parsedItems.map((i) => i.medicineName).join(', '),
          'REPLACE',
        );
      } else if (action == 'append') {
        setState(() {
          _prescriptionRows.addAll(
            parsedItems.map((item) => PrescriptionRowControllers.fromItem(item)),
          );
          _prescriptionTranscript = null;
        });
        _logTranscriptionAudit(
          'prescription',
          parsedItems.map((i) => i.medicineName).join(', '),
          'APPEND',
        );
      }
    } else {
      setState(() {
        _prescriptionRows = parsedItems
            .map((item) => PrescriptionRowControllers.fromItem(item))
            .toList();
        _prescriptionTranscript = null;
      });
      _logTranscriptionAudit(
        'prescription',
        parsedItems.map((i) => i.medicineName).join(', '),
        'DIRECT_INSERT',
      );
    }
  }

  Future<void> _handleCancelSpeech() async {
    final speechService = SpeechToTextService.instance;
    await speechService.cancelListening();
    if (mounted) {
      setState(() {
        _activeListeningField = null;
        _partialTranscript = '';
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _logTranscriptCleanupAudit({
    required String action,
    required String fieldId,
    int? rawTranscriptLength,
    int? cleanedTranscriptLength,
    int? acceptedLength,
    String? choice,
    String? errorCode,
  }) async {
    try {
      final session = DoctorSessionService.instance;
      final doctorId = session.activeDoctorId ?? 'DOC-101';
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: action,
          entityType: 'CLINICAL_VISIT',
          entityId: _activeVisit?.visitId ?? 'UNKNOWN',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': _patient?.patientId,
            'caseId': _selectedCase?.caseId,
            'fieldId': fieldId,
            'rawTranscriptLength': ?rawTranscriptLength,
            'cleanedTranscriptLength': ?cleanedTranscriptLength,
            'acceptedLength': ?acceptedLength,
            'choice': ?choice,
            'errorCode': ?errorCode,
          },
        ),
      );
    } catch (_) {}
  }

  Future<void> _logTranscriptionAudit(
    String fieldId,
    String transcript,
    String mode,
  ) async {
    try {
      final session = DoctorSessionService.instance;
      final doctorId = session.activeDoctorId ?? 'DOC-101';
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'CONSULTATION_TRANSCRIPTION_USED',
          entityType: 'CLINICAL_VISIT',
          entityId: _activeVisit?.visitId ?? 'UNKNOWN',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': _patient?.patientId,
            'caseId': _selectedCase?.caseId,
            'fieldId': fieldId,
            'insertionMode': mode,
            'transcriptLength': transcript.length,
          },
        ),
      );
    } catch (_) {}
  }

  void _onSelectCase(ClinicalCase c) {
    if (_selectedCase?.caseId == c.caseId) return;

    final caseVisits = _visits.where((v) => v.caseId == c.caseId).toList();
    ClinicalVisit? activeVisit;
    try {
      activeVisit = caseVisits.firstWhere((v) => v.status == ClinicalVisitStatus.active);
    } catch (_) {
      activeVisit = null;
    }

    setState(() {
      _selectedCase = c;
      _activeVisit = activeVisit;
    });

    _populateControllersFromActiveVisit(activeVisit, c);
  }

  void _onSelectVisit(ClinicalVisit visit) {
    setState(() {
      _activeVisit = visit;
      if (visit.vitals != null) {
        _vitals = visit.vitals;
      }
    });
    _populateControllersFromActiveVisit(visit, _selectedCase);
  }

  void _onStartNewCase() {
    final rawDomain = (_selectedCase?.domain.trim().isNotEmpty == true &&
            _selectedCase!.domain != 'Department not available')
        ? _selectedCase!.domain
        : (_domain.trim().isNotEmpty ? _domain : (_appointment?.domainId ?? 'General Medicine'));
    final domain = ClinicalCase.normalizeDepartment(rawDomain);
    showDialog(
      context: context,
      builder: (ctx) => DoctorNewCaseDialog(
        defaultDomain: domain,
        onConfirm: (selectedDomain, title) async {
          final normalizedDomain = ClinicalCase.normalizeDepartment(selectedDomain);
          final newCase = ClinicalCase(
            caseId: 'CASE-${DateTime.now().millisecondsSinceEpoch}',
            patientId: _patient?.patientId ?? 'PAT-001',
            title: title,
            domain: normalizedDomain,
            status: ClinicalCaseStatus.open,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          try {
            await BackendProvider.instance.caseRepository.createCase(newCase);
            if (mounted) {
              setState(() {
                _cases.insert(0, newCase);
                _selectedCase = newCase;
                _activeVisit = null;
              });
              _populateControllersFromActiveVisit(null, newCase);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to start new case: $e'),
                  backgroundColor: DoctorColors.statusBusy,
                ),
              );
            }
          }
        },
        locale: _locale,
      ),
    );
  }

  Future<void> _onAddVisit() async {
    if (_selectedCase == null || _patient == null) return;

    if (_selectedCase!.isClosed) {
      final strings = DoctorLocalizations.forLocale(_locale);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.cannotAddVisitToClosedCase),
          backgroundColor: DoctorColors.statusOffline,
        ),
      );
      return;
    }

    // 1. Check for existing active consultation visit (Duplicate Visit Protection)
    final activeVisit = await BackendProvider.instance.clinicalVisitRepository
        .getActiveVisitForCase(
      patientId: _patient!.patientId,
      caseId: _selectedCase!.caseId,
    );

    if (activeVisit != null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => DoctorActiveVisitExistsDialog(
          activeVisit: activeVisit,
          domain: _selectedCase!.domain,
          locale: _locale,
          onReturnToActiveVisit: () {
            _onSelectVisit(activeVisit);
          },
        ),
      );
      return;
    }

    // 2. Show New Visit Confirmation Dialog
    final caseVisitsCount =
        _visits.where((v) => v.caseId == _selectedCase!.caseId).length;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => DoctorStartNewVisitDialog(
        clinicalCase: _selectedCase!,
        patientName: _patient?.name,
        previousVisitsCount: caseVisitsCount,
        locale: _locale,
        onConfirmStart: _executeStartNewVisit,
      ),
    );
  }

  Future<void> _executeStartNewVisit() async {
    if (_selectedCase == null || _patient == null) return;
    if (_isStartingNewVisit) return;
    _isStartingNewVisit = true;

    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';
    final doctorName = session.activeDoctorName ?? 'Dr. Rajesh Sharma';
    final doctorQualification =
        session.activeProfile?.qualification ?? 'MBBS, MD (Cardiology)';

    try {
      // 1. Atomically create next visit in repository
      final created = await BackendProvider.instance.clinicalVisitRepository
          .createNextVisit(
        patientId: _patient!.patientId,
        caseId: _selectedCase!.caseId,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorQualification: doctorQualification,
        appointmentId: _requestId,
        vitals: _vitals,
        department: _selectedCase?.domain ?? _domain,
      );

      // 2. Transition Doctor Presence: AVAILABLE -> IN_CONSULTATION
      await DoctorPresenceService.instance.setInConsultation();

      // 3. Audit logs
      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'CASE_CONTINUED',
            entityType: 'CLINICAL_CASE',
            entityId: _selectedCase!.caseId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient!.patientId,
              'caseId': _selectedCase!.caseId,
              'newVisitNumber': created.visitNumber,
            },
          ),
        );

        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'VISIT_CREATED',
            entityType: 'CLINICAL_VISIT',
            entityId: created.visitId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient!.patientId,
              'caseId': _selectedCase!.caseId,
              'visitId': created.visitId,
              'visitNumber': created.visitNumber,
            },
          ),
        );
      } catch (_) {}

      // 4. Update case record with incremented visit count (case strictly remains open)
      final updatedCase = _selectedCase!.copyWith(
        visitCount: created.visitNumber,
        updatedAt: DateTime.now(),
        status: ClinicalCaseStatus.open,
      );
      await BackendProvider.instance.caseRepository.updateCase(updatedCase);

      if (mounted) {
        setState(() {
          _visits.add(created);
          _activeVisit = created;
          final caseIdx =
              _cases.indexWhere((c) => c.caseId == updatedCase.caseId);
          if (caseIdx != -1) {
            _cases[caseIdx] = updatedCase;
          }
          _selectedCase = updatedCase;
        });
        _populateControllersFromActiveVisit(created, updatedCase);

        final strings = DoctorLocalizations.forLocale(_locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.newVisitCreatedNotice),
            backgroundColor: DoctorColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add visit: $e'),
            backgroundColor: DoctorColors.statusBusy,
          ),
        );
      }
    } finally {
      _isStartingNewVisit = false;
    }
  }

  // Phase D15: Explicit Case Closure Handler
  Future<void> _onCloseCaseRequested() async {
    final strings = DoctorLocalizations.forLocale(_locale);
    if (_selectedCase == null || _patient == null) return;

    if (_selectedCase!.isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.closedCaseReadOnlyNotice),
          backgroundColor: DoctorColors.statusOffline,
        ),
      );
      return;
    }

    // 1. Active Visit Protection: A Case with an ACTIVE Visit must NOT be closed
    final hasActiveVisit = _visits.any(
      (v) => v.caseId == _selectedCase!.caseId && v.isActive,
    );
    if (hasActiveVisit) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DoctorTheme.radius16),
            side: const BorderSide(color: DoctorColors.dialogBorder, width: 1.0),
          ),
          backgroundColor: DoctorColors.dialogBg,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DoctorColors.dialogWarningBg,
                  borderRadius: BorderRadius.circular(DoctorTheme.radius8),
                  border: Border.all(color: DoctorColors.dialogWarningBorder),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: DoctorColors.dialogWarningText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.activeVisitExistsTitle,
                  style: DoctorTheme.headline2.copyWith(
                    color: DoctorColors.dialogPrimaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            strings.activeVisitBlocksClosureError,
            style: DoctorTheme.bodyRegular.copyWith(
              color: DoctorColors.dialogSecondaryText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DoctorColors.dialogPrimaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DoctorTheme.radius8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                strings.close,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Open Close Case Confirmation Dialog (Declaration Checkbox + Closure Note)
    final closureNote = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DoctorCloseCaseDialog(
        clinicalCase: _selectedCase!,
        locale: _locale,
      ),
    );

    if (closureNote == null || closureNote.trim().isEmpty) {
      return;
    }

    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';
    final doctorName = session.activeProfile?.name ?? session.activeDoctorName ?? 'Dr. Ramesh Sharma';

    try {
      // 3. Log Audit: CASE_CLOSURE_DECLARATION_CONFIRMED
      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'CASE_CLOSURE_DECLARATION_CONFIRMED',
            entityType: 'CLINICAL_CASE',
            entityId: _selectedCase!.caseId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient!.patientId,
              'caseId': _selectedCase!.caseId,
              'closureNoteLength': closureNote.trim().length,
            },
          ),
        );
      } catch (_) {}

      // 4. Atomically close Case in repository
      final closedCase = await BackendProvider.instance.caseRepository.closeCase(
        patientId: _patient!.patientId,
        caseId: _selectedCase!.caseId,
        doctorId: doctorId,
        doctorName: doctorName,
        closureNote: closureNote.trim(),
      );

      // 5. Log Audit: CASE_CLOSED
      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'CASE_CLOSED',
            entityType: 'CLINICAL_CASE',
            entityId: _selectedCase!.caseId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient!.patientId,
              'caseId': _selectedCase!.caseId,
              'closedAt': closedCase.closedAt?.toIso8601String(),
              'closedByDoctorId': doctorId,
            },
          ),
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          final caseIdx =
              _cases.indexWhere((c) => c.caseId == closedCase.caseId);
          if (caseIdx != -1) {
            _cases[caseIdx] = closedCase;
          }
          _selectedCase = closedCase;
        });

        // 6. Show Case Closed Confirmation Dialog
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => DoctorCaseClosedDialog(
            clinicalCase: closedCase,
            doctorName: doctorName,
            locale: _locale,
          ),
        );

        if (result == 'dashboard' && mounted) {
          Navigator.of(context)
              .pushReplacementNamed(AppRoutes.doctorDashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close case: $e'),
            backgroundColor: DoctorColors.statusBusy,
          ),
        );
      }
    }
  }

  // Phase D10: Gemini Documentation Assistant Handlers
  DocumentationInput _buildDocumentationInput() {
    return DocumentationInput(
      chiefComplaint: _chiefComplaintController.text,
      onsetDuration: _onsetDurationController.text,
      associatedSymptoms: _associatedSymptomsController.text,
      medicalHistory: _medicalHistoryController.text,
      currentMedication: _currentMedicationController.text,
      clinicalObservations: _clinicalObservationsController.text,
      assessment: _assessmentController.text,
      plan: _planController.text,
      previousRelevantHistory: _relevantHistoryController.text,
      followUp: _followUpController.text,
      patientInstructions: _patientInstructionsController.text,
    );
  }

  Future<void> _onGenerateDocumentation() async {
    final input = _buildDocumentationInput();
    if (!input.isComplete) {
      setState(() {
        _documentationErrorMessage =
            'Please complete all 8 required consultation fields before generating draft.';
      });
      return;
    }

    setState(() {
      _isGeneratingDocumentation = true;
      _documentationErrorMessage = null;
    });

    final service = GeminiDocumentationService.instance;
    final result = await service.generateDocumentationSummary(input, locale: _locale);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _summaryController.text = result.summary;
        _summaryApprovalStatus = SummaryApprovalStatus.reviewRequired;
        _approvedDoctorId = null;
        _approvedAt = null;
        _isGeneratingDocumentation = false;
        _hasGeneratedAiDraft = true;
      });

      final session = DoctorSessionService.instance;
      final doctorId = session.activeDoctorId ?? 'DOC-101';

      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'AI_DOCUMENTATION_GENERATED',
            entityType: 'CLINICAL_VISIT',
            entityId: _activeVisit?.visitId ?? 'UNKNOWN',
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient?.patientId,
              'caseId': _selectedCase?.caseId,
              'fieldCount': 8,
            },
          ),
        );
      } catch (_) {}
    } else {
      setState(() {
        _isGeneratingDocumentation = false;
        _documentationErrorMessage = result.errorMessage ??
            DoctorLocalizations.forLocale(_locale).documentationUnavailable;
      });
    }
  }

  Future<void> _onRegenerateDocumentation() async {
    // Show confirmation dialog if doctor has content in summary
    if (_summaryController.text.trim().isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => DoctorRegenerateWarningDialog(locale: _locale),
      );
      if (confirmed != true) return;
    }

    final input = _buildDocumentationInput();
    if (!input.isComplete) {
      setState(() {
        _documentationErrorMessage =
            'Please complete all 8 required consultation fields before generating draft.';
      });
      return;
    }

    setState(() {
      _isGeneratingDocumentation = true;
      _documentationErrorMessage = null;
    });

    final service = GeminiDocumentationService.instance;
    final result = await service.generateDocumentationSummary(input, locale: _locale);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _summaryController.text = result.summary;
        _summaryApprovalStatus = SummaryApprovalStatus.reviewRequired;
        _approvedDoctorId = null;
        _approvedAt = null;
        _isGeneratingDocumentation = false;
        _hasGeneratedAiDraft = true;
      });

      final session = DoctorSessionService.instance;
      final doctorId = session.activeDoctorId ?? 'DOC-101';

      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'AI_DOCUMENTATION_REGENERATED',
            entityType: 'CLINICAL_VISIT',
            entityId: _activeVisit?.visitId ?? 'UNKNOWN',
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient?.patientId,
              'caseId': _selectedCase?.caseId,
              'fieldCount': 8,
            },
          ),
        );
      } catch (_) {}
    } else {
      setState(() {
        _isGeneratingDocumentation = false;
        _documentationErrorMessage = result.errorMessage ??
            DoctorLocalizations.forLocale(_locale).documentationUnavailable;
      });
    }
  }

  void _onDismissDocumentationError() {
    setState(() {
      _documentationErrorMessage = null;
    });
  }

  void _onSummaryChanged(String newSummary) {
    if (_summaryApprovalStatus == SummaryApprovalStatus.approvedByDoctor) {
      setState(() {
        _summaryApprovalStatus = SummaryApprovalStatus.reviewRequired;
        _approvedDoctorId = null;
        _approvedAt = null;
      });
    }

    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';

    try {
      BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'AI_DOCUMENTATION_REVIEWED',
          entityType: 'CLINICAL_VISIT',
          entityId: _activeVisit?.visitId ?? 'UNKNOWN',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': _patient?.patientId,
            'caseId': _selectedCase?.caseId,
          },
        ),
      );
    } catch (_) {}
  }

  void _onApproveSummary() {
    final strings = DoctorLocalizations.forLocale(_locale);
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';

    setState(() {
      _summaryApprovalStatus = SummaryApprovalStatus.approvedByDoctor;
      _approvedDoctorId = doctorId;
      _approvedAt = DateTime.now();
    });

    try {
      BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'SUMMARY_APPROVED',
          entityType: 'CLINICAL_VISIT',
          entityId: _activeVisit?.visitId ?? 'UNKNOWN',
          timestamp: DateTime.now(),
          metadata: {
            'patientId': _patient?.patientId,
            'caseId': _selectedCase?.caseId,
            'approvedDoctorId': doctorId,
          },
        ),
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.summaryApprovedNotice),
        backgroundColor: DoctorColors.statusAvailable,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onAddInvestigation() {
    showDialog(
      context: context,
      builder: (ctx) => DoctorRequestInvestigationDialog(
        locale: _locale,
        onConfirm: (name, category, priority) async {
          final session = DoctorSessionService.instance;
          final doctorId = session.activeDoctorId ?? 'DOC-101';

          final newReq = InvestigationRequest(
            requestId: 'REQ-INV-${DateTime.now().millisecondsSinceEpoch}',
            patientId: _patient?.patientId,
            caseId: _selectedCase?.caseId,
            visitId: _activeVisit?.visitId,
            requestedByDoctorId: doctorId,
            department: _selectedCase?.domain ?? _domain,
            name: name,
            category: category,
            priority: priority,
            status: InvestigationStatus.pendingUpload,
            requestedAt: DateTime.now(),
          );

          if (_patient != null && _selectedCase != null && _activeVisit != null) {
            try {
              await BackendProvider.instance.investigationRepository
                  .createInvestigationRequest(newReq);
            } catch (_) {}
          }

          setState(() {
            _investigationRequests.add(newReq);
          });

          try {
            await BackendProvider.instance.auditRepository.logEvent(
              AuditLog(
                auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
                actorType: 'DOCTOR',
                actorId: doctorId,
                action: 'INVESTIGATION_REQUESTED',
                entityType: 'CLINICAL_VISIT',
                entityId: _activeVisit?.visitId ?? 'UNKNOWN',
                timestamp: DateTime.now(),
                metadata: {
                  'patientId': _patient?.patientId,
                  'caseId': _selectedCase?.caseId,
                  'investigationName': name,
                  'category': category.name,
                  'priority': priority.name,
                },
              ),
            );
          } catch (_) {}
        },
      ),
    );
  }

  Future<void> _onMarkReportReviewed(
    InvestigationRequest inv,
    ReportDocument? rep,
  ) async {
    final strings = DoctorLocalizations.forLocale(_locale);
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';

    try {
      if (_patient != null && _selectedCase != null && _activeVisit != null) {
        await BackendProvider.instance.investigationRepository.markReviewed(
          patientId: _patient!.patientId,
          caseId: _selectedCase!.caseId,
          visitId: _activeVisit!.visitId,
          investigationId: inv.requestId,
          doctorId: doctorId,
        );

        if (rep != null) {
          await BackendProvider.instance.reportRepository.updateReportStatus(
            patientId: _patient!.patientId,
            caseId: _selectedCase!.caseId,
            visitId: _activeVisit!.visitId,
            reportId: rep.reportId,
            status: ReportReviewStatus.reviewed,
            doctorId: doctorId,
          );
        }

        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'REPORT_REVIEWED',
            entityType: 'CLINICAL_VISIT',
            entityId: _activeVisit!.visitId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient!.patientId,
              'caseId': _selectedCase!.caseId,
              'investigationId': inv.requestId,
              'reportId': rep?.reportId,
            },
          ),
        );
      }

      setState(() {
        final invIdx = _investigationRequests
            .indexWhere((r) => r.requestId == inv.requestId);
        if (invIdx != -1) {
          _investigationRequests[invIdx] =
              _investigationRequests[invIdx].copyWith(
            status: InvestigationStatus.reviewed,
            reviewedAt: DateTime.now(),
            reviewedByDoctorId: doctorId,
          );
        }

        if (rep != null) {
          final repIdx =
              _reportDocuments.indexWhere((r) => r.reportId == rep.reportId);
          if (repIdx != -1) {
            _reportDocuments[repIdx] = _reportDocuments[repIdx].copyWith(
              reviewStatus: ReportReviewStatus.reviewed,
              reviewedAt: DateTime.now(),
              reviewedByDoctorId: doctorId,
            );
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.reportReviewedNotice),
            backgroundColor: DoctorColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to review report: $e'),
            backgroundColor: DoctorColors.statusBusy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onPreviewVisitReport() {
    if (_patient == null || _selectedCase == null) return;

    final session = DoctorSessionService.instance;
    final doctorName = session.activeDoctorName ?? 'Dr. Rajesh Sharma';
    final doctorQualification =
        session.activeProfile?.qualification ?? 'MBBS, MD (Cardiology)';

    final currentVisit = _buildCurrentVisitFromState(
      status: _activeVisit?.status ?? ClinicalVisitStatus.active,
    );

    final reportData = VisitReportData.fromComponents(
      patient: _patient!,
      clinicalCase: _selectedCase!,
      visit: currentVisit,
      vitals: _vitals,
      doctorName: doctorName,
      doctorQualification: doctorQualification,
      isExistingPatient: _isPreviousDoctorRequested,
    );

    try {
      BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: session.activeDoctorId ?? 'DOC-101',
          action: 'VISIT_REPORT_PREVIEWED',
          entityType: 'CLINICAL_VISIT',
          entityId: currentVisit.visitId,
          timestamp: DateTime.now(),
          metadata: {
            'patientId': _patient?.patientId,
            'caseId': _selectedCase?.caseId,
            'canGenerate': reportData.canGenerateReport,
          },
        ),
      );
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => DoctorVisitReportPreviewDialog(
        data: reportData,
        onGeneratePdf: () => _onGeneratePdf(reportData),
        locale: _locale,
      ),
    );
  }

  Future<void> _onGeneratePdf(VisitReportData reportData) async {
    if (!reportData.canGenerateReport) {
      showDialog(
        context: context,
        builder: (ctx) => DoctorMissingRequirementsDialog(
          missingRequirements: reportData.missingRequirements,
          locale: _locale,
        ),
      );
      return;
    }

    try {
      final localResult = await VisitReportPdfService.instance
          .generateAndSaveVisitPdf(reportData);

      if (!localResult.isSuccess || localResult.filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localResult.errorMessage ?? 'Failed to generate and save PDF report.',
              ),
              backgroundColor: DoctorColors.statusCritical,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Cloud copy upload to Firebase Storage + Firestore metadata
      final finalResult = await VisitReportPdfService.instance
          .uploadVisitReportPdfToCloud(
        localResult: localResult,
        data: reportData,
      );

      final session = DoctorSessionService.instance;
      final doctorId = session.activeDoctorId ?? 'DOC-101';

      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'VISIT_REPORT_PDF_GENERATED',
            entityType: 'CLINICAL_VISIT',
            entityId: reportData.caseId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': reportData.patientId,
              'caseId': reportData.caseId,
              'visitNumber': reportData.visitNumber,
              'pdfSizeBytes': finalResult.fileSizeBytes,
              'fileName': finalResult.fileName,
              'filePath': finalResult.filePath,
              'cloudStoragePath': finalResult.cloudStoragePath,
              'isCloudUploaded': finalResult.isCloudUploaded,
            },
          ),
        );
      } catch (_) {}

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => DoctorPdfSuccessDialog(
            result: finalResult,
            reportData: reportData,
            locale: _locale,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF report: $e'),
            backgroundColor: DoctorColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onRemoveInvestigation(InvestigationRequest req) {
    setState(() {
      _investigationRequests.removeWhere((r) => r.requestId == req.requestId);
    });
  }

  ClinicalVisit _buildCurrentVisitFromState({
    required ClinicalVisitStatus status,
    DateTime? completedAt,
  }) {
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';
    final doctorName = session.activeDoctorName ?? 'Dr. Rajesh Sharma';
    final doctorQualification =
        session.activeProfile?.qualification ?? 'MBBS, MD (Cardiology)';

    final computedVisitNumber = _activeVisit?.visitNumber ??
        (_visits.isNotEmpty
            ? (_visits.map((v) => v.visitNumber).reduce((a, b) => a > b ? a : b) + 1)
            : 1);

    return ClinicalVisit(
      visitId: _activeVisit?.visitId ??
          'VIS-${_selectedCase?.caseId ?? "CASE"}-$computedVisitNumber-${DateTime.now().millisecondsSinceEpoch}',
      caseId: _selectedCase?.caseId ?? 'CASE-001',
      patientId: _patient?.patientId ?? 'PAT-001',
      doctorId: doctorId,
      doctorName: doctorName,
      doctorQualification: doctorQualification,
      appointmentId: _appointment?.requestId,
      department: (_selectedCase?.domain.trim().isNotEmpty == true &&
              _selectedCase!.domain != 'Department not available')
          ? _selectedCase!.domain
          : (_domain.trim().isNotEmpty ? _domain : null),
      visitNumber: computedVisitNumber,
      startedAt: _activeVisit?.startedAt ?? DateTime.now(),
      completedAt: completedAt,
      status: status,
      chiefComplaint: _chiefComplaintController.text.trim(),
      onsetDuration: _onsetDurationController.text.trim(),
      associatedSymptoms: _associatedSymptomsController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
      currentMedication: _currentMedicationController.text.trim(),
      clinicalObservations: _clinicalObservationsController.text.trim(),
      assessment: _assessmentController.text.trim(),
      plan: _planController.text.trim(),
      summary: _summaryController.text.trim(),
      summaryText: _summaryController.text.trim(),
      prescriptions: _prescriptionRows.map((r) => r.toPrescriptionItem()).toList(),
      summaryApprovalStatus: _summaryApprovalStatus,
      approvedByDoctorId: _approvedDoctorId,
      approvedAt: _approvedAt,
      followUp: _followUpController.text.trim(),
      patientInstructions: _patientInstructionsController.text.trim(),
      investigationRequests: List.from(_investigationRequests),
      vitals: _vitals ?? _activeVisit?.vitals,
    );
  }

  Future<void> _onSaveDraft() async {
    final strings = DoctorLocalizations.forLocale(_locale);
    final draftVisit = _buildCurrentVisitFromState(
      status: ClinicalVisitStatus.active,
    );

    try {
      await BackendProvider.instance.clinicalVisitRepository.updateVisit(draftVisit);

      // Also update case history if needed
      if (_selectedCase != null) {
        final updatedCase = _selectedCase!.copyWith(
          relevantHistory: _relevantHistoryController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await BackendProvider.instance.caseRepository.updateCase(updatedCase);
      }

      final session = DoctorSessionService.instance;
      final doctorId = session.activeDoctorId ?? 'DOC-101';

      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'CONSULTATION_DRAFT_SAVED',
            entityType: 'CLINICAL_VISIT',
            entityId: draftVisit.visitId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient?.patientId,
              'caseId': _selectedCase?.caseId,
              'visitId': draftVisit.visitId,
              'queueNumber': _queueNumber,
            },
          ),
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _activeVisit = draftVisit;
          final idx = _visits.indexWhere((v) => v.visitId == draftVisit.visitId);
          if (idx != -1) {
            _visits[idx] = draftVisit;
          } else {
            _visits.add(draftVisit);
          }
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.draftSavedNotice),
            backgroundColor: DoctorColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save consultation: $e'),
            backgroundColor: DoctorColors.statusBusy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onCompleteVisit() async {
    final visitToValidate = _buildCurrentVisitFromState(
      status: ClinicalVisitStatus.active,
    );

    // 1. Validation check
    if (!visitToValidate.canCompleteVisit) {
      showDialog(
        context: context,
        builder: (ctx) => DoctorMissingRequirementsDialog(
          missingRequirements: visitToValidate.missingRequirements,
          locale: _locale,
        ),
      );
      return;
    }

    // 2. Present Complete Visit Modal with Prerequisites and Doctor Declaration
    showDialog(
      context: context,
      builder: (ctx) => DoctorCompleteVisitDialog(
        visit: visitToValidate,
        hasPdfGenerated: true,
        locale: _locale,
        onConfirmCompletion: () => _executeVisitCompletion(visitToValidate),
      ),
    );
  }

  Future<void> _executeVisitCompletion(ClinicalVisit visitToValidate) async {
    final strings = DoctorLocalizations.forLocale(_locale);
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';

    // 1. Log Declaration Confirmed Audit Event
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'VISIT_COMPLETION_DECLARATION_CONFIRMED',
          entityType: 'CLINICAL_VISIT',
          entityId: visitToValidate.visitId,
          timestamp: DateTime.now(),
          metadata: {
            'patientId': _patient?.patientId,
            'caseId': _selectedCase?.caseId,
            'visitId': visitToValidate.visitId,
            'visitNumber': visitToValidate.visitNumber,
            'doctorId': doctorId,
          },
        ),
      );
    } catch (_) {}

    try {
      // 2. Save latest form updates
      await BackendProvider.instance.clinicalVisitRepository.updateVisit(visitToValidate);

      // 3. Complete the Visit in repository
      final completedVisit =
          await BackendProvider.instance.clinicalVisitRepository.completeVisit(
        patientId: visitToValidate.patientId,
        caseId: visitToValidate.caseId,
        visitId: visitToValidate.visitId,
        doctorId: doctorId,
      );

      // 3b. Mark corresponding appointment status as completed
      if (_requestId.isNotEmpty) {
        try {
          await BackendProvider.instance.appointmentRepository
              .updateAppointmentStatus(_requestId, AppointmentStatus.completed);
        } catch (e) {
          debugPrint('[DoctorPatientWorkspaceScreen] Appointment completion status sync notice: $e');
        }
      }

      // 4. Update parent Case (Case status strictly REMAINS OPEN)
      if (_selectedCase != null) {
        final updatedCase = _selectedCase!.copyWith(
          relevantHistory: _relevantHistoryController.text.trim(),
          updatedAt: DateTime.now(),
          status: ClinicalCaseStatus.open,
        );
        await BackendProvider.instance.caseRepository.updateCase(updatedCase);
      }

      // 5. Log VISIT_COMPLETED Audit Event
      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUDIT-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'VISIT_COMPLETED',
            entityType: 'CLINICAL_VISIT',
            entityId: completedVisit.visitId,
            timestamp: DateTime.now(),
            metadata: {
              'patientId': _patient?.patientId,
              'caseId': _selectedCase?.caseId,
              'visitId': completedVisit.visitId,
              'visitNumber': completedVisit.visitNumber,
              'queueNumber': _queueNumber,
              'doctorId': doctorId,
              'completedAt': completedVisit.completedAt?.toIso8601String(),
              'prescriptionCount': completedVisit.prescriptions.length,
            },
          ),
        );
      } catch (_) {}

      // 6. Transition Doctor Presence: IN_CONSULTATION -> AVAILABLE
      await DoctorPresenceService.instance.setAvailable();

      if (mounted) {
        setState(() {
          _activeVisit = completedVisit;
          final idx =
              _visits.indexWhere((v) => v.visitId == completedVisit.visitId);
          if (idx != -1) {
            _visits[idx] = completedVisit;
          } else {
            _visits.add(completedVisit);
          }
        });

        // 7. Show Completion Confirmation Modal
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => DoctorVisitCompletedDialog(
            visit: completedVisit,
            domain: _selectedCase?.domain ?? _domain,
            locale: _locale,
            onReturnToDashboard: () {
              Navigator.of(ctx).pop();
              Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.doctorDashboard);
            },
          ),
        );
      }
    } catch (e) {
      // If backend fails: doctor presence remains IN_CONSULTATION
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.visitCompletionFailedNotice} ($e)'),
            backgroundColor: DoctorColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onEscalateCase() {
    if (_patient == null || _selectedCase == null) return;

    showDialog(
      context: context,
      builder: (ctx) => DoctorCaseEscalationDialog(
        clinicalCase: _selectedCase!,
        currentVisitNumber: _activeVisit?.visitNumber ?? 1,
        department: _selectedCase?.domain ?? _domain,
        locale: _locale,
        onConfirm: (reason, note) async {
          final session = DoctorSessionService.instance;
          final doctorId = session.activeDoctorId ?? 'DOC-101';
          final doctorName = session.activeDoctorName ?? 'Dr. Rajesh Sharma';
          final visitId = _activeVisit?.visitId ?? 'VISIT-${_patient!.patientId}-1';

          final escalated = await BackendProvider.instance.caseRepository.escalateCase(
            patientId: _patient!.patientId,
            caseId: _selectedCase!.caseId,
            visitId: visitId,
            doctorId: doctorId,
            doctorName: doctorName,
            reason: reason,
            note: note,
          );

          if (mounted) {
            setState(() {
              _selectedCase = escalated;
              final idx = _cases.indexWhere((c) => c.caseId == escalated.caseId);
              if (idx != -1) {
                _cases[idx] = escalated;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  DoctorLocalizations.forLocale(_locale).caseEscalatedSuccess,
                ),
                backgroundColor: DoctorColors.brandTeal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _onTransfer() {
    if (_patient == null || _selectedCase == null) return;

    final currentVisit = _buildCurrentVisitFromState(
      status: ClinicalVisitStatus.active,
    );

    showDialog(
      context: context,
      builder: (ctx) => DoctorTransferPatientDialog(
        currentDepartment: _selectedCase?.domain ?? _domain,
        patientId: _patient!.patientId,
        patientName: _patient!.name,
        clinicalCase: _selectedCase!,
        currentVisit: currentVisit,
        locale: _locale,
        onConfirmTransfer: (destinationDept, reason) {
          _executeTransfer(
            destinationDepartment: destinationDept,
            transferReason: reason,
            currentVisit: currentVisit,
          );
        },
      ),
    );
  }

  Future<void> _executeTransfer({
    required String destinationDepartment,
    required String transferReason,
    required ClinicalVisit currentVisit,
  }) async {
    final strings = DoctorLocalizations.forLocale(_locale);
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';
    final doctorName = session.activeDoctorName ?? 'Dr. Rajesh Sharma';
    final currentDept = _selectedCase?.domain ?? _domain;
    final now = DateTime.now();
    final transferId = 'TRF-${_patient!.patientId}-${now.millisecondsSinceEpoch}';

    // 1. Audit Log: TRANSFER_REQUESTED
    try {
      await BackendProvider.instance.auditRepository.logEvent(
        AuditLog(
          auditId: 'AUD-TRF-REQ-${now.millisecondsSinceEpoch}',
          actorType: 'DOCTOR',
          actorId: doctorId,
          action: 'TRANSFER_REQUESTED',
          entityType: 'PATIENT_TRANSFER',
          entityId: transferId,
          timestamp: now,
          metadata: {
            'transferId': transferId,
            'patientId': _patient!.patientId,
            'caseId': _selectedCase!.caseId,
            'sourceVisitId': currentVisit.visitId,
            'sourceDoctorId': doctorId,
            'sourceDepartment': currentDept,
            'destinationDepartment': destinationDepartment,
          },
        ),
      );
    } catch (_) {}

    try {
      // 2. Mark current visit as TRANSFERRED and persist in repository
      final transferredVisit = currentVisit.copyWith(
        status: ClinicalVisitStatus.transferred,
      );
      await BackendProvider.instance.clinicalVisitRepository
          .updateVisit(transferredVisit);

      // 3. Create transfer request in transfer repository
      final transferRequest = PatientTransferRequest(
        transferId: transferId,
        patientId: _patient!.patientId,
        caseId: _selectedCase!.caseId,
        sourceVisitId: currentVisit.visitId,
        sourceDoctorId: doctorId,
        sourceDoctorName: doctorName,
        sourceDepartment: currentDept,
        destinationDepartment: destinationDepartment,
        reason: transferReason,
        requestedAt: now,
        status: TransferStatus.pending,
        queueNumber: _queueNumber,
        patientAge: _patient!.age,
        patientGender: _patient!.gender,
        vitals: _vitals,
      );
      await BackendProvider.instance.transferRepository
          .createTransfer(transferRequest);

      // 4. Audit Log: TRANSFER_CONFIRMED
      try {
        await BackendProvider.instance.auditRepository.logEvent(
          AuditLog(
            auditId: 'AUD-TRF-CONF-${DateTime.now().millisecondsSinceEpoch}',
            actorType: 'DOCTOR',
            actorId: doctorId,
            action: 'TRANSFER_CONFIRMED',
            entityType: 'PATIENT_TRANSFER',
            entityId: transferId,
            timestamp: DateTime.now(),
            metadata: {
              'transferId': transferId,
              'patientId': _patient!.patientId,
              'caseId': _selectedCase!.caseId,
              'sourceVisitId': currentVisit.visitId,
              'sourceDoctorId': doctorId,
              'sourceDepartment': currentDept,
              'destinationDepartment': destinationDepartment,
            },
          ),
        );
      } catch (_) {}

      // 5. Restore Doctor Presence: IN_CONSULTATION -> AVAILABLE (only after backend persistence succeeds)
      await DoctorPresenceService.instance.setAvailable();

      if (mounted) {
        // Show success snackbar and return to dashboard
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.transferSubmittedSuccess,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: DoctorColors.brandTeal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
      }
    } catch (e) {
      // If backend fails: doctor presence strictly remains IN_CONSULTATION
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.transferFailedNotice} ($e)'),
            backgroundColor: DoctorColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleLeaveWorkspace() {
    final strings = DoctorLocalizations.forLocale(_locale);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.consultationInProgressTitle),
        content: Text(strings.consultationInProgressNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.stayButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.statusCritical,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
            },
            child: Text(strings.leaveWorkspaceButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(_locale);
    final session = DoctorSessionService.instance;
    final doctorName = session.activeDoctorName ?? 'Dr. Rajesh Sharma';
    final doctorDepartment = session.activeDepartment ?? 'Cardiology';

    final isRecordingActive = _speechState == SpeechRecognitionState.listening ||
        _speechState == SpeechRecognitionState.processing;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleLeaveWorkspace();
        }
      },
      child: Scaffold(
        backgroundColor: DoctorColors.background,
        body: Column(
          children: [
            // Top Workspace Header
            DoctorPatientWorkspaceHeader(
              doctorName: doctorName,
              doctorDepartment: doctorDepartment,
              queueNumber: _queueNumber,
              isPreviousDoctorRequested: _isPreviousDoctorRequested,
              onBackAttempt: _handleLeaveWorkspace,
              locale: _locale,
            ),

            // Speech Error banner if any
            if (_speechErrorMessage != null)
              DoctorSpeechErrorCard(
                errorMessage: _speechErrorMessage!,
                onDismiss: () => setState(() => _speechErrorMessage = null),
                locale: _locale,
              ),

            // Speech Floating Recording Bar
            if (isRecordingActive)
              DoctorSpeechRecordingBar(
                fieldId: _activeListeningField ?? 'activeField',
                fieldLabel: _getFieldLabel(_activeListeningField ?? 'activeField'),
                elapsedDuration: _recordingDuration,
                partialTranscript: _partialTranscript,
                isProcessing: _speechState == SpeechRecognitionState.processing,
                onStop: _handleStopSpeech,
                onCancel: _handleCancelSpeech,
                locale: _locale,
              ),

            // Content Body
            Expanded(
              child: _buildBody(strings, doctorName),
            ),

            // Bottom Action Bar (if loaded)
            if (!_isLoading && _patient != null && !_isUnauthorized)
              DoctorWorkspaceBottomBar(
                onSaveDraft: _onSaveDraft,
                onPreviewReport: _onPreviewVisitReport,
                onEscalateCase: _selectedCase != null && _selectedCase!.isOpen
                    ? _onEscalateCase
                    : null,
                onTransfer: _onTransfer,
                onComplete: _onCompleteVisit,
                locale: _locale,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DoctorStrings strings, String doctorName) {
    if (_isLoading) {
      return Center(
        child: DoctorLoadingView(
          message: strings.loadingPatientWorkspace,
          subtitle: strings.loadingSubtitle,
        ),
      );
    }

    if (_isUnauthorized) {
      return Center(
        child: DoctorErrorView(
          title: strings.unauthorizedAccess,
          message: _errorMessage ?? strings.unauthorizedAccess,
          onRetry: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.doctorDashboard),
        ),
      );
    }

    if (_errorMessage != null || _patient == null) {
      return Center(
        child: DoctorErrorView(
          title: strings.patientNotFound,
          message: _errorMessage ?? strings.unableToLoadClinicalRecords,
          onRetry: _loadWorkspaceData,
        ),
      );
    }

    // Filter visits for currently selected case
    final activeCaseVisits = _selectedCase != null
        ? _visits.where((v) => v.caseId == _selectedCase!.caseId).toList()
        : <ClinicalVisit>[];

    final session = DoctorSessionService.instance;
    final doctorQualification =
        session.activeProfile?.qualification ?? 'MBBS, MD (Cardiology)';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DoctorTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transfer Context Banner (if transferred from another department)
          if (_sourceDepartment != null && _sourceDepartment!.isNotEmpty) ...[
            DoctorTransferContextBanner(
              sourceDepartment: _sourceDepartment!,
              sourceDoctorName: _sourceDoctorName,
              transferReason: _transferReason ?? '',
              locale: _locale,
            ),
          ],

          // 1. Visit Identification
          DoctorVisitIdentificationCard(
            patientId: _patient!.patientId,
            caseId: _selectedCase?.caseId ?? 'CASE-001',
            visitNumber: _activeVisit?.visitNumber ?? 1,
            status: _activeVisit?.status ?? ClinicalVisitStatus.active,
            department: _selectedCase?.domain ?? _domain,
            dateTime: _activeVisit?.startedAt ?? DateTime.now(),
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 2. Patient Information (Read-Only)
          DoctorPatientInfoConsultationCard(
            patient: _patient!,
            doctorName: doctorName,
            doctorQualification: doctorQualification,
            isExistingPatient: _isPreviousDoctorRequested,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 3. Vitals at Consultation (Read-Only)
          DoctorVitalsConsultationCard(
            vitals: _vitals,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 4. Clinical Cases & Visits Selection
          DoctorClinicalRecordsSection(
            cases: _cases,
            selectedCase: _selectedCase,
            visits: activeCaseVisits,
            onSelectCase: _onSelectCase,
            onStartNewCase: _onStartNewCase,
            onAddVisit: _onAddVisit,
            onCloseCase: _onCloseCaseRequested,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 5. Case Information
          if (_selectedCase != null) ...[
            DoctorCaseInfoCard(
              clinicalCase: _selectedCase!,
              relevantHistoryController: _relevantHistoryController,
              activeListeningField: _activeListeningField,
              isListening: _speechState == SpeechRecognitionState.listening,
              onSpeechTrigger: _handleSpeechTrigger,
              locale: _locale,
            ),
            const SizedBox(height: DoctorTheme.space16),
          ],

          // 6. Structured Consultation (8 Mandatory Fields)
          DoctorStructuredConsultationCard(
            chiefComplaintController: _chiefComplaintController,
            onsetDurationController: _onsetDurationController,
            associatedSymptomsController: _associatedSymptomsController,
            medicalHistoryController: _medicalHistoryController,
            currentMedicationController: _currentMedicationController,
            clinicalObservationsController: _clinicalObservationsController,
            assessmentController: _assessmentController,
            planController: _planController,
            activeListeningField: _activeListeningField,
            isListening: _speechState == SpeechRecognitionState.listening,
            onSpeechTrigger: _handleSpeechTrigger,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 7. Prescription Module (D9.1)
          DoctorPrescriptionCard(
            rows: _prescriptionRows,
            onAddMedicine: _onAddPrescriptionMedicine,
            onRemoveMedicine: _onRemovePrescriptionMedicine,
            onCreateWithCount: _onCreatePrescriptionWithCount,
            onDictate: _onPrescriptionDictate,
            isListening: _speechState == SpeechRecognitionState.listening,
            activeListeningField: _activeListeningField,
            prescriptionTranscript: _prescriptionTranscript,
            onUseTranscript: _onUsePrescriptionTranscript,
            onDiscardTranscript: _onDiscardPrescriptionTranscript,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 8. Gemini Documentation Assistant (Phase D10)
          ListenableBuilder(
            listenable: Listenable.merge([
              _chiefComplaintController,
              _onsetDurationController,
              _associatedSymptomsController,
              _medicalHistoryController,
              _currentMedicationController,
              _clinicalObservationsController,
              _assessmentController,
              _planController,
              _summaryController,
            ]),
            builder: (context, _) {
              final docInput = _buildDocumentationInput();
              return DoctorGeminiDocumentationCard(
                isGenerating: _isGeneratingDocumentation,
                isComplete: docInput.isComplete,
                missingFields: docInput.missingFields,
                hasDraft: _summaryController.text.trim().isNotEmpty || _hasGeneratedAiDraft,
                errorMessage: _documentationErrorMessage,
                onGenerate: _onGenerateDocumentation,
                onRegenerate: _onRegenerateDocumentation,
                onDismissError: _onDismissDocumentationError,
                locale: _locale,
              );
            },
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 9. Doctor-Approved Visit Summary
          DoctorApprovedSummaryCard(
            summaryController: _summaryController,
            approvalStatus: _summaryApprovalStatus,
            approvedDoctorId: _approvedDoctorId,
            approvedAt: _approvedAt,
            onApprove: _onApproveSummary,
            onSummaryChanged: _onSummaryChanged,
            activeListeningField: _activeListeningField,
            isListening: _speechState == SpeechRecognitionState.listening,
            onSpeechTrigger: _handleSpeechTrigger,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 9. Reports / Investigations Requested
          DoctorInvestigationRequestsCard(
            requests: _investigationRequests,
            onAddInvestigation: _onAddInvestigation,
            onRemoveInvestigation: _onRemoveInvestigation,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // 10. Plan / Follow-up
          DoctorFollowUpCard(
            followUpController: _followUpController,
            patientInstructionsController: _patientInstructionsController,
            activeListeningField: _activeListeningField,
            isListening: _speechState == SpeechRecognitionState.listening,
            onSpeechTrigger: _handleSpeechTrigger,
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),

          // Reports & Diagnostic Tests Desk (Phase D11)
          DoctorReportsReviewWidget(
            investigations: _investigationRequests,
            reports: _reportDocuments,
            onMarkReviewed: _onMarkReportReviewed,
            onRequestInvestigation: _onAddInvestigation,
            onViewReport: (rep) {
              DoctorReportViewerDialog.show(
                context,
                reportDoc: rep,
                locale: _locale,
                currentPatientId: rep.patientId,
                currentCaseId: rep.caseId,
                currentVisitId: rep.visitId,
              );
            },
            locale: _locale,
          ),
          const SizedBox(height: DoctorTheme.space16),
        ],
      ),
    );
  }
}
