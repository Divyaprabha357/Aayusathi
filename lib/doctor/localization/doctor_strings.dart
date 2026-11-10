/// Base English string definitions for the AAYUSATHI Doctor Interface.
/// Designed for multi-language expansion across English, Hindi, and Marathi.
class DoctorStrings {
  const DoctorStrings();

  // Branding & Portal Titles
  String get appName => 'AAYUSATHI';
  String get appTagline => 'LIVE BETTER, TOGETHER';
  String get doctorPortalTitle => 'Doctor OPD Management System';
  String get clinicalWorkstation => 'Physician Clinical Workstation';
  String get doctorPortalBadge => 'DOCTOR PORTAL';
  String get hospitalWorkstation => 'OPD CLINICAL DESK';

  // Standby Screen
  String get standbyHeadline => 'Doctor Clinical Workstation';
  String get standbySubheadline =>
      'Secure OPD Consultation, Patient Telemetry & Electronic Health Documentation';
  String get loginButtonLabel => 'DOCTOR LOGIN';
  String get loginTooltip => 'Click or press Enter to sign in';
  String get terminalReady => 'Workstation Ready';
  String get secureSessionNotice =>
      'Authorized Physician Access Only • Hospital Network Protected';
  String get switchToKiosk => 'Switch to Kiosk Terminal';

  // Doctor Login Screen (Phase D2)
  String get doctorLoginTitle => 'DOCTOR LOGIN';
  String get doctorLoginSubtitle => 'Secure access to your clinical workstation';
  String get doctorUniqueCode => 'Doctor Unique Code';
  String get doctorUniqueCodeHint => 'Enter your assigned doctor code';
  String get password => 'Password';
  String get passwordHint => 'Enter workstation password';
  String get loginButton => 'LOGIN';
  String get forgotPassword => 'Forgot Password?';
  String get forgotPasswordTitle => 'Workstation Credential Recovery';
  String get forgotPasswordNotice =>
      'Doctor accounts are provisioned and managed by Hospital IT Administration. Please contact your Hospital Administrator or IT Helpdesk for credential recovery.';

  // OTP Verification Screen (Phase D2)
  String get otpVerificationTitle => 'OTP VERIFICATION';
  String get otpVerificationSubtitle =>
      'Enter the verification code sent to your registered mobile number.';
  String get otpSentTo => 'OTP sent to';
  String get enterOtp => 'ENTER OTP';
  String get enterSixDigitOtp => 'Enter 6-digit OTP';
  String get verifyOtpButton => 'VERIFY OTP';
  String get resendOtpButton => 'RESEND OTP';
  String resendOtpCooldown(int seconds) => 'Resend OTP in ${seconds}s';
  String get otpResentNotice => 'A new verification code has been dispatched.';

  // Validation & Error Messages (Phase D2 & D3)
  String get invalidLoginDetails => 'Invalid login details.';
  String get invalidOtp => 'Invalid OTP. Please try again.';
  String get emptyDoctorCodeError => 'Please enter your Doctor Unique Code.';
  String get emptyPasswordError => 'Please enter your password.';
  String get invalidOtpFormatError => 'Please enter the 6-digit OTP.';
  String get inactiveDoctorError =>
      'Your doctor account is currently inactive. Please contact Hospital Administration.';
  String get serverConnectionError =>
      'Unable to connect to the clinical server. Please check your connection and try again.';
  String get authFailedError =>
      'Authentication could not be completed. Please try again.';

  // Doctor Profile & Workstation Availability (Phase D4)
  String get doctorProfileTitle => 'DOCTOR PROFILE';
  String get qualificationLabel => 'QUALIFICATION';
  String get departmentLabel => 'DEPARTMENT';
  String get doctorUniqueCodeLabel => 'DOCTOR UNIQUE CODE';
  String get registeredPhoneLabel => 'REGISTERED PHONE';
  String get accountStatusLabel => 'ACCOUNT STATUS';
  String get activeStatus => 'ACTIVE';
  String get inactiveStatus => 'INACTIVE';
  String get availabilityLabel => 'AVAILABILITY';
  String get goOnlineButton => 'GO ONLINE';
  String get goOfflineButton => 'GO OFFLINE';
  String get readyForPatients => 'Ready for Patients';
  String get currentlyInConsultation => 'Currently in Consultation';
  String get profileManagedByAdminNotice =>
      'Doctor profile data is managed exclusively by Hospital Administration. Contact IT Administration for updates.';
  String get viewDoctorProfile => 'View Doctor Profile';
  String get workstationAvailability => 'Workstation Availability';

  // Patient Requests (Phase D5)
  String get patientRequestsTitle => 'PATIENT REQUESTS';
  String get patientRequestsSubtitle =>
      'Incoming OPD consultation requests for your department';
  String get pendingRequestsCountLabel => 'Pending Requests';
  String get queueNumberLabel => 'QUEUE NUMBER';
  String get ageLabel => 'AGE';
  String get genderLabel => 'GENDER';
  String get domainLabel => 'DOMAIN';
  String get requestTypeLabel => 'REQUEST TYPE';
  String get newVisitLabel => 'New Visit';
  String get previousDoctorRequestedLabel => 'Previous Doctor Requested';
  String get vitalsLabel => 'VITALS';
  String get spo2Label => 'SpO₂';
  String get heartRateLabel => 'Heart Rate';
  String get temperatureLabel => 'Temperature';
  String get waitingStatusLabel => 'Waiting';
  String get noPatientRequestsTitle => 'NO PATIENT REQUESTS';
  String get noPatientRequestsSubtitle =>
      'There are currently no waiting OPD requests for your department.';
  String get refreshRequestsButton => 'Refresh Requests';
  String get unableToLoadRequestsTitle => 'Unable to load patient requests.';
  String get acceptRequestButton => 'ACCEPT REQUEST';
  String get assignmentD6Notice =>
      'Patient assignment will be enabled in Phase D6.';
  String get notAvailableLabel => 'Not available';
  String get workstationOfflineNotice =>
      'Workstation is offline. Set status to Available to accept OPD requests.';
  String get workstationInConsultationNotice =>
      'Currently in consultation. Complete active consultation before accepting new requests.';

  // Request Acceptance & Assignment (Phase D6)
  String get acceptingRequest => 'Accepting Request...';
  String get patientAcceptedNotice => 'Patient accepted successfully.';
  String get patientAlreadyAssignedNotice =>
      'Patient request has already been assigned to another doctor.';
  String get notEligibleNotice =>
      'You are not eligible for this request.';
  String get doctorNotAvailableNotice =>
      'Workstation is not available for consultation.';
  String get unableToAcceptNotice =>
      'Unable to accept this patient request. Please try again.';
  String get openingWorkspaceNotice => 'Opening Patient Workspace...';

  // Transitions & Success
  String get authSuccessTitle => 'Authentication Successful';
  String get authSuccessSubtitle => 'Opening Clinical Workstation...';

  // Navigation & Headers
  String get navDashboard => 'Dashboard';
  String get navPatientRequests => 'Patient Requests';
  String get navPatientWorkspace => 'Patient Workspace';
  String get navConsultation => 'Consultation';
  String get navCases => 'Cases & Visits';
  String get navReports => 'Reports & Diagnostics';
  String get navSettings => 'Settings';

  // Status Indicators
  String get statusOnline => 'Online';
  String get statusOffline => 'Offline';
  String get statusAvailable => 'Available';
  String get statusInConsultation => 'In Consultation';
  String get statusBusy => 'Busy';
  String get statusOnBreak => 'On Break';

  // UI State Messages
  String get loadingTitle => 'Loading Clinical Data...';
  String get loadingSubtitle => 'Please wait while records are synchronized';
  String get emptyTitle => 'No Records Available';
  String get emptySubtitle => 'There are currently no items to display';
  String get errorTitle => 'Unable to Complete Request';
  String get errorSubtitle => 'An error occurred while loading this view';
  String get retryButton => 'Retry';
  String get successTitle => 'Operation Successful';

  // General Actions
  String get back => 'BACK';
  String get close => 'CLOSE';
  String get cancel => 'CANCEL';
  String get save => 'SAVE';
  String get proceed => 'PROCEED';

  // Patient Workspace & Clinical Records (Phase D7)
  String get patientWorkspaceTitle => 'PATIENT WORKSPACE';
  String get patientInformation => 'PATIENT INFORMATION';
  String get patientNameLabel => 'Patient Name';
  String get patientIdLabel => 'Patient ID';
  String get bloodGroupLabel => 'Blood Group';
  String get currentVitals => 'CURRENT VITALS';
  String get historicalVitals => 'HISTORICAL VITALS';
  String get clinicalRecords => 'CLINICAL RECORDS';
  String get cases => 'CASES';
  String get visits => 'VISITS';
  String get myCases => 'MY CASES';
  String get startNewCase => 'START NEW CASE';
  String get addVisit => 'ADD VISIT';
  String get caseDomainLabel => 'Case Domain';
  String get caseTitleLabel => 'Case Label / Reason';
  String get caseTitleHint => 'e.g. Hypertension & Chest Discomfort';
  String get openCase => 'OPEN';
  String get closedCase => 'CLOSED';
  String get visit => 'Visit';
  String get activeStatusLabel => 'ACTIVE';
  String get completedStatusLabel => 'COMPLETED';
  String get cancelledStatusLabel => 'CANCELLED';
  String get attendingDoctorLabel => 'Attending Doctor';
  String get visitStartedAtLabel => 'Started At';
  String get selectCasePrompt => 'Select a case to view its consultation visits.';
  String get noCasesFound => 'No clinical cases found for this patient.';
  String get noVisitsFound => 'No visits recorded for this clinical case.';
  String get clinicalDocumentationNotice =>
      'Clinical documentation will appear after consultation.';
  String get consultationWorkspacePlaceholder =>
      'Consultation documentation workspace will be available in Phase D8.';
  String get reportsTitle => 'REPORTS & DIAGNOSTICS';
  String get availableReportsTab => 'Available Reports';
  String get requestedReportsTab => 'Requested Reports';
  String get uploadedReportsTab => 'Uploaded Reports';
  String get noReportsFound => 'No diagnostic reports found.';
  String get transferPatientButton => 'TRANSFER PATIENT';
  String get completeVisitButton => 'COMPLETE VISIT';
  String get notAvailable => 'Not available';
  String get loadingPatientWorkspace => 'Loading patient workspace...';
  String get patientNotFound => 'Patient information could not be loaded.';
  String get unauthorizedAccess =>
      'You are not authorized to access this patient.';
  String get unableToLoadClinicalRecords =>
      'Unable to load clinical records. Please try again.';
  String get consultationInProgressTitle => 'Consultation in Progress';
  String get consultationInProgressNotice =>
      'Consultation is currently in progress. Are you sure you want to leave the workspace?';
  String get stayButton => 'STAY';
  String get leaveWorkspaceButton => 'LEAVE WORKSPACE';
  String get previousDoctorRequestBadge => 'PREVIOUS DOCTOR REQUEST';

  // Phase D8: Live Doctor Consultation & Clinical Documentation
  String get visitIdentification => 'VISIT IDENTIFICATION';
  String get vitalsAtConsultation => 'VITALS AT CONSULTATION';
  String get caseInformation => 'CASE INFORMATION';
  String get caseTypeLabel => 'Case Type';
  String get newCase => 'New Case';
  String get existingCase => 'Existing Case';
  String get caseStatusLabel => 'Case Status';
  String get ongoingStatus => 'Ongoing';
  String get closedStatus => 'Closed';
  String get previousRelevantHistoryLabel => 'Previous Relevant History';
  String get previousRelevantHistoryHint =>
      'Enter relevant medical, surgical or family history for this case...';
  String get structuredConsultation => 'STRUCTURED CONSULTATION';
  String get chiefComplaint => 'Chief Complaint';
  String get chiefComplaintHint =>
      'Primary reason for visit in patient\'s own words...';
  String get onsetDuration => 'Onset / Duration';
  String get onsetDurationHint =>
      'e.g. 3 days, acute onset, worsening since yesterday...';
  String get associatedSymptoms => 'Associated Symptoms';
  String get associatedSymptomsHint =>
      'e.g. Fever, radiating pain, nausea, dizziness...';
  String get medicalHistory => 'Medical History';
  String get medicalHistoryHint =>
      'Past medical conditions, allergies, surgical history...';
  String get currentMedication => 'Current Medication';
  String get currentMedicationHint =>
      'Active prescription drugs, OTC medications, dosages...';
  String get clinicalObservations => 'Clinical Observations';
  String get clinicalObservationsHint =>
      'Physical examination findings, auscultation, palpation...';
  String get assessment => 'Assessment';
  String get assessmentHint =>
      'Clinical diagnostic impression, differential diagnosis...';
  String get plan => 'Plan';
  String get planHint =>
      'Treatment strategy, investigations, immediate management...';
  String get doctorApprovedSummary => 'DOCTOR-APPROVED VISIT SUMMARY';
  String get summaryLabel => 'Visit Summary';
  String get summaryHint =>
      'Enter clinical visit summary to be reviewed and approved by doctor...';
  String get summaryStatusLabel => 'Summary Status';
  String get summaryDraftStatus => 'DRAFT';
  String get summaryReviewRequiredStatus => 'REVIEW REQUIRED';
  String get summaryApprovedStatus => 'APPROVED BY DOCTOR';
  String get approveSummaryButton => 'APPROVE SUMMARY';
  String get summaryApprovedNotice =>
      'Visit summary approved by treating doctor.';
  String get summaryEditWarning =>
      'Summary was edited. Re-approval required.';
  String get reportsRequested => 'REPORTS / INVESTIGATIONS REQUESTED';
  String get addInvestigationButton => '+ ADD REPORT / INVESTIGATION';
  String get investigationNameLabel => 'Report / Investigation Name';
  String get investigationNameHint =>
      'e.g. 12-Lead ECG, Complete Blood Count (CBC), Chest X-Ray';
  String get priorityLabel => 'Priority';
  String get requiredPriority => 'Required';
  String get asAdvisedPriority => 'As Advised';
  String get pendingUploadStatus => 'Pending Upload';
  String get uploadedStatus => 'Uploaded';
  String get reviewedStatus => 'Reviewed';
  String get planFollowUp => 'PLAN / FOLLOW-UP';
  String get followUpLabel => 'Follow-up';
  String get followUpHint =>
      'e.g. Review in 2 weeks or SOS if symptoms worsen...';
  String get patientInstructionsLabel => 'Patient Instructions';
  String get patientInstructionsHint =>
      'Dietary advice, activity precautions, lifestyle guidance...';
  String get visitCompletion => 'VISIT COMPLETION';
  String get saveDraftButton => 'SAVE DRAFT';
  String get draftSavedNotice =>
      'Consultation draft saved successfully.';
  String get visitCompletedTitle => 'VISIT COMPLETED';
  String get visitCompletedSuccess =>
      'Visit completed successfully. Case remains ONGOING.';
  String get caseOngoingNotice => 'Case remains ONGOING.';
  String get incompleteFieldsError =>
      'Please complete all required consultation fields and approve summary.';
  String get missingRequirementsTitle => 'Missing Consultation Requirements';
  String get consultationInProgress => 'Consultation in Progress';
  String get savingDraft => 'Saving draft...';
  String get completingVisit => 'Completing visit...';
  String get treatingDoctor => 'Treating Doctor';
  String get doctorQualification => 'Doctor Qualification';
  String get consultationTimestamp => 'Date / Time';
  String get statusActive => 'ACTIVE';
  String get noInvestigationsRequested =>
      'No reports or investigations requested yet.';

  // Phase D9: Speech-to-Text Consultation Assistant
  String get speechToText => 'Speech to Text';
  String get dictateField => 'Dictate notes into this field';
  String get startDictation => 'Start Dictation';
  String get stopDictation => 'Stop & Insert';
  String get cancelDictation => 'Cancel';
  String get recordingActive => 'Recording Active...';
  String get listeningToSpeech => 'Listening...';
  String get processingSpeech => 'Processing audio...';
  String get speechErrorTitle => 'Speech Recognition Error';
  String get micPermissionDenied =>
      'Microphone access is required for speech-to-text transcription. Please check device permissions.';
  String get speechEngineUnavailable =>
      'Speech-to-text service is currently unavailable on this workstation.';
  String get appendOrReplaceTitle => 'Existing Text in Field';
  String get appendOrReplacePrompt =>
      'This field already contains notes. Would you like to append the new transcript or replace the current content?';
  String get appendButton => 'APPEND';
  String get replaceButton => 'REPLACE';
  String get transcriptionSuccess => 'Speech transcript inserted into field.';
  String get micHardwareNotFound =>
      'No microphone detected. Please connect an audio input device.';
  String get noSpeechDetected =>
      'No speech was detected. Please try speaking clearly.';

  // Phase D9.1: Prescription Module & Unified Dictation
  String get prescription => 'PRESCRIPTION';
  String get prescriptionSectionTitle => 'PRESCRIPTION';
  String get numberOfMedicines => 'Number of Medicines';
  String get createPrescription => 'CREATE PRESCRIPTION';
  String get addMedicine => '+ ADD MEDICINE';
  String get removeMedicine => 'Remove';
  String get dictatePrescription => 'DICTATE PRESCRIPTION';
  String get prescriptionTranscript => 'Prescription Transcript';
  String get useInPrescription => 'USE IN PRESCRIPTION';
  String get addToExistingPrescription => 'ADD TO EXISTING PRESCRIPTION';
  String get replacePrescription => 'REPLACE PRESCRIPTION';
  String get cancelPrescriptionDictation => 'CANCEL';
  String get incompletePrescription => 'Incomplete Prescription';
  String get srNo => 'Sr. No.';
  String get medicineName => 'Name of Medicine';
  String get duration => 'Duration';
  String get timesADay => 'Times a Day';
  String get remarks => 'Remarks';
  String get medicineNameHint => 'e.g. Paracetamol 500 mg';
  String get durationHint => 'e.g. 5 days';
  String get timesADayHint => 'e.g. 2';
  String get remarksHint => 'e.g. After food';
  String get enterNumberOfMedicinesPrompt =>
      'Enter how many medicines are required for this prescription.';
  String get noMedicinesAddedNotice =>
      'No medicines added yet. Enter number of medicines or dictate.';

  // Phase D10: Gemini Documentation Assistant
  String get doctorAssistedDocumentation => 'DOCTOR-ASSISTED DOCUMENTATION';
  String get generateDraftSummary => 'GENERATE DRAFT SUMMARY';
  String get regenerateDraftSummary => 'REGENERATE DRAFT';
  String get aiPreparingDocumentation => 'AI is preparing documentation draft...';
  String get aiDraftDisclaimer =>
      'AI-generated documentation is a draft. Doctor review and approval are required.';
  String get regenerateWarningTitle => 'Regenerate Documentation Draft?';
  String get regenerateWarningPrompt =>
      'Regenerating will replace the current draft with a new AI-generated draft. Your current manual edits may be lost.';
  String get regenerateButton => 'REGENERATE';
  String get documentationUnavailable =>
      'Documentation assistance is temporarily unavailable. Your consultation data has not been changed.';
  String get completeMandatoryFieldsPrompt =>
      'Complete all 8 required consultation fields to generate draft summary.';
  String get aiAssistedBadge => 'AI ASSISTED';
  String get devModeBadge => 'DEV MODE';

  // Phase D9.2: Gemini Speech Transcript Cleanup Assistant
  String get voiceTranscriptReviewTitle => 'VOICE TRANSCRIPT REVIEW';
  String get originalTranscriptLabel => 'ORIGINAL TRANSCRIPT (SPEECH-TO-TEXT)';
  String get geminiCleanedDraftLabel => 'AI CLEANED TRANSCRIPT DRAFT';
  String get useCleanedVersion => 'USE CLEANED VERSION';
  String get useOriginal => 'USE ORIGINAL';
  String get editManually => 'EDIT';
  String get doneEditing => 'DONE EDITING';
  String get cleanAgain => 'CLEAN AGAIN';
  String get cleanAgainTitle => 'Regenerate Cleaned Draft?';
  String get cleanAgainPrompt =>
      'Generate a new cleaned draft from the original transcript? Your current edits will not be used as the source.';
  String get cleanAgainConfirm => 'CLEAN AGAIN';
  String get aiDraftNotice =>
      'AI CLEANUP IS A DRAFT. Please verify before accepting.';
  String get aiCleaningInProgress => 'AI is cleaning transcript draft...';
  String get cleanupUnavailable =>
      'AI cleanup is unavailable. You can use the original transcript or edit it manually.';
  String get transcriptTooLong =>
      'Transcript is too long for AI cleanup. Please edit or split the dictation.';
  String get unclearPhraseWarning => 'Unclear phrase detected — please verify.';
  String get editModeNotice => 'Editing mode active. Make changes and accept.';

  // Phase D11: Reports, Investigations & Visit PDF
  String get investigationCategoryLabel => 'Category';
  String get labCategory => 'Lab';
  String get radiologyCategory => 'Radiology';
  String get diagnosticCategory => 'Diagnostic';
  String get otherCategory => 'Other';
  String get requestInvestigationButton => '+ REQUEST INVESTIGATION';
  String get requestInvestigationDialogTitle => 'REQUEST DIAGNOSTIC INVESTIGATION';
  String get reportsReviewTitle => 'DOCTOR REPORTS & DIAGNOSTICS';
  String get tabRequested => 'Requested';
  String get tabUploaded => 'Uploaded (Pending Review)';
  String get tabReviewed => 'Reviewed';
  String get markAsReviewedButton => 'MARK AS REVIEWED';
  String get reportReviewedNotice => 'Report marked as reviewed by attending doctor.';
  String get noReportsInTab => 'No reports in this section.';
  String get viewReportButton => 'VIEW REPORT';
  String get uploadReportButton => 'UPLOAD REPORT';
  String get previewVisitReportButton => 'PREVIEW VISIT REPORT';
  String get visitReportPreviewTitle => 'AAYUSATHI — CASE & VISIT DOCUMENTATION (DRAFT PREVIEW)';
  String get generatePdfButton => 'GENERATE VISIT PDF';
  String get printPdfButton => 'PRINT / EXPORT PDF';
  String get pdfGatingWarning =>
      'Complete all required consultation fields and approve the visit summary before generating the report.';
  String get pdfGeneratedSuccess => 'Official AAYUSATHI Visit Report PDF generated successfully.';

  // Phase D11.1: PDF Output, Open & Save As
  String get pdfCreatedSuccessTitle => 'Visit Report PDF Created';
  String get openPdfButton => 'OPEN PDF';
  String get saveAsButton => 'SAVE AS';
  String get pdfLocationLabel => 'Saved Location';
  String get pdfOpenError => 'PDF was created, but Windows could not open the file.';
  String get pdfSaveAsSuccess => 'PDF report copy saved successfully.';
  String get pdfSaveAsCancelled => 'Save operation cancelled.';
  String get pdfSavedToDesktopNotice => 'Report PDF copy successfully saved to your Desktop.';

  // Phase D12: Visit Completion, Case Lifecycle & Doctor Workflow Finalization
  String get completeVisitDialogTitle => 'Complete Visit';
  String get completeVisitExplanation =>
      'Completing this Visit records the consultation as completed. The Case will remain open for future visits unless explicitly closed later.';
  String get prerequisitesChecklistTitle => 'Before completing this Visit, confirm:';
  String get consultationDocsCompleteCheck =>
      'Required consultation documentation complete (8 fields)';
  String get summaryApprovedCheck => 'Doctor-approved summary present';
  String get investigationsRecordedCheck => 'Reports / investigations recorded';
  String get pdfGeneratedCheck => 'Visit report generated';
  String get caseRemainsOpenNote =>
      'Note: Completing this Visit does not close the Case.';
  String get doctorDeclarationCheckbox =>
      'I confirm that I have reviewed and completed the documentation for this consultation.';
  String get doctorDeclarationText =>
      'I confirm that the documentation for this consultation is complete and this Visit may be marked as completed.';
  String get completeVisitSubmitButton => 'COMPLETE VISIT';
  String get visitCompletedSuccessTitle => 'Visit Completed Successfully';
  String get visitCompletedSuccessSubtitle =>
      'Consultation encounter has been finalized. Patient Case remains OPEN.';
  String get historicalVisitReadOnlyTitle => 'Historical Visit Details (Read-Only)';
  String get historicalVisitNotice =>
      'This completed visit record is archived and read-only.';
  String get viewVisitDetailsButton => 'VIEW VISIT';
  String get continueExistingCaseButton => '+ NEW VISIT';
  String get newVisitCreatedNotice =>
      'New active visit started for this ongoing case.';
  String get visitCompletionFailedNotice =>
      'Unable to complete this Visit. Please try again.';
  String get caseStatusOpenBadge => 'OPEN (ONGOING)';
  String get caseStatusClosedBadge => 'CLOSED';
  String get completedByDoctorLabel => 'Completed By';
  String get completedAtLabel => 'Completed At';
  String get backToDashboardButton => 'RETURN TO DASHBOARD';
  String get chiefComplaintLabel => chiefComplaint;
  String get onsetDurationLabel => onsetDuration;
  String get associatedSymptomsLabel => associatedSymptoms;
  String get medicalHistoryLabel => medicalHistory;
  String get currentMedicationLabel => currentMedication;
  String get clinicalObservationsLabel => clinicalObservations;
  String get assessmentLabel => assessment;
  String get planLabel => plan;

  // Phase D13: Doctor Transfer & Inter-Department Referral
  String get transferPatientTitle => 'Transfer Patient';
  String get transferPatientSubtitle =>
      'Refer patient to another medical department for specialized evaluation.';
  String get transferPatientDialogSubtitle =>
      'Select a destination OPD department and specify clinical reasons for transfer.';
  String get continueButton => 'CONTINUE';
  String get reviewTransferButton => 'REVIEW TRANSFER';
  String get selectDestinationDepartment => 'Select Destination Department';
  String get currentDepartmentLabel => 'Current Department';
  String get destinationDepartmentLabel => 'Destination Department';
  String get transferReasonLabel => 'Transfer Reason';
  String get transferReasonHint =>
      'Enter clinical rationale for transfer (e.g., Requires neurological evaluation)...';
  String get transferReasonRequiredError => 'Transfer reason is required.';
  String get transferReasonTooLongError =>
      'Transfer reason cannot exceed 1000 characters.';
  String get cannotTransferToSameDepartmentError =>
      'Destination department cannot be the same as current department.';
  String get transferPreservesCaseNote =>
      'Important: The transfer will preserve this patient\'s existing Case and Visit history.';
  String get reviewTransferTitle => 'Review Transfer';
  String get reviewTransferSubtitle =>
      'Confirm inter-department patient referral details before submission.';
  String get confirmTransferButton => 'CONFIRM TRANSFER';
  String get transferSubmittedSuccess =>
      'Patient transferred successfully. Returning to dashboard...';
  String get transferFailedNotice =>
      'Failed to transfer patient. Please try again.';
  String get transferredFromBanner => 'Transferred from';
  String get transferRequestBadge => 'TRANSFER REQUEST';
  String get fromDepartmentLabel => 'From';
  String get transferReasonCardLabel => 'Reason';
  String get cancelTransferTitle => 'Cancel Transfer?';
  String get cancelTransferConfirmation =>
      'Are you sure you want to cancel this transfer request?';
  String get cancelTransferButton => 'CANCEL TRANSFER';
  String get keepTransferButton => 'KEEP TRANSFER';
  String get transferCancelledSuccess =>
      'Transfer request cancelled successfully.';
  String get transferAlreadyAcceptedNotice =>
      'This transfer request was already accepted by another doctor.';
  String get awaitingTransferDoctorBadge => 'Awaiting Doctor';
  String get transferAssignedBadge => 'Transfer Assigned';

  // Phase D14: Doctor Case Continuation & Follow-Up Workflow
  String get continueCaseButton => 'CONTINUE CASE';
  String get viewHistoryButton => 'VIEW HISTORY';
  String get caseTimelineTab => 'CASE TIMELINE';
  String get visitHistoryTab => 'VISIT HISTORY';
  String get startNewVisitTitle => 'Start New Visit';
  String get startNewVisitSubtitle =>
      'A new consultation visit will be created under this existing Case.';
  String get startNewVisitButton => '+ NEW VISIT';
  String get confirmStartNewVisitButton => 'START NEW VISIT';
  String get activeVisitExistsTitle => 'Active Visit Exists';
  String get activeVisitExistsNotice =>
      'An active consultation already exists for this Case.';
  String get returnToActiveVisitButton => 'RETURN TO CONSULTATION';
  String get caseInformationTitle => 'CASE INFORMATION';
  String get createdDateLabel => 'Created Date';
  String get lastUpdatedLabel => 'Last Updated';
  String get caseTimeline => 'Case Timeline';
  String get timelineFilterAll => 'All';
  String get timelineFilterCompleted => 'Completed';
  String get timelineFilterTransferred => 'Transferred';
  String get timelineFilterActive => 'Active';
  String get currentVitalsNotRecorded => 'Current vitals not recorded.';
  String get historicalVitalsLabel => 'Historical Vitals';
  String get caseContinuedSuccess =>
      'Continuing existing case. New visit started.';
  String get openCasesTitle => 'Open Cases';
  String get closedCasesTitle => 'Closed Cases (Read-Only)';
  String get previousCaseHistoryTitle => 'PREVIOUS CASE HISTORY';

  // Phase D15: Doctor Case Closure, Standalone Cases & Diagnostics Desks
  String get closeCaseButton => 'CLOSE CASE';
  String get closeCaseTitle => 'Close Case';
  String get closeCaseSubtitle =>
      'Conclude this patient\'s clinical episode of care.';
  String get closeCaseExplanation =>
      'Before closing this Case, confirm that the patient\'s condition/problem associated with this Case has been resolved or that no further consultation is required under this Case.';
  String get closeCaseDeclarationCheckbox =>
      'I confirm that I am closing this Case because the clinical problem associated with this Case has been resolved / appropriately concluded.';
  String get closureDeclarationError =>
      'You must confirm the closure declaration checkbox.';
  String get closureNoteLabel => 'Closure Note';
  String get closureNoteHint =>
      'Enter doctor closure note / clinical outcome (max 1,000 characters)...';
  String get closureNoteRequiredError => 'Closure note is required.';
  String get closureNoteTooLongError =>
      'Closure note cannot exceed 1,000 characters.';
  String get activeVisitBlocksClosureError =>
      'Complete or transfer the active Visit before closing this Case.';
  String get pendingTransferBlocksClosureError =>
      'A pending inter-department transfer must be resolved before closing this Case.';
  String get caseClosedSuccessTitle => 'CASE CLOSED';
  String get caseClosedSuccessSubtitle =>
      'All previous Visits and clinical records remain preserved.';
  String get closedByDoctorLabel => 'Closed by';
  String get closureDateLabel => 'Date';
  String get closureNoteCardLabel => 'Closure Note';
  String get viewCaseHistoryButton => 'VIEW CASE HISTORY';
  String get closedCaseReadOnlyNotice =>
      'This Case is CLOSED and archived. All historical visits and documents are read-only.';
  String get cannotAddVisitToClosedCase =>
      'Cannot start a new visit under a closed case.';
  String get casesAndVisitsTitle => 'Cases & Clinical Visits';
  String get casesAndVisitsSubtitle => 'OPD Longitudinal Patient Histories';
  String get tabAllCases => 'All Cases';
  String get tabOpenCases => 'Open Cases';
  String get tabClosedCases => 'Closed Cases';
  String get searchCasesHint => 'Search by Patient ID, Case ID, or Domain...';
  String get openCaseButton => 'OPEN CASE';
  String get noCasesInFilter => 'No clinical cases found for this category.';
  String get reportsAndDiagnosticsTitle => 'Diagnostic Reports';
  String get reportsAndDiagnosticsSubtitle =>
      'Lab investigations & Radiology Records';
  String get tabVisitReports => 'Visit Reports';
  String get searchReportsHint => 'Search by Patient ID or Investigation Name...';
  String get markReviewedSuccess =>
      'Diagnostic report marked as reviewed by doctor.';
  String get officialVisitPdf => 'Official Visit PDF';
  String get caseClosedTimelineTitle => 'Case Closed';
  String get caseClosedTimelineBadge => 'CASE CLOSED';
  String get createdLabel => 'Created';
  String get unauthorizedCaseAccess =>
      'You are not authorized to view or access this clinical case.';

  // Phase A8: Case Escalation
  String get escalateCaseButton => 'ESCALATE CASE';
  String get escalateCaseDialogTitle => 'Request Higher Authority Review';
  String get escalateCaseDialogSubtitle => 'Clinical Case Escalation Protocol';
  String get escalationReasonPrompt =>
      'Select the primary clinical reason for higher authority review:';
  String get reasonClinicalDeterioration => 'Clinical deterioration';
  String get reasonRepeatedVisits => 'Repeated visits without resolution';
  String get reasonHigherAuthority => 'Higher authority review required';
  String get reasonDoctorConcern => 'Doctor concern';
  String get reasonOther => 'Other';
  String get escalationNoteLabel => 'Additional Clinical Context / Reason';
  String get escalationNoteHint =>
      'Enter concise explanation for higher authority review...';
  String get escalationNoteRequiredError =>
      'Please provide an explanation when selecting "Other".';
  String get confirmEscalatePrompt =>
      'Escalate this clinical case for Admin review?';
  String get confirmEscalateNotice =>
      'The case and ongoing consultation will remain open and active.';
  String get caseAlreadyEscalatedMessage =>
      'This case is already escalated for Admin review.';
  String get caseEscalatedSuccess => 'Case escalated for Admin review.';
  String get escalating => 'Escalating...';

  // Patient Uploaded Reports (Past Visits & Clinical Workspace)
  String get patientUploadedReportsHeader => 'Patient Uploaded Reports';
  String get noPatientReportsForVisit =>
      'No patient reports uploaded for this visit.';
  String get waitingForPatientReport => 'Waiting for patient report.';
  String get aiSummarizeReportButton => 'AI Summarize Report';
  String get aiSummaryTitle => 'AI Report Summary Assistant';
  String get aiSummaryNotice =>
      'AI-generated summary — Doctor verification required.';
  String get aiSummaryDisclaimer =>
      'AI must not diagnose the patient or prescribe treatment.';
  String get unauthorizedReportAccess =>
      'You are not authorized to view reports for this patient visit.';
  String get analyzingReport => 'Analyzing report...';
  String get unableToSummarizeReport => 'Unable to summarize this report.';
  String get unableToSummarizeReportTryAgain =>
      'Unable to summarize this report. Please try again.';
  String get reviewRequiredBadge => 'REVIEW REQUIRED';
  String get approvedByDoctorBadge => 'APPROVED BY DOCTOR';
  String get editSummaryButton => 'Edit Summary';
  String get regenerateConfirmationTitle => 'Regenerate AI Summary?';
  String get regenerateConfirmationMessage =>
      'Regenerating will replace the approved summary and reset its status to REVIEW REQUIRED. Do you wish to continue?';
  String get reportOverviewHeader => '1. REPORT OVERVIEW';
  String get keyFindingsHeader => '2. KEY FINDINGS';
  String get reportedMeasurementsHeader => '3. REPORTED MEASUREMENTS';
  String get reportedFindingsHeader => '4. REPORTED FINDINGS';
  String get reportedImpressionHeader => '5. REPORTED IMPRESSION / CONCLUSION';
  String get itemsToReviewHeader => '6. ITEMS TO REVIEW';
  String get dataQualityHeader => '7. DATA QUALITY / UNCERTAINTY';
  String get summarySavedNotice => 'AI summary approved and saved by doctor.';
  String get saveChangesButton => 'SAVE CHANGES';

  // Placeholders
  String placeholderNotice(String featureName) =>
      '$featureName will be fully integrated in subsequent doctor phases.';
}

/// Hindi localized string definitions for the AAYUSATHI Doctor Interface.
class DoctorStringsHindi extends DoctorStrings {
  const DoctorStringsHindi();

  @override
  String get doctorPortalTitle => 'डॉक्टर ओपीडी प्रबंधन प्रणाली';
  @override
  String get clinicalWorkstation => 'चिकित्सक क्लिनिकल वर्कस्टेशन';
  @override
  String get doctorPortalBadge => 'डॉक्टर पोर्टल';
  @override
  String get hospitalWorkstation => 'ओपीडी क्लिनिकल डेस्क';

  @override
  String get standbyHeadline => 'डॉक्टर क्लिनिकल वर्कस्टेशन';
  @override
  String get standbySubheadline =>
      'सुरक्षित ओपीडी परामर्श, मरीज टेलीमेट्री एवं इलेक्ट्रॉनिक स्वास्थ्य प्रलेखन';
  @override
  String get loginButtonLabel => 'डॉक्टर लॉगिन';
  @override
  String get loginTooltip => 'साइन इन करने के लिए क्लिक करें या एंटर दबाएं';
  @override
  String get terminalReady => 'वर्कस्टेशन तैयार है';
  @override
  String get secureSessionNotice =>
      'केवल अधिकृत चिकित्सकों हेतु • अस्पताल नेटवर्क द्वारा सुरक्षित';
  @override
  String get switchToKiosk => 'कियोस्क टर्मिनल पर जाएं';

  // Doctor Login Screen (Phase D2)
  @override
  String get doctorLoginTitle => 'डॉक्टर लॉगिन';
  @override
  String get doctorLoginSubtitle => 'अपने क्लिनिकल वर्कस्टेशन तक सुरक्षित पहुंच';
  @override
  String get doctorUniqueCode => 'डॉक्टर यूनिक कोड';
  @override
  String get doctorUniqueCodeHint => 'अपना निर्दिष्ट डॉक्टर कोड दर्ज करें';
  @override
  String get password => 'पासवर्ड';
  @override
  String get passwordHint => 'वर्कस्टेशन पासवर्ड दर्ज करें';
  @override
  String get loginButton => 'लॉगिन';
  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';
  @override
  String get forgotPasswordTitle => 'वर्कस्टेशन क्रेडेंशियल पुनर्प्राप्ति';
  @override
  String get forgotPasswordNotice =>
      'डॉक्टर खाते अस्पताल आईटी प्रशासन द्वारा बनाए और प्रबंधित किए जाते हैं। कृपया क्रेडेंशियल पुनर्प्राप्ति हेतु अस्पताल प्रशासक या आईटी हेल्पडेस्क से संपर्क करें।';

  // OTP Verification Screen (Phase D2)
  @override
  String get otpVerificationTitle => 'ओटीपी सत्यापन';
  @override
  String get otpVerificationSubtitle =>
      'अपने पंजीकृत मोबाइल नंबर पर भेजा गया सत्यापन कोड दर्ज करें।';
  @override
  String get otpSentTo => 'ओटीपी भेजा गया';
  @override
  String get enterOtp => 'ओटीपी दर्ज करें';
  @override
  String get enterSixDigitOtp => '6 अंकों का ओटीपी दर्ज करें';
  @override
  String get verifyOtpButton => 'ओटीपी सत्यापित करें';
  @override
  String get resendOtpButton => 'ओटीपी पुनः भेजें';
  @override
  String resendOtpCooldown(int seconds) => '$seconds सेकंड में पुनः भेजें';
  @override
  String get otpResentNotice => 'एक नया सत्यापन कोड भेज दिया गया है।';

  // Validation & Error Messages (Phase D2 & D3)
  @override
  String get invalidLoginDetails => 'अमान्य लॉगिन विवरण।';
  @override
  String get invalidOtp => 'अमान्य ओटीपी। कृपया पुनः प्रयास करें।';
  @override
  String get emptyDoctorCodeError => 'कृपया अपना डॉक्टर यूनिक कोड दर्ज करें।';
  @override
  String get emptyPasswordError => 'कृपया अपना पासवर्ड दर्ज करें।';
  @override
  String get invalidOtpFormatError => 'कृपया 6 अंकों का ओटीपी दर्ज करें।';
  @override
  String get inactiveDoctorError =>
      'आपका डॉक्टर खाता वर्तमान में निष्क्रिय है। कृपया अस्पताल प्रशासन से संपर्क करें।';
  @override
  String get serverConnectionError =>
      'क्लिनिकल सर्वर से कनेक्ट करने में असमर्थ। कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';
  @override
  String get authFailedError =>
      'प्रमाणीकरण पूरा नहीं हो सका। कृपया पुनः प्रयास करें।';

  // Doctor Profile & Workstation Availability (Phase D4)
  @override
  String get doctorProfileTitle => 'डॉक्टर प्रोफाइल';
  @override
  String get qualificationLabel => 'योग्यता';
  @override
  String get departmentLabel => 'विभाग';
  @override
  String get doctorUniqueCodeLabel => 'डॉक्टर यूनिक कोड';
  @override
  String get registeredPhoneLabel => 'पंजीकृत फोन';
  @override
  String get accountStatusLabel => 'खाता स्थिति';
  @override
  String get activeStatus => 'सक्रिय';
  @override
  String get inactiveStatus => 'निष्क्रिय';
  @override
  String get availabilityLabel => 'उपलब्धता';
  @override
  String get goOnlineButton => 'ऑनलाइन जाएं';
  @override
  String get goOfflineButton => 'ऑफ़लाइन जाएं';
  @override
  String get readyForPatients => 'मरीजों के लिए तैयार';
  @override
  String get currentlyInConsultation => 'वर्तमान में परामर्श में';
  @override
  String get profileManagedByAdminNotice =>
      'डॉक्टर प्रोफ़ाइल डेटा विशेष रूप से अस्पताल प्रशासन द्वारा प्रबंधित किया जाता है। अपडेट के लिए आईटी प्रशासन से संपर्क करें।';
  @override
  String get viewDoctorProfile => 'डॉक्टर प्रोफाइल देखें';
  @override
  String get workstationAvailability => 'वर्कस्टेशन उपलब्धता';

  // Patient Requests (Phase D5)
  @override
  String get patientRequestsTitle => 'मरीज़ अनुरोध';
  @override
  String get patientRequestsSubtitle =>
      'आपके विभाग के लिए आने वाले ओपीडी परामर्श अनुरोध';
  @override
  String get pendingRequestsCountLabel => 'लंबित अनुरोध';
  @override
  String get queueNumberLabel => 'कतार संख्या';
  @override
  String get ageLabel => 'आयु';
  @override
  String get genderLabel => 'लिंग';
  @override
  String get domainLabel => 'विभाग';
  @override
  String get requestTypeLabel => 'अनुरोध प्रकार';
  @override
  String get newVisitLabel => 'नई यात्रा';
  @override
  String get previousDoctorRequestedLabel => 'पिछले डॉक्टर का अनुरोध';
  @override
  String get vitalsLabel => 'वाइटल्स';
  @override
  String get spo2Label => 'SpO₂';
  @override
  String get heartRateLabel => 'हृदय गति';
  @override
  String get temperatureLabel => 'तापमान';
  @override
  String get waitingStatusLabel => 'प्रतीक्षारत';
  @override
  String get noPatientRequestsTitle => 'कोई मरीज़ अनुरोध नहीं';
  @override
  String get noPatientRequestsSubtitle =>
      'वर्तमान में आपके विभाग के लिए कोई प्रतीक्षारत ओपीडी अनुरोध नहीं हैं।';
  @override
  String get refreshRequestsButton => 'अनुरोध रीफ़्रेश करें';
  @override
  String get unableToLoadRequestsTitle => 'मरीज़ अनुरोध लोड करने में असमर्थ।';
  @override
  String get acceptRequestButton => 'अनुरोध स्वीकारें';
  @override
  String get assignmentD6Notice =>
      'मरीज़ आवंटन चरण D6 में सक्षम किया जाएगा।';
  @override
  String get notAvailableLabel => 'उपलब्ध नहीं';
  @override
  String get workstationOfflineNotice =>
      'वर्कस्टेशन ऑफ़लाइन है। ओपीडी अनुरोध स्वीकार करने के लिए स्थिति उपलब्ध पर सेट करें।';
  @override
  String get workstationInConsultationNotice =>
      'वर्तमान में परामर्श जारी है। नए अनुरोध स्वीकार करने से पहले सक्रिय परामर्श पूरा करें।';

  // Request Acceptance & Assignment (Phase D6)
  @override
  String get acceptingRequest => 'अनुरोध स्वीकार किया जा रहा है...';
  @override
  String get patientAcceptedNotice =>
      'मरीज़ अनुरोध सफलतापूर्वक स्वीकार कर लिया गया।';
  @override
  String get patientAlreadyAssignedNotice =>
      'मरीज़ का अनुरोध पहले ही किसी अन्य डॉक्टर को सौंपा जा चुका है।';
  @override
  String get notEligibleNotice =>
      'आप इस अनुरोध के लिए पात्र नहीं हैं।';
  @override
  String get doctorNotAvailableNotice =>
      'वर्कस्टेशन परामर्श के लिए उपलब्ध नहीं है।';
  @override
  String get unableToAcceptNotice =>
      'इस मरीज़ के अनुरोध को स्वीकार करने में असमर्थ। कृपया पुनः प्रयास करें।';
  @override
  String get openingWorkspaceNotice => 'मरीज़ वर्कस्पेस खोला जा रहा है...';

  // Transitions & Success
  @override
  String get authSuccessTitle => 'प्रमाणीकरण सफल';
  @override
  String get authSuccessSubtitle => 'क्लिनिकल वर्कस्टेशन खोला जा रहा है...';

  @override
  String get back => 'वापस';
  @override
  String get close => 'बंद करें';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get save => 'सहेजें';
  @override
  String get proceed => 'आगे बढ़ें';

  // Patient Workspace & Clinical Records (Phase D7)
  @override
  String get patientWorkspaceTitle => 'मरीज़ वर्कस्पेस';
  @override
  String get patientInformation => 'मरीज़ की जानकारी';
  @override
  String get patientNameLabel => 'मरीज़ का नाम';
  @override
  String get patientIdLabel => 'मरीज़ आईडी';
  @override
  String get bloodGroupLabel => 'रक्त समूह';
  @override
  String get currentVitals => 'वर्तमान वाइटल्स';
  @override
  String get historicalVitals => 'ऐतिहासिक वाइटल्स';
  @override
  String get clinicalRecords => 'क्लिनिकल रिकॉर्ड्स';
  @override
  String get cases => 'केस';
  @override
  String get visits => 'विज़िट';
  @override
  String get myCases => 'मेरे केस';
  @override
  String get startNewCase => 'नया केस शुरू करें';
  @override
  String get addVisit => 'विज़िट जोड़ें';
  @override
  String get caseDomainLabel => 'केस विभाग';
  @override
  String get caseTitleLabel => 'केस शीर्षक / कारण';
  @override
  String get caseTitleHint => 'उदा. उच्च रक्तचाप और सीने में तकलीफ';
  @override
  String get openCase => 'खुला';
  @override
  String get closedCase => 'बंद';
  @override
  String get visit => 'विज़िट';
  @override
  String get activeStatusLabel => 'सक्रिय';
  @override
  String get completedStatusLabel => 'पूर्ण';
  @override
  String get cancelledStatusLabel => 'रद्द';
  @override
  String get attendingDoctorLabel => 'उपस्थित डॉक्टर';
  @override
  String get visitStartedAtLabel => 'प्रारंभ समय';
  @override
  String get selectCasePrompt => 'परामर्श विज़िट देखने के लिए केस का चयन करें।';
  @override
  String get noCasesFound => 'इस मरीज़ के लिए कोई क्लिनिकल केस नहीं मिला।';
  @override
  String get noVisitsFound => 'इस केस के लिए कोई विज़िट दर्ज नहीं है।';
  @override
  String get clinicalDocumentationNotice =>
      'परामर्श के बाद क्लिनिकल दस्तावेज़ीकरण दिखाई देगा।';
  @override
  String get consultationWorkspacePlaceholder =>
      'परामर्श दस्तावेज़ीकरण वर्कस्पेस चरण D8 में उपलब्ध होगा।';
  @override
  String get reportsTitle => 'रिपोर्ट एवं डायग्नोस्टिक्स';
  @override
  String get availableReportsTab => 'उपलब्ध रिपोर्ट';
  @override
  String get requestedReportsTab => 'अनुरोधित रिपोर्ट';
  @override
  String get uploadedReportsTab => 'अपलोड की गई रिपोर्ट';
  @override
  String get noReportsFound => 'कोई डायग्नोस्टिक रिपोर्ट नहीं मिली।';
  @override
  String get transferPatientButton => 'मरीज स्थानांतरित करें';
  @override
  String get completeVisitButton => 'विज़िट पूर्ण करें';
  @override
  String get notAvailable => 'उपलब्ध नहीं';
  @override
  String get loadingPatientWorkspace => 'मरीज़ वर्कस्पेस लोड हो रहा है...';
  @override
  String get patientNotFound => 'मरीज़ की जानकारी लोड नहीं हो सकी।';
  @override
  String get unauthorizedAccess =>
      'आप इस मरीज़ वर्कस्पेस तक पहुँचने के लिए अधिकृत नहीं हैं।';
  @override
  String get unableToLoadClinicalRecords =>
      'क्लिनिकल रिकॉर्ड लोड करने में असमर्थ। कृपया पुनः प्रयास करें।';
  @override
  String get consultationInProgressTitle => 'परामर्श प्रगति पर है';
  @override
  String get consultationInProgressNotice =>
      'परामर्श वर्तमान में प्रगति पर है। क्या आप वाकई वर्कस्पेस छोड़ना चाहते हैं?';
  @override
  String get stayButton => 'रहें';
  @override
  String get leaveWorkspaceButton => 'वर्कस्पेस छोड़ें';
  @override
  String get previousDoctorRequestBadge => 'पूर्व डॉक्टर का अनुरोध';

  // Phase D8: Live Doctor Consultation & Clinical Documentation
  @override
  String get visitIdentification => 'विज़िट पहचान';
  @override
  String get vitalsAtConsultation => 'परामर्श समय के वाइटल्स';
  @override
  String get caseInformation => 'केस की जानकारी';
  @override
  String get caseTypeLabel => 'केस प्रकार';
  @override
  String get newCase => 'नया केस';
  @override
  String get existingCase => 'मौजूदा केस';
  @override
  String get caseStatusLabel => 'केस स्थिति';
  @override
  String get ongoingStatus => 'प्रगति पर';
  @override
  String get closedStatus => 'बंद';
  @override
  String get previousRelevantHistoryLabel => 'पिछला प्रासंगिक इतिहास';
  @override
  String get previousRelevantHistoryHint =>
      'इस केस के लिए प्रासंगिक चिकित्सा, शल्य चिकित्सा या पारिवारिक इतिहास दर्ज करें...';
  @override
  String get structuredConsultation => 'संरचित परामर्श';
  @override
  String get chiefComplaint => 'मुख्य शिकायत';
  @override
  String get chiefComplaintHint =>
      'मरीज़ के अपने शब्दों में आने का प्राथमिक कारण...';
  @override
  String get onsetDuration => 'शुरुआत / अवधि';
  @override
  String get onsetDurationHint =>
      'उदा. 3 दिन, अचानक शुरुआत, कल से बढ़ रहा है...';
  @override
  String get associatedSymptoms => 'संबंधित लक्षण';
  @override
  String get associatedSymptomsHint =>
      'उदा. बुखार, फैलता दर्द, मतली, चक्कर आना...';
  @override
  String get medicalHistory => 'चिकित्सा इतिहास';
  @override
  String get medicalHistoryHint =>
      'पिछली बीमारियाँ, एलर्जी, सर्जरी का इतिहास...';
  @override
  String get currentMedication => 'वर्तमान दवाएं';
  @override
  String get currentMedicationHint =>
      'सक्रिय दवाएं, ओवर-द-काउंटर दवाएं, खुराक...';
  @override
  String get clinicalObservations => 'क्लिनिकल अवलोकन';
  @override
  String get clinicalObservationsHint =>
      'शारीरिक परीक्षण के निष्कर्ष, स्टेथ पहचान, स्पर्श परीक्षण...';
  @override
  String get assessment => 'मूल्यांकन / निदान';
  @override
  String get assessmentHint =>
      'क्लिनिकल नैदानिक धारणा, विभेदक निदान...';
  @override
  String get plan => 'उपचार योजना';
  @override
  String get planHint =>
      'उपचार रणनीति, जांच, तत्काल प्रबंधन...';
  @override
  String get doctorApprovedSummary => 'डॉक्टर द्वारा स्वीकृत विज़िट सारांश';
  @override
  String get summaryLabel => 'विज़िट सारांश';
  @override
  String get summaryHint =>
      'डॉक्टर द्वारा समीक्षा और स्वीकृत किए जाने वाले सारांश को दर्ज करें...';
  @override
  String get summaryStatusLabel => 'सारांश स्थिति';
  @override
  String get summaryDraftStatus => 'प्रारूप';
  @override
  String get summaryReviewRequiredStatus => 'समीक्षा आवश्यक';
  @override
  String get summaryApprovedStatus => 'डॉक्टर द्वारा स्वीकृत';
  @override
  String get approveSummaryButton => 'सारांश स्वीकृत करें';
  @override
  String get summaryApprovedNotice =>
      'उपचार करने वाले डॉक्टर द्वारा विज़िट सारांश स्वीकृत किया गया।';
  @override
  String get summaryEditWarning =>
      'सारांश संपादित किया गया था। पुनः स्वीकृति आवश्यक है।';
  @override
  String get reportsRequested => 'अनुरोधित रिपोर्ट एवं जांच';
  @override
  String get addInvestigationButton => '+ रिपोर्ट / जांच जोड़ें';
  @override
  String get investigationNameLabel => 'रिपोर्ट / जांच का नाम';
  @override
  String get investigationNameHint =>
      'उदा. 12-लीड ईसीजी, पूर्ण रक्त गणना (सीबीसी), छाती का एक्स-रे';
  @override
  String get priorityLabel => 'प्राथमिकता';
  @override
  String get requiredPriority => 'आवश्यक';
  @override
  String get asAdvisedPriority => 'सलाह अनुसार';
  @override
  String get pendingUploadStatus => 'अपलोड लंबित';
  @override
  String get uploadedStatus => 'अपलोड किया गया';
  @override
  String get reviewedStatus => 'समीक्षित';
  @override
  String get planFollowUp => 'योजना / अनुवर्ती परामर्श';
  @override
  String get followUpLabel => 'अनुवर्ती परामर्श';
  @override
  String get followUpHint =>
      'उदा. 2 सप्ताह में समीक्षा या लक्षण बढ़ने पर तुरंत आएं...';
  @override
  String get patientInstructionsLabel => 'मरीज़ निर्देश';
  @override
  String get patientInstructionsHint =>
      'आहार सलाह, गतिविधि सावधानियां, जीवनशैली मार्गदर्शन...';
  @override
  String get visitCompletion => 'विज़िट पूर्णता';
  @override
  String get saveDraftButton => 'प्रारूप सहेजें';
  @override
  String get draftSavedNotice =>
      'परामर्श प्रारूप सफलतापूर्वक सहेजा गया।';
  @override
  String get visitCompletedTitle => 'विज़िट पूर्ण';
  @override
  String get visitCompletedSuccess =>
      'विज़िट सफलतापूर्वक पूर्ण हुई। केस जारी है।';
  @override
  String get caseOngoingNotice => 'केस जारी है।';
  @override
  String get incompleteFieldsError =>
      'कृपया सभी आवश्यक परामर्श फ़ील्ड पूर्ण करें और सारांश स्वीकृत करें।';
  @override
  String get missingRequirementsTitle => 'अपूर्ण परामर्श आवश्यकताएं';
  @override
  String get consultationInProgress => 'परामर्श प्रगति पर है';
  @override
  String get savingDraft => 'प्रारूप सहेजा जा रहा है...';
  @override
  String get completingVisit => 'विज़िट पूर्ण की जा रही है...';
  @override
  String get treatingDoctor => 'उपचार करने वाले डॉक्टर';
  @override
  String get doctorQualification => 'डॉक्टर की योग्यता';
  @override
  String get consultationTimestamp => 'दिनांक / समय';
  @override
  @override
  String get statusActive => 'सक्रिय';
  @override
  String get noInvestigationsRequested =>
      'अभी तक कोई रिपोर्ट या जांच का अनुरोध नहीं किया गया है।';

  // Phase D9: Speech-to-Text Consultation Assistant
  @override
  String get speechToText => 'भाषण से पाठ';
  @override
  String get dictateField => 'इस फ़ील्ड में बोलकर लिखें';
  @override
  String get startDictation => 'बोलना शुरू करें';
  @override
  String get stopDictation => 'रोकें और जोड़ें';
  @override
  String get cancelDictation => 'रद्द करें';
  @override
  String get recordingActive => 'रिकॉर्डिंग सक्रिय...';
  @override
  String get listeningToSpeech => 'सुन रहे हैं...';
  @override
  String get processingSpeech => 'ऑडियो संसाधित किया जा रहा है...';
  @override
  String get speechErrorTitle => 'भाषण पहचान त्रुटि';
  @override
  String get micPermissionDenied =>
      'भाषण प्रतिलेखन हेतु माइक्रोफ़ोन अनुमति आवश्यक है। कृपया अनुमति जांचें।';
  @override
  String get speechEngineUnavailable =>
      'इस वर्कस्टेशन पर भाषण पहचान सेवा उपलब्ध नहीं है।';
  @override
  String get appendOrReplaceTitle => 'फ़ील्ड में मौजूदा टेक्स्ट';
  @override
  String get appendOrReplacePrompt =>
      'इस फ़ील्ड में पहले से नोट्स हैं। क्या आप नया टेक्स्ट जोड़ना चाहते हैं या बदलना चाहते हैं?';
  @override
  String get appendButton => 'जोड़ें';
  @override
  String get replaceButton => 'बदलें';
  @override
  String get transcriptionSuccess => 'टेक्स्ट फ़ील्ड में जोड़ा गया।';
  @override
  String get micHardwareNotFound =>
      'कोई माइक्रोफ़ोन नहीं मिला। कृपया इनपुट डिवाइस कनेक्ट करें।';
  @override
  String get noSpeechDetected =>
      'कोई आवाज़ नहीं पहचानी गई। कृपया स्पष्ट बोलें।';

  // Phase D9.1: Prescription Module & Unified Dictation (Hindi)
  @override
  String get prescription => 'प्रिस्क्रिप्शन / औषधोपचार';
  @override
  String get prescriptionSectionTitle => 'प्रिस्क्रिप्शन / औषधोपचार';
  @override
  String get numberOfMedicines => 'दवाइयों की संख्या';
  @override
  String get createPrescription => 'प्रिस्क्रिप्शन बनाएं';
  @override
  String get addMedicine => '+ दवाई जोड़ें';
  @override
  String get removeMedicine => 'हटाएं';
  @override
  String get dictatePrescription => 'प्रिस्क्रिप्शन बोलें';
  @override
  String get prescriptionTranscript => 'प्रिस्क्रिप्शन ट्रांसक्रिप्ट';
  @override
  String get useInPrescription => 'प्रिस्क्रिप्शन में उपयोग करें';
  @override
  String get addToExistingPrescription => 'मौजूदा में जोड़ें';
  @override
  String get replacePrescription => 'प्रिस्क्रिप्शन बदलें';
  @override
  String get cancelPrescriptionDictation => 'रद्द करें';
  @override
  String get incompletePrescription => 'अपूर्ण प्रिस्क्रिप्शन';
  @override
  String get srNo => 'क्र. सं.';
  @override
  String get medicineName => 'दवाई का नाम';
  @override
  String get duration => 'अवधि';
  @override
  String get timesADay => 'दिन में कितनी बार';
  @override
  String get remarks => 'टिप्पणी / निर्देश';
  @override
  String get medicineNameHint => 'उदा. पैरासिटामोल 500 मिलीग्राम';
  @override
  String get durationHint => 'उदा. 5 दिन';
  @override
  String get timesADayHint => 'उदा. 2';
  @override
  String get remarksHint => 'उदा. भोजन के बाद';
  @override
  String get enterNumberOfMedicinesPrompt =>
      'इस प्रिस्क्रिप्शन के लिए आवश्यक दवाइयों की संख्या दर्ज करें।';
  @override
  String get noMedicinesAddedNotice =>
      'अभी तक कोई दवाई नहीं जोड़ी गई। दवाइयों की संख्या दर्ज करें या बोलें।';

  // Phase D10: Gemini Documentation Assistant (Hindi)
  @override
  String get doctorAssistedDocumentation => 'डॉक्टर-सहायता प्राप्त दस्तावेज़ीकरण';
  @override
  String get generateDraftSummary => 'प्रारूप सारांश तैयार करें';
  @override
  String get regenerateDraftSummary => 'पुनः प्रारूप तैयार करें';
  @override
  String get aiPreparingDocumentation => 'एआई दस्तावेज़ीकरण प्रारूप तैयार कर रहा है...';
  @override
  String get aiDraftDisclaimer =>
      'एआई द्वारा तैयार दस्तावेज़ केवल एक प्रारूप है। डॉक्टर की समीक्षा और मंजूरी अनिवार्य है।';
  @override
  String get regenerateWarningTitle => 'क्या आप नया प्रारूप तैयार करना चाहते हैं?';
  @override
  String get regenerateWarningPrompt =>
      'पुनः तैयार करने पर वर्तमान सारांश नए एआई प्रारूप से बदल दिया जाएगा। आपके द्वारा किए गए संपादन मिट सकते हैं।';
  @override
  String get regenerateButton => 'पुनः तैयार करें';
  @override
  String get documentationUnavailable =>
      'दस्तावेज़ीकरण सहायता अस्थायी रूप से अनुपलब्ध है। आपका परामर्श डेटा सुरक्षित है।';
  @override
  String get completeMandatoryFieldsPrompt =>
      'प्रारूप सारांश के लिए सभी 8 आवश्यक परामर्श फ़ील्ड भरें।';
  // Phase D9.2: Gemini Speech Transcript Cleanup Assistant (Hindi)
  @override
  String get voiceTranscriptReviewTitle => 'वॉयस ट्रांसक्रिप्ट समीक्षा';
  @override
  String get originalTranscriptLabel => 'मूल ट्रांसक्रिप्ट (स्पीच-टू-टेक्स्ट)';
  @override
  String get geminiCleanedDraftLabel => 'एआई संशोधित ट्रांसक्रिप्ट प्रारूप';
  @override
  String get useCleanedVersion => 'संशोधित संस्करण उपयोग करें';
  @override
  String get useOriginal => 'मूल ट्रांसक्रिप्ट उपयोग करें';
  @override
  String get editManually => 'संपादित करें';
  @override
  String get doneEditing => 'संपादन पूर्ण';
  @override
  String get cleanAgain => 'पुनः संशोधित करें';
  @override
  String get cleanAgainTitle => 'क्या नया प्रारूप संशोधित करना चाहते हैं?';
  @override
  String get cleanAgainPrompt =>
      'मूल ट्रांसक्रिप्ट से नया संशोधित प्रारूप तैयार करें? आपके वर्तमान संपादन मिट जाएंगे।';
  @override
  String get cleanAgainConfirm => 'पुनः संशोधित करें';
  @override
  String get aiDraftNotice =>
      'एआई संशोधन केवल एक प्रारूप है। कृपया स्वीकार करने से पूर्व जांच करें।';
  @override
  String get aiCleaningInProgress => 'एआई ट्रांसक्रिप्ट को संशोधित कर रहा है...';
  @override
  String get cleanupUnavailable =>
      'एआई संशोधन उपलब्ध नहीं है। आप मूल ट्रांसक्रिप्ट का उपयोग कर सकते हैं या इसे मैन्युअल रूप से संपादित कर सकते हैं।';
  @override
  String get transcriptTooLong =>
      'ट्रांसक्रिप्ट एआई संशोधन के लिए अत्यधिक लंबी है। कृपया संपादन करें।';
  @override
  String get unclearPhraseWarning => 'अस्पष्ट वाक्यांश पाया गया — कृपया जांच करें।';
  @override
  String get editModeNotice => 'संपादन मोड सक्रिय है। बदलाव करें और स्वीकारें।';
  @override
  String get aiAssistedBadge => 'एआई सहायक';
  @override
  String get devModeBadge => 'डेव मोड';

  // Phase D11: Reports, Investigations & Visit PDF
  @override
  String get investigationCategoryLabel => 'श्रेणी';
  @override
  String get labCategory => 'प्रयोगशाला';
  @override
  String get radiologyCategory => 'रेडियोलॉजी';
  @override
  String get diagnosticCategory => 'नैदानिक';
  @override
  String get otherCategory => 'अन्य';
  @override
  String get requestInvestigationButton => '+ जांच का अनुरोध करें';
  @override
  String get requestInvestigationDialogTitle => 'नैदानिक जांच का अनुरोध';
  @override
  String get reportsReviewTitle => 'डॉक्टर रिपोर्ट एवं निदान';
  @override
  String get tabRequested => 'अनुरोधित';
  @override
  String get tabUploaded => 'अपलोड किए गए (समीक्षा बाकी)';
  @override
  String get tabReviewed => 'समीक्षित';
  @override
  String get markAsReviewedButton => 'समीक्षित चिह्नित करें';
  @override
  String get reportReviewedNotice => 'रिपोर्ट को उपस्थित डॉक्टर द्वारा समीक्षित चिह्नित किया गया।';
  @override
  String get noReportsInTab => 'इस अनुभाग में कोई रिपोर्ट नहीं है।';
  @override
  String get viewReportButton => 'रिपोर्ट देखें';
  @override
  String get uploadReportButton => 'रिपोर्ट अपलोड करें';
  @override
  String get previewVisitReportButton => 'विज़िट रिपोर्ट पूर्वावलोकन';
  @override
  String get visitReportPreviewTitle => 'आयुसाथी — केस एवं विज़िट दस्तावेज़ीकरण (प्रारूप)';
  @override
  String get generatePdfButton => 'विज़िट PDF बनाएं';
  @override
  String get printPdfButton => 'PDF प्रिंट / निर्यात करें';
  @override
  String get pdfGatingWarning =>
      'रिपोर्ट तैयार करने से पहले सभी आवश्यक परामर्श फ़ील्ड भरें और विज़िट सारांश को स्वीकृत करें।';
  @override
  String get pdfGeneratedSuccess => 'आधिकारिक आयुसाथी विज़िट रिपोर्ट PDF सफलतापूर्वक तैयार की गई।';

  // Phase D11.1: PDF Output, Open & Save As (Hindi)
  @override
  String get pdfCreatedSuccessTitle => 'विज़िट रिपोर्ट PDF तैयार';
  @override
  String get openPdfButton => 'PDF खोलें';
  @override
  String get saveAsButton => 'इस रूप में सहेजें';
  @override
  String get pdfLocationLabel => 'सहेजा गया स्थान';
  @override
  String get pdfOpenError => 'PDF तैयार हुई, लेकिन विंडोज़ फ़ाइल नहीं खोल सका।';
  @override
  String get pdfSaveAsSuccess => 'PDF प्रतिलिपि सफलतापूर्वक सहेजी गई।';
  @override
  String get pdfSaveAsCancelled => 'सहेजने की प्रक्रिया रद्द की गई।';
  @override
  String get pdfSavedToDesktopNotice => 'रिपोर्ट PDF प्रतिलिपि आपके डेस्कटॉप पर सहेज दी गई है।';

  // Phase D12: Visit Completion, Case Lifecycle & Doctor Workflow Finalization (Hindi)
  @override
  String get completeVisitDialogTitle => 'परामर्श पूर्ण करें';
  @override
  String get completeVisitExplanation =>
      'इस विज़िट को पूरा करने से यह परामर्श संपन्न दर्ज हो जाएगा। केस भविष्य की विज़िट्स के लिए खुला रहेगा जब तक इसे बाद में स्पष्ट रूप से बंद न किया जाए।';
  @override
  String get prerequisitesChecklistTitle => 'इस विज़िट को पूरा करने से पहले पुष्टि करें:';
  @override
  String get consultationDocsCompleteCheck =>
      'आवश्यक परामर्श दस्तावेज़ीकरण पूर्ण (8 फ़ील्ड)';
  @override
  String get summaryApprovedCheck => 'डॉक्टर-स्वीकृत सारांश उपलब्ध';
  @override
  String get investigationsRecordedCheck => 'रिपोर्ट्स / जांचें दर्ज की गईं';
  @override
  String get pdfGeneratedCheck => 'विज़िट रिपोर्ट तैयार';
  @override
  String get caseRemainsOpenNote =>
      'नोट: इस विज़िट को पूरा करने से केस बंद नहीं होता है।';
  @override
  String get doctorDeclarationCheckbox =>
      'मैं पुष्टि करता/करती हूँ कि मैंने इस परामर्श के दस्तावेज़ीकरण की समीक्षा और इसे पूरा कर लिया है।';
  @override
  String get doctorDeclarationText =>
      'मैं पुष्टि करता/करती हूँ कि इस परामर्श का दस्तावेज़ीकरण पूर्ण है और इस विज़िट को संपन्न के रूप में चिह्नित किया जा सकता है।';
  @override
  String get completeVisitSubmitButton => 'विज़िट पूर्ण करें';
  @override
  String get visitCompletedSuccessTitle => 'विज़िट सफलतापूर्वक संपन्न';
  @override
  String get visitCompletedSuccessSubtitle =>
      'परामर्श सत्र संपन्न हो गया है। मरीज़ का केस खुला (OPEN) रहेगा।';
  @override
  String get historicalVisitReadOnlyTitle => 'पिछली विज़िट का विवरण (केवल पढ़ने हेतु)';
  @override
  String get historicalVisitNotice =>
      'यह पूर्ण विज़िट रिकॉर्ड संग्रहीत और केवल पढ़ने योग्य है।';
  @override
  String get viewVisitDetailsButton => 'विज़िट देखें';
  @override
  String get continueExistingCaseButton => '+ नई विज़िट';
  @override
  String get newVisitCreatedNotice =>
      'इस जारी केस के लिए नई सक्रिय विज़िट शुरू की गई।';
  @override
  String get visitCompletionFailedNotice =>
      'इस विज़िट को पूरा करने में असमर्थ। कृपया पुनः प्रयास करें।';
  @override
  String get caseStatusOpenBadge => 'खुला (जारी)';
  @override
  String get caseStatusClosedBadge => 'बंद';
  @override
  String get completedAtLabel => 'संपन्न समय';
  @override
  String get backToDashboardButton => 'डैशबोर्ड पर लौटें';

  // Phase D13: Doctor Transfer & Inter-Department Referral (Hindi)
  @override
  String get transferPatientTitle => 'मरीज स्थानांतरण';
  @override
  String get transferPatientSubtitle =>
      'विशेषज्ञ मूल्यांकन के लिए मरीज को दूसरे चिकित्सा विभाग में रेफर करें।';
  @override
  String get transferPatientDialogSubtitle =>
      'गंतव्य ओपीडी विभाग का चयन करें और स्थानांतरण का क्लिनिकल कारण बताएं।';
  @override
  String get continueButton => 'आगे बढ़ें';
  @override
  String get reviewTransferButton => 'स्थानांतरण की समीक्षा करें';
  @override
  String get selectDestinationDepartment => 'गंतव्य विभाग चुनें';
  @override
  String get currentDepartmentLabel => 'वर्तमान विभाग';
  @override
  String get destinationDepartmentLabel => 'गंतव्य विभाग';
  @override
  String get transferReasonLabel => 'स्थानांतरण / रेफरल का कारण';
  @override
  String get transferReasonHint =>
      'स्थानांतरण का क्लिनिकल कारण दर्ज करें (उदा. न्यूरोलॉजिकल मूल्यांकन की आवश्यकता)...';
  @override
  String get transferReasonRequiredError => 'स्थानांतरण का कारण आवश्यक है।';
  @override
  String get transferReasonTooLongError =>
      'स्थानांतरण का कारण 1000 अक्षरों से अधिक नहीं हो सकता।';
  @override
  String get cannotTransferToSameDepartmentError =>
      'गंतव्य विभाग वर्तमान विभाग के समान नहीं हो सकता।';
  @override
  String get transferPreservesCaseNote =>
      'महत्वपूर्ण: ट्रांसफर से मरीज का मौजूदा केस और विज़िट इतिहास सुरक्षित रहेगा।';
  @override
  String get reviewTransferTitle => 'ट्रांसफर की समीक्षा करें';
  @override
  String get reviewTransferSubtitle =>
      'जमा करने से पहले अंतर-विभागीय मरीज रेफरल विवरण की पुष्टि करें।';
  @override
  String get confirmTransferButton => 'स्थानांतरण की पुष्टि करें';
  @override
  String get transferSubmittedSuccess =>
      'मरीज सफलतापूर्वक ट्रांसफर किया गया। डैशबोर्ड पर लौट रहे हैं...';
  @override
  String get transferFailedNotice =>
      'मरीज ट्रांसफर करने में विफल। कृपया पुनः प्रयास करें।';
  @override
  String get transferredFromBanner => 'से स्थानांतरित';
  @override
  String get transferRequestBadge => 'स्थानांतरण अनुरोध';
  @override
  String get fromDepartmentLabel => 'से';
  @override
  String get transferReasonCardLabel => 'कारण';
  @override
  String get cancelTransferTitle => 'स्थानांतरण रद्द करें?';
  @override
  String get cancelTransferConfirmation =>
      'क्या आप वाकई इस ट्रांसफर अनुरोध को रद्द करना चाहते हैं?';
  @override
  String get cancelTransferButton => 'स्थानांतरण रद्द करें';
  @override
  String get keepTransferButton => 'स्थानांतरण रखें';
  @override
  String get transferCancelledSuccess =>
      'ट्रांसफर अनुरोध सफलतापूर्वक रद्द किया गया।';
  @override
  String get transferAlreadyAcceptedNotice =>
      'यह ट्रांसफर अनुरोध पहले ही किसी अन्य डॉक्टर द्वारा स्वीकार कर लिया गया है।';
  @override
  String get awaitingTransferDoctorBadge => 'डॉक्टर की प्रतीक्षा';
  @override
  String get transferAssignedBadge => 'स्थानांतरण आवंटित';

  // Phase D14: Doctor Case Continuation & Follow-Up Workflow (Hindi)
  @override
  String get continueCaseButton => 'केस जारी रखें';
  @override
  String get viewHistoryButton => 'इतिहास देखें';
  @override
  String get caseTimelineTab => 'केस टाइमलाइन';
  @override
  String get visitHistoryTab => 'भेंट इतिहास';
  @override
  String get startNewVisitTitle => 'नई भेंट शुरू करें';
  @override
  String get startNewVisitSubtitle =>
      'इस मौजूदा केस के तहत एक नई परामर्श भेंट बनाई जाएगी।';
  @override
  String get startNewVisitButton => '+ नई भेंट';
  @override
  String get confirmStartNewVisitButton => 'नई भेंट शुरू करें';
  @override
  String get activeVisitExistsTitle => 'सक्रिय परामर्श मौजूद है';
  @override
  String get activeVisitExistsNotice =>
      'इस केस के लिए पहले से ही एक सक्रिय परामर्श भेंट मौजूद है।';
  @override
  String get returnToActiveVisitButton => 'परामर्श पर लौटें';
  @override
  String get caseInformationTitle => 'केस जानकारी';
  @override
  String get createdDateLabel => 'निर्माण तिथि';
  @override
  String get lastUpdatedLabel => 'अंतिम अद्यतन';
  @override
  String get caseTimeline => 'केस टाइमलाइन';
  @override
  String get timelineFilterAll => 'सभी';
  @override
  String get timelineFilterCompleted => 'पूर्ण';
  @override
  String get timelineFilterTransferred => 'स्थानांतरित';
  @override
  String get timelineFilterActive => 'सक्रिय';
  @override
  String get currentVitalsNotRecorded => 'वर्तमान वाइटल्स दर्ज नहीं हैं।';
  @override
  String get historicalVitalsLabel => 'ऐतिहासिक वाइटल्स';
  @override
  String get caseContinuedSuccess =>
      'मौजूदा केस जारी रखा गया। नई भेंट शुरू हुई।';
  @override
  String get openCasesTitle => 'सक्रिय केस';
  @override
  String get closedCasesTitle => 'बंद केस (केवल पढ़ने योग्य)';
  @override
  String get previousCaseHistoryTitle => 'पिछला केस इतिहास';

  // Phase D15: Doctor Case Closure, Standalone Cases & Diagnostics Desks
  @override
  String get closeCaseButton => 'केस बंद करें';
  @override
  String get closeCaseTitle => 'केस बंद करें';
  @override
  String get closeCaseSubtitle => 'मरीज़ के इस क्लिनिकल उपचार चक्र को समाप्त करें।';
  @override
  String get closeCaseExplanation =>
      'इस केस को बंद करने से पहले, पुष्टि करें कि इस केस से जुड़ी मरीज़ की स्थिति/समस्या का समाधान हो गया है या इस केस के तहत आगे किसी परामर्श की आवश्यकता नहीं है।';
  @override
  String get closeCaseDeclarationCheckbox =>
      'मैं पुष्टि करता/करती हूँ कि मैं इस केस को बंद कर रहा/रही हूँ क्योंकि इस केस से जुड़ी क्लिनिकल समस्या का समाधान हो गया है / उचित रूप से निष्कर्ष निकाला गया है।';
  @override
  String get closureDeclarationError => 'आपको केस समापन घोषणा चेकबॉक्स की पुष्टि करनी होगी।';
  @override
  String get closureNoteLabel => 'समापन नोट';
  @override
  String get closureNoteHint => 'डॉक्टर का समापन नोट / नैदानिक परिणाम दर्ज करें (अधिकतम 1,000 वर्ण)...';
  @override
  String get closureNoteRequiredError => 'समापन नोट आवश्यक है।';
  @override
  String get closureNoteTooLongError => 'समापन नोट 1,000 वर्णों से अधिक नहीं हो सकता।';
  @override
  String get activeVisitBlocksClosureError =>
      'इस केस को बंद करने से पहले सक्रिय भेंट को पूरा करें या स्थानांतरित करें।';
  @override
  String get pendingTransferBlocksClosureError =>
      'इस केस को बंद करने से पहले लंबित अंतर-विभागीय स्थानांतरण का समाधान होना चाहिए।';
  @override
  String get caseClosedSuccessTitle => 'केस बंद हो गया';
  @override
  String get caseClosedSuccessSubtitle =>
      'पिछली सभी भेंटें और क्लिनिकल रिकॉर्ड सुरक्षित रहेंगे।';
  @override
  String get closedByDoctorLabel => 'द्वारा बंद किया गया';
  @override
  String get closureDateLabel => 'तारीख';
  @override
  String get closureNoteCardLabel => 'समापन नोट';
  @override
  String get viewCaseHistoryButton => 'केस इतिहास देखें';
  @override
  String get closedCaseReadOnlyNotice =>
      'यह केस बंद और संग्रहीत है। सभी ऐतिहासिक भेंटें और दस्तावेज़ केवल पढ़ने योग्य हैं।';
  @override
  String get cannotAddVisitToClosedCase => 'बंद केस के तहत नई भेंट शुरू नहीं की जा सकती।';
  @override
  String get casesAndVisitsTitle => 'केस एवं क्लिनिकल भेंटें';
  @override
  String get casesAndVisitsSubtitle => 'ओपीडी अनुदैर्ध्य मरीज़ इतिहास';
  @override
  String get tabAllCases => 'सभी केस';
  @override
  String get tabOpenCases => 'सक्रिय केस';
  @override
  String get tabClosedCases => 'बंद केस';
  @override
  String get searchCasesHint => 'मरीज़ आईडी, केस आईडी या विभाग द्वारा खोजें...';
  @override
  String get openCaseButton => 'केस खोलें';
  @override
  String get noCasesInFilter => 'इस श्रेणी के लिए कोई क्लिनिकल केस नहीं मिला।';
  @override
  String get reportsAndDiagnosticsTitle => 'नैदानिक रिपोर्ट';
  @override
  String get reportsAndDiagnosticsSubtitle => 'लैब जांच एवं रेडियोलॉजी रिकॉर्ड';
  @override
  String get tabVisitReports => 'भेंट रिपोर्ट (PDF)';
  @override
  String get searchReportsHint => 'मरीज़ आईडी या जांच नाम द्वारा खोजें...';
  @override
  String get markReviewedSuccess => 'नैदानिक रिपोर्ट डॉक्टर द्वारा जांची गई के रूप में चिह्नित की गई।';
  @override
  String get officialVisitPdf => 'आधिकारिक भेंट रिपोर्ट PDF';
  @override
  String get caseClosedTimelineTitle => 'केस बंद';
  @override
  String get caseClosedTimelineBadge => 'केस बंद';
  @override
  String get createdLabel => 'निर्मित';
  @override
  String get unauthorizedCaseAccess =>
      'आप इस क्लिनिकल केस को देखने या एक्सेस करने के लिए अधिकृत नहीं हैं।';

  // Phase A8: Case Escalation (Hindi)
  @override
  String get escalateCaseButton => 'केस एस्केलेट करें';
  @override
  String get escalateCaseDialogTitle => 'उच्च प्राधिकारी समीक्षा का अनुरोध';
  @override
  String get escalateCaseDialogSubtitle => 'क्लिनिकल केस एस्केलेशन प्रोटोकॉल';
  @override
  String get escalationReasonPrompt =>
      'प्रशासनिक समीक्षा हेतु प्राथमिक क्लिनिकल कारण चुनें:';
  @override
  String get reasonClinicalDeterioration => 'क्लिनिकल गिरावट';
  @override
  String get reasonRepeatedVisits => 'बिना समाधान बार-बार विज़िट';
  @override
  String get reasonHigherAuthority => 'उच्च प्राधिकारी समीक्षा आवश्यक';
  @override
  String get reasonDoctorConcern => 'डॉक्टर चिंता / संदेह';
  @override
  String get reasonOther => 'अन्य';
  @override
  String get escalationNoteLabel => 'अतिरिक्त क्लिनिकल विवरण / कारण';
  @override
  String get escalationNoteHint =>
      'उच्च प्राधिकारी समीक्षा के लिए संक्षिप्त विवरण दर्ज करें...';
  @override
  String get escalationNoteRequiredError =>
      'अन्य का चयन करने पर कृपया स्पष्टीकरण प्रदान करें।';
  @override
  String get confirmEscalatePrompt =>
      'क्या आप इस केस को एडमिन समीक्षा के लिए एस्केलेट करना चाहते हैं?';
  @override
  String get confirmEscalateNotice =>
      'केस और वर्तमान परामर्श सक्रिय एवं खुले रहेंगे।';
  @override
  String get caseAlreadyEscalatedMessage =>
      'यह केस पहले से ही एडमिन समीक्षा के लिए एस्केलेट किया गया है।';
  @override
  String get caseEscalatedSuccess => 'केस एडमिन समीक्षा हेतु एस्केलेट किया गया।';
  @override
  String get escalating => 'एस्केलेट किया जा रहा है...';

  // Patient Uploaded Reports (Past Visits & Clinical Workspace)
  @override
  String get patientUploadedReportsHeader => 'मरीज़ द्वारा अपलोड की गई रिपोर्ट';
  @override
  String get noPatientReportsForVisit =>
      'इस विज़िट के लिए कोई मरीज़ रिपोर्ट अपलोड नहीं की गई।';
  @override
  String get waitingForPatientReport => 'मरीज़ की रिपोर्ट की प्रतीक्षा है।';
  @override
  String get aiSummarizeReportButton => 'एआई रिपोर्ट सारांश';
  @override
  String get aiSummaryTitle => 'एआई रिपोर्ट सारांश सहायक';
  @override
  String get aiSummaryNotice =>
      'एआई-जनित सारांश — डॉक्टर सत्यापन आवश्यक है।';
  @override
  String get aiSummaryDisclaimer =>
      'एआई मरीज़ का निदान या उपचार निर्धारित नहीं कर सकता।';
  @override
  String get unauthorizedReportAccess =>
      'आप इस मरीज़ विज़िट की रिपोर्ट देखने के लिए अधिकृत नहीं हैं।';
  @override
  String get analyzingReport => 'रिपोर्ट का विश्लेषण किया जा रहा है...';
  @override
  String get unableToSummarizeReport => 'इस रिपोर्ट का सारांश बनाने में असमर्थ।';
  @override
  String get unableToSummarizeReportTryAgain =>
      'इस रिपोर्ट का सारांश बनाने में असमर्थ। कृपया पुनः प्रयास करें।';
  @override
  String get reviewRequiredBadge => 'समीक्षा आवश्यक';
  @override
  String get approvedByDoctorBadge => 'डॉक्टर द्वारा स्वीकृत';
  @override
  String get editSummaryButton => 'सारांश संपादित करें';
  @override
  String get regenerateConfirmationTitle => 'क्या एआई सारांश पुनः उत्पन्न करें?';
  @override
  String get regenerateConfirmationMessage =>
      'पुनः उत्पन्न करने से स्वीकृत सारांश बदल जाएगा और स्थिति समीक्षा आवश्यक पर रीसेट हो जाएगी। क्या आप जारी रखना चाहते हैं?';
  @override
  String get reportOverviewHeader => '1. रिपोर्ट अवलोकन';
  @override
  String get keyFindingsHeader => '2. मुख्य निष्कर्ष';
  @override
  String get reportedMeasurementsHeader => '3. रिपोर्ट किए गए माप';
  @override
  String get reportedFindingsHeader => '4. रिपोर्ट किए गए निष्कर्ष';
  @override
  String get reportedImpressionHeader => '5. रिपोर्ट किया गया प्रभाव / निष्कर्ष';
  @override
  String get itemsToReviewHeader => '6. समीक्षा हेतु बिंदु';
  @override
  String get dataQualityHeader => '7. डेटा गुणवत्ता / अनिश्चितता';
  @override
  String get summarySavedNotice =>
      'एआई सारांश डॉक्टर द्वारा स्वीकृत और सहेजा गया।';
  @override
  String get saveChangesButton => 'बदलाव सहेजें';
}

/// Marathi localized string definitions for the AAYUSATHI Doctor Interface.
class DoctorStringsMarathi extends DoctorStrings {
  const DoctorStringsMarathi();

  @override
  String get doctorPortalTitle => 'डॉक्टर ओपीडी व्यवस्थापन प्रणाली';
  @override
  String get clinicalWorkstation => 'वैद्यकीय क्लिनिकल वर्कस्टेशन';
  @override
  String get doctorPortalBadge => 'डॉक्टर पोर्टल';
  @override
  String get hospitalWorkstation => 'ओपीडी क्लिनिकल डेस्क';

  @override
  String get standbyHeadline => 'डॉक्टर क्लिनिकल वर्कस्टेशन';
  @override
  String get standbySubheadline =>
      'सुरक्षित ओपीडी सल्लामसलत, रुग्ण टेलीमेट्री आणि इलेक्ट्रॉनिक आरोग्य नोंदी';
  @override
  String get loginButtonLabel => 'डॉक्टर लॉगिन';
  @override
  String get loginTooltip => 'साइन इन करण्यासाठी क्लिक करा किंवा एंटर दाबा';
  @override
  String get terminalReady => 'वर्कस्टेशन सज्ज आहे';
  @override
  String get secureSessionNotice =>
      'केवळ अधिकृत डॉक्टरांसाठी प्रवेश • रुग्णालय नेटवर्क सुरक्षित';
  @override
  String get switchToKiosk => 'किओस्क टर्मिनलवर जा';

  // Doctor Login Screen (Phase D2)
  @override
  String get doctorLoginTitle => 'डॉक्टर लॉगिन';
  @override
  String get doctorLoginSubtitle => 'आपल्या क्लिनिकल वर्कस्टेशनवर सुरक्षित प्रवेश';
  @override
  String get doctorUniqueCode => 'डॉक्टर युनिक कोड';
  @override
  String get doctorUniqueCodeHint => 'आपला नियुक्त केलेला डॉक्टर कोड प्रविष्ट करा';
  @override
  String get password => 'पासवर्ड';
  @override
  String get passwordHint => 'वर्कस्टेशन पासवर्ड प्रविष्ट करा';
  @override
  String get loginButton => 'लॉगिन';
  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';
  @override
  String get forgotPasswordTitle => 'वर्कस्टेशन क्रेडेंशियल पुनर्प्राप्ती';
  @override
  String get forgotPasswordNotice =>
      'डॉक्टर खाती रुग्णालय आयटी प्रशासनाकडून तयार आणि व्यवस्थापित केली जातात. कृपया क्रेडेंशियल पुनर्प्राप्तीसाठी रुग्णालय प्रशासक किंवा आयटी हेल्पडेस्कशी संपर्क साधा.';

  // OTP Verification Screen (Phase D2)
  @override
  String get otpVerificationTitle => 'ओटीपी पडताळणी';
  @override
  String get otpVerificationSubtitle =>
      'आपल्या नोंदणीकृत मोबाईल नंबरवर पाठवलेला पडताळणी कोड प्रविष्ट करा.';
  @override
  String get otpSentTo => 'ओटीपी पाठवला';
  @override
  String get enterOtp => 'ओटीपी प्रविष्ट करा';
  @override
  String get enterSixDigitOtp => '6-अंकी ओटीपी प्रविष्ट करा';
  @override
  String get verifyOtpButton => 'ओटीपी पडताळा';
  @override
  String get resendOtpButton => 'ओटीपी पुन्हा पाठवा';
  @override
  String resendOtpCooldown(int seconds) => '$seconds सेकंदात पुन्हा पाठवा';
  @override
  String get otpResentNotice => 'एक नवीन पडताळणी कोड पाठवला गेला आहे.';

  // Validation & Error Messages (Phase D2 & D3)
  @override
  String get invalidLoginDetails => 'अवैध लॉगिन तपशील.';
  @override
  String get invalidOtp => 'अवैध ओटीपी. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get emptyDoctorCodeError => 'कृपया आपला डॉक्टर युनिक कोड प्रविष्ट करा.';
  @override
  String get emptyPasswordError => 'कृपया आपला पासवर्ड प्रविष्ट करा.';
  @override
  String get invalidOtpFormatError => 'कृपया 6-अंकी ओटीपी प्रविष्ट करा.';
  @override
  String get inactiveDoctorError =>
      'आपले डॉक्टर खाते सध्या निष्क्रिय आहे. कृपया रुग्णालय प्रशासनाशी संपर्क साधा.';
  @override
  String get serverConnectionError =>
      'क्लिनिकल सर्व्हरशी कनेक्ट करण्यात अक्षम. कृपया आपले कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';
  @override
  String get authFailedError =>
      'प्रमाणीकरण पूर्ण होऊ शकले नाही. कृपया पुन्हा प्रयत्न करा.';

  // Doctor Profile & Workstation Availability (Phase D4)
  @override
  String get doctorProfileTitle => 'डॉक्टर प्रोफाइल';
  @override
  String get qualificationLabel => 'पात्रता';
  @override
  String get departmentLabel => 'विभाग';
  @override
  String get doctorUniqueCodeLabel => 'डॉक्टर युनिक कोड';
  @override
  String get registeredPhoneLabel => 'नोंदणीकृत फोन';
  @override
  String get accountStatusLabel => 'खाते स्थिती';
  @override
  String get activeStatus => 'सक्रिय';
  @override
  String get inactiveStatus => 'निष्क्रिय';
  @override
  String get availabilityLabel => 'उपलब्धता';
  @override
  String get goOnlineButton => 'ऑनलाइन जा';
  @override
  String get goOfflineButton => 'ऑफलाइन जा';
  @override
  String get readyForPatients => 'रुग्णांसाठी उपलब्ध';
  @override
  String get currentlyInConsultation => 'सध्या सल्लामसलत सुरू';
  @override
  String get profileManagedByAdminNotice =>
      'डॉक्टर प्रोफाइल डेटा केवळ रुग्णालय प्रशासनाकडून व्यवस्थापित केला जातो. अद्यतनांसाठी आयटी प्रशासनाशी संपर्क साधा.';
  @override
  String get viewDoctorProfile => 'डॉक्टर प्रोफाइल पहा';
  @override
  String get workstationAvailability => 'वर्कस्टेशन उपलब्धता';

  // Patient Requests (Phase D5)
  @override
  String get patientRequestsTitle => 'रुग्ण विनंत्या';
  @override
  String get patientRequestsSubtitle =>
      'आपल्या विभागासाठी येणाऱ्या ओपीडी सल्लामसलत विनंत्या';
  @override
  String get pendingRequestsCountLabel => 'प्रलंबित विनंत्या';
  @override
  String get queueNumberLabel => 'रांग क्रमांक';
  @override
  String get ageLabel => 'वय';
  @override
  String get genderLabel => 'लिंग';
  @override
  String get domainLabel => 'विभाग';
  @override
  String get requestTypeLabel => 'विनंती प्रकार';
  @override
  String get newVisitLabel => 'नवीन भेट';
  @override
  String get previousDoctorRequestedLabel => 'मागील डॉक्टरांची विनंती';
  @override
  String get vitalsLabel => 'व्हायटल्स';
  @override
  String get spo2Label => 'SpO₂';
  @override
  String get heartRateLabel => 'हृदयाचे ठोके';
  @override
  String get temperatureLabel => 'तापमान';
  @override
  String get waitingStatusLabel => 'प्रतिक्षेत';
  @override
  String get noPatientRequestsTitle => 'कोणत्याही रुग्ण विनंत्या नाहीत';
  @override
  String get noPatientRequestsSubtitle =>
      'सध्या आपल्या विभागासाठी कोणत्याही प्रलंबित ओपीडी विनंत्या नाहीत.';
  @override
  String get refreshRequestsButton => 'विनंत्या रीफ्रेश करा';
  @override
  String get unableToLoadRequestsTitle => 'रुग्ण विनंत्या लोड करण्यात अक्षम.';
  @override
  String get acceptRequestButton => 'विनंती स्वीकारा';
  @override
  String get assignmentD6Notice =>
      'रुग्ण वाटप टप्पा D6 मध्ये सक्षम केले जाईल.';
  @override
  String get notAvailableLabel => 'उपलब्ध नाही';
  @override
  String get workstationOfflineNotice =>
      'वर्कस्टेशन ऑफलाइन आहे. ओपीडी विनंत्या स्वीकारण्यासाठी स्थिती उपलब्ध वर सेट करा.';
  @override
  String get workstationInConsultationNotice =>
      'सध्या सल्लामसलत सुरू आहे. नवीन विनंत्या स्वीकारण्यापूर्वी चालू सल्लामसलत पूर्ण करा.';

  // Request Acceptance & Assignment (Phase D6)
  @override
  String get acceptingRequest => 'विनंती स्वीकारत आहे...';
  @override
  String get patientAcceptedNotice =>
      'रुग्ण विनंती यशस्वीरित्या स्वीकारली गेली.';
  @override
  String get patientAlreadyAssignedNotice =>
      'रुग्ण विनंती आधीच दुसऱ्या डॉक्टरांना नेमण्यात आली आहे.';
  @override
  String get notEligibleNotice =>
      'तुम्ही या विनंतीसाठी पात्र नाही.';
  @override
  String get doctorNotAvailableNotice =>
      'वर्कस्टेशन सल्लामसलतसाठी उपलब्ध नाही.';
  @override
  String get unableToAcceptNotice =>
      'ही रुग्ण विनंती स्वीकारण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get openingWorkspaceNotice => 'रुग्ण वर्कस्पेस उघडत आहे...';

  // Transitions & Success
  @override
  String get authSuccessTitle => 'प्रमाणीकरण यशस्वी';
  @override
  String get authSuccessSubtitle => 'क्लिनिकल वर्कस्टेशन उघडत आहे...';

  // General Actions
  @override
  String get back => 'मागे';
  @override
  String get close => 'बंद करा';
  @override
  String get cancel => 'रद्द करा';
  @override
  String get save => 'जतन करा';
  @override
  String get proceed => 'पुढे जा';

  // Patient Workspace & Clinical Records (Phase D7)
  @override
  String get patientWorkspaceTitle => 'रुग्ण वर्कस्पेस';
  @override
  String get patientInformation => 'रुग्णाची माहिती';
  @override
  String get patientNameLabel => 'रुग्णाचे नाव';
  @override
  String get patientIdLabel => 'रुग्ण आयडी';
  @override
  String get bloodGroupLabel => 'रक्तगट';
  @override
  String get currentVitals => 'सध्याचे व्हायटल्स';
  @override
  String get historicalVitals => 'मागील व्हायटल्स';
  @override
  String get clinicalRecords => 'क्लिनिकल रेकॉर्ड्स';
  @override
  String get cases => 'केस';
  @override
  String get visits => 'भेटी';
  @override
  String get myCases => 'माझे केस';
  @override
  String get startNewCase => 'नवीन केस सुरू करा';
  @override
  String get addVisit => 'भेट जोडा';
  @override
  String get caseDomainLabel => 'केस विभाग';
  @override
  String get caseTitleLabel => 'केस शीर्षक / कारण';
  @override
  String get caseTitleHint => 'उदा. उच्च रक्तदाब आणि छातीत अस्वस्थता';
  @override
  String get openCase => 'खुली';
  @override
  String get closedCase => 'बंद';
  @override
  String get visit => 'भेट';
  @override
  String get activeStatusLabel => 'सक्रिय';
  @override
  String get completedStatusLabel => 'पूर्ण';
  @override
  String get cancelledStatusLabel => 'रद्द';
  @override
  String get attendingDoctorLabel => 'उपस्थित डॉक्टर';
  @override
  String get visitStartedAtLabel => 'सुरू झालेली वेळ';
  @override
  String get selectCasePrompt => 'सल्लामसलत भेटी पाहण्यासाठी केस निवडा.';
  @override
  String get noCasesFound => 'या रुग्णासाठी कोणतीही क्लिनिकल केस आढळली नाही.';
  @override
  String get noVisitsFound => 'या केससाठी कोणतीही भेट नोंदवलेली नाही.';
  @override
  String get clinicalDocumentationNotice =>
      'सल्लामसलतीनंतर क्लिनिकल दस्तऐवजीकरण दिसेल.';
  @override
  String get consultationWorkspacePlaceholder =>
      'सल्लामसलत दस्तऐवजीकरण वर्कस्पेस टप्पा D8 मध्ये उपलब्ध होईल.';
  @override
  String get reportsTitle => 'अहवाल आणि निदान';
  @override
  String get availableReportsTab => 'उपलब्ध अहवाल';
  @override
  String get requestedReportsTab => 'मागवलेले अहवाल';
  @override
  String get uploadedReportsTab => 'अपलोड केलेले अहवाल';
  @override
  String get noReportsFound => 'कोणतेही निदान अहवाल आढळले नाहीत.';
  @override
  String get transferPatientButton => 'रुग्ण हस्तांतरित करा';
  @override
  String get completeVisitButton => 'भेट पूर्ण करा';
  @override
  String get notAvailable => 'उपलब्ध नाही';
  @override
  String get loadingPatientWorkspace => 'रुग्ण वर्कस्पेस लोड होत आहे...';
  @override
  String get patientNotFound => 'रुग्णाची माहिती लोड करता आली नाही.';
  @override
  String get unauthorizedAccess =>
      'तुम्हाला या रुग्ण वर्कस्पेसमध्ये प्रवेश करण्याची परवानगी नाही.';
  @override
  String get unableToLoadClinicalRecords =>
      'क्लिनिकल नोंदी लोड करण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get consultationInProgressTitle => 'सल्लामसलत सुरू आहे';
  @override
  String get consultationInProgressNotice =>
      'सल्लामसलत सध्या सुरू आहे. तुमची खात्री आहे की तुम्ही वर्कस्पेस सोडू इच्छिता?';
  @override
  String get stayButton => 'थांबा';
  @override
  String get leaveWorkspaceButton => 'वर्कस्पेस सोडा';
  @override
  String get previousDoctorRequestBadge => 'मागील डॉक्टर विनंती';

  // Phase D8: Live Doctor Consultation & Clinical Documentation
  @override
  String get visitIdentification => 'भेट ओळख';
  @override
  String get vitalsAtConsultation => 'सल्लामसलती दरम्यानचे व्हायटल्स';
  @override
  String get caseInformation => 'केस माहिती';
  @override
  String get caseTypeLabel => 'केस प्रकार';
  @override
  String get newCase => 'नवीन केस';
  @override
  String get existingCase => 'विद्यमान केस';
  @override
  String get caseStatusLabel => 'केस स्थिती';
  @override
  String get ongoingStatus => 'सुरू आहे';
  @override
  String get closedStatus => 'बंद';
  @override
  String get previousRelevantHistoryLabel => 'मागील संबंधित इतिहास';
  @override
  String get previousRelevantHistoryHint =>
      'या केससाठी संबंधित वैद्यकीय, शस्त्रक्रिया किंवा कौटुंबिक इतिहास प्रविष्ट करा...';
  @override
  String get structuredConsultation => 'संरचित सल्लामसलत';
  @override
  String get chiefComplaint => 'मुख्य तक्रार';
  @override
  String get chiefComplaintHint =>
      'रुग्णाच्या स्वतःच्या शब्दांत भेटीचे प्राथमिक कारण...';
  @override
  String get onsetDuration => 'सुरुवात / कालावधी';
  @override
  String get onsetDurationHint =>
      'उदा. 3 दिवस, अचानक सुरुवात, कालपासून वाढलेली...';
  @override
  String get associatedSymptoms => 'संबंधित लक्षणे';
  @override
  String get associatedSymptomsHint =>
      'उदा. ताप, पसरणाऱ्या वेदना, मळमळ, चक्कर येणे...';
  @override
  String get medicalHistory => 'वैद्यकीय इतिहास';
  @override
  String get medicalHistoryHint =>
      'मागील आजार, ऍलर्जी, शस्त्रक्रियांचा इतिहास...';
  @override
  String get currentMedication => 'सध्याची औषधे';
  @override
  String get currentMedicationHint =>
      'सक्रिय औषधे, ओव्हर-द-काउंटर औषधे, डोस...';
  @override
  String get clinicalObservations => 'क्लिनिकल निरीक्षणे';
  @override
  String get clinicalObservationsHint =>
      'शारीरिक तपासणीचे निष्कर्ष, स्टेथ तपासणी, स्पर्श परीक्षा...';
  @override
  String get assessment => 'मूल्यांकन / निदान';
  @override
  String get assessmentHint =>
      'क्लिनिकल निदान अंदाज, विभेदक निदान...';
  @override
  String get plan => 'उपचार योजना';
  @override
  String get planHint =>
      'उपचार धोरण, तपासण्या, त्वरित व्यवस्थापन...';
  @override
  String get doctorApprovedSummary => 'डॉक्टरांनी मंजूर केलेला भेट सारांश';
  @override
  String get summaryLabel => 'भेट सारांश';
  @override
  String get summaryHint =>
      'डॉक्टरांनी पुनरावलोकन करून मंजूर करण्यासाठी भेट सारांश प्रविष्ट करा...';
  @override
  String get summaryStatusLabel => 'सारांश स्थिती';
  @override
  String get summaryDraftStatus => 'मसुदा';
  @override
  String get summaryReviewRequiredStatus => 'पुनरावलोकन आवश्यक';
  @override
  String get summaryApprovedStatus => 'डॉक्टरांनी मंजूर केले';
  @override
  String get approveSummaryButton => 'सारांश मंजूर करा';
  @override
  String get summaryApprovedNotice =>
      'उपचार करणाऱ्या डॉक्टरांनी भेट सारांश मंजूर केला.';
  @override
  String get summaryEditWarning =>
      'सारांश संपादित केला गेला. पुन्हा मंजूरी आवश्यक आहे.';
  @override
  String get reportsRequested => 'मागवलेले अहवाल आणि तपासण्या';
  @override
  String get addInvestigationButton => '+ अहवाल / तपासणी जोडा';
  @override
  String get investigationNameLabel => 'अहवाल / तपासणीचे नाव';
  @override
  String get investigationNameHint =>
      'उदा. 12-लीड ईसीजी, कम्प्लीट ब्लड काउंट (सीबीसी), छातीचा एक्स-रे';
  @override
  String get priorityLabel => 'प्राधान्य';
  @override
  String get requiredPriority => 'आवश्यक';
  @override
  String get asAdvisedPriority => 'सल्ल्यानुसार';
  @override
  String get pendingUploadStatus => 'अपलोड प्रलंबित';
  @override
  String get uploadedStatus => 'अपलोड केले';
  @override
  String get reviewedStatus => 'तपासले';
  @override
  String get planFollowUp => 'योजना / पुढील भेट';
  @override
  String get followUpLabel => 'पुढील भेट';
  @override
  String get followUpHint =>
      'उदा. 2 आठवड्यांत पुनरावलोकन किंवा लक्षणे वाढल्यास त्वरित...';
  @override
  String get patientInstructionsLabel => 'रुग्णाला सूचना';
  @override
  String get patientInstructionsHint =>
      'आहार सल्ला, हालचालींची काळजी, जीवनशैली मार्गदर्शन...';
  @override
  String get visitCompletion => 'भेट पूर्णता';
  @override
  String get saveDraftButton => 'मसुदा जतन करा';
  @override
  String get draftSavedNotice =>
      'सल्लामसलत मसुदा यशस्वीरित्या जतन केला.';
  @override
  String get visitCompletedTitle => 'भेट पूर्ण झाली';
  @override
  String get visitCompletedSuccess =>
      'भेट यशस्वीरित्या पूर्ण झाली. केस चालू राहील.';
  @override
  String get caseOngoingNotice => 'केस चालू राहील.';
  @override
  String get incompleteFieldsError =>
      'कृपया सर्व आवश्यक सल्लामसलत फील्ड भरा आणि सारांश मंजूर करा.';
  @override
  String get missingRequirementsTitle => 'अपूर्ण सल्लामसलत आवश्यकता';
  @override
  String get consultationInProgress => 'सल्लामसलत सुरू आहे';
  @override
  String get savingDraft => 'मसुदा जतन करत आहे...';
  @override
  String get completingVisit => 'भेट पूर्ण करत आहे...';
  @override
  String get treatingDoctor => 'उपचार करणारे डॉक्टर';
  @override
  String get doctorQualification => 'डॉक्टरांची पात्रता';
  @override
  String get consultationTimestamp => 'दिनांक / वेळ';
  @override
  String get statusActive => 'सक्रिय';
  @override
  String get noInvestigationsRequested =>
      'अद्याप कोणतेही अहवाल किंवा तपासण्या मागवल्या नाहीत.';

  // Phase D9: Speech-to-Text Consultation Assistant
  @override
  String get speechToText => 'व्हॉइस रेकॉर्डिंग';
  @override
  String get dictateField => 'या फील्डमध्ये बोलून लिहा';
  @override
  String get startDictation => 'रेकॉर्डिंग सुरू करा';
  @override
  String get stopDictation => 'थांबवा आणि जोडा';
  @override
  String get cancelDictation => 'रद्द करा';
  @override
  String get recordingActive => 'रेकॉर्डिंग सुरू आहे...';
  @override
  String get listeningToSpeech => 'ऐकत आहे...';
  @override
  String get processingSpeech => 'ऑडिओ प्रक्रिया सुरू आहे...';
  @override
  String get speechErrorTitle => 'आवाज ओळख त्रुटी';
  @override
  String get micPermissionDenied =>
      'आवाज प्रतिलेखनासाठी मायक्रोफोन परवानगी आवश्यक आहे. कृपया परवानगी तपासा.';
  @override
  String get speechEngineUnavailable =>
      'या वर्कस्टेशनवर आवाज ओळख सेवा उपलब्ध नाही.';
  @override
  String get appendOrReplaceTitle => 'फील्डमधील मजकूर';
  @override
  String get appendOrReplacePrompt =>
      'या फील्डमध्ये आधीच मजकूर आहे. आपण नवीन मजकूर जोडू इच्छिता की बदलू इच्छिता?';
  @override
  String get appendButton => 'शेवटी जोडा';
  @override
  String get replaceButton => 'बदला';
  @override
  String get transcriptionSuccess => 'मजकूर फील्डमध्ये जोडला गेला.';
  @override
  String get micHardwareNotFound =>
      'मायक्रोफोन आढळला नाही. कृपया इनपुट डिव्हाइस कनेक्ट करा.';
  @override
  String get noSpeechDetected =>
      'कोणताही आवाज आढळला नाही. कृपया स्पष्ट बोला.';

  // Phase D9.1: Prescription Module & Unified Dictation (Marathi)
  @override
  String get prescription => 'औषधोपचार / प्रिस्क्रिप्शन';
  @override
  String get prescriptionSectionTitle => 'औषधोपचार / प्रिस्क्रिप्शन';
  @override
  String get numberOfMedicines => 'औषधांची संख्या';
  @override
  String get createPrescription => 'प्रिस्क्रिप्शन तयार करा';
  @override
  String get addMedicine => '+ औषध जोडा';
  @override
  String get removeMedicine => 'काढून टाका';
  @override
  String get dictatePrescription => 'प्रिस्क्रिप्शन बोला';
  @override
  String get prescriptionTranscript => 'प्रिस्क्रिप्शन उतारा';
  @override
  String get useInPrescription => 'प्रिस्क्रिप्शनमध्ये वापरा';
  @override
  String get addToExistingPrescription => 'विद्यमान मध्ये जोडा';
  @override
  String get replacePrescription => 'प्रिस्क्रिप्शन बदला';
  @override
  String get cancelPrescriptionDictation => 'रद्द करा';
  @override
  String get incompletePrescription => 'अपूर्ण प्रिस्क्रिप्शन';
  @override
  String get srNo => 'अनु. क्र.';
  @override
  String get medicineName => 'औषधाचे नाव';
  @override
  String get duration => 'कालावधी';
  @override
  String get timesADay => 'दिवसातून किती वेळा';
  @override
  String get remarks => 'सूचना / शेरा';
  @override
  String get medicineNameHint => 'उदा. पॅरासिटामॉल 500 मिग्रॅ';
  @override
  String get durationHint => 'उदा. 5 दिवस';
  @override
  String get timesADayHint => 'उदा. 2';
  @override
  String get remarksHint => 'उदा. जेवणानंतर';
  @override
  String get enterNumberOfMedicinesPrompt =>
      'या प्रिस्क्रिप्शनसाठी आवश्यक औषधांची संख्या प्रविष्ट करा.';
  @override
  String get noMedicinesAddedNotice =>
      'अद्याप कोणतीही औषधे जोडली नाहीत. औषधांची संख्या प्रविष्ट करा किंवा बोला.';

  // Phase D10: Gemini Documentation Assistant (Marathi)
  @override
  String get doctorAssistedDocumentation => 'डॉक्टर-सहाय्यित दस्तऐवजीकरण';
  @override
  String get generateDraftSummary => 'मसुदा सारांश तयार करा';
  @override
  String get regenerateDraftSummary => 'पुन्हा मसुदा तयार करा';
  @override
  String get aiPreparingDocumentation => 'एआय दस्तऐवजीकरण मसुदा तयार करत आहे...';
  @override
  String get aiDraftDisclaimer =>
      'एआय-निर्मित दस्तऐवज हा मसुदा आहे. डॉक्टरांचे पुनरावलोकन आणि मंजुरी आवश्यक आहे.';
  @override
  String get regenerateWarningTitle => 'नवीन मसुदा तयार करू इच्छिता?';
  @override
  String get regenerateWarningPrompt =>
      'पुन्हा तयार केल्यास सध्याचा सारांश नवीन एआय मसुद्याने बदलला जाईल. तुमचे संपादन नष्ट होऊ शकते.';
  @override
  String get regenerateButton => 'पुन्हा तयार करा';
  @override
  String get documentationUnavailable =>
      'दस्तऐवजीकरण सहाय्य तात्पुरते अनुपलब्ध आहे. तुमचा सल्लामसलत डेटा सुरक्षित आहे.';
  @override
  String get completeMandatoryFieldsPrompt =>
      'मसुदा सारांशासाठी सर्व 8 आवश्यक सल्लामसलत फील्ड भरा.';
  // Phase D9.2: Gemini Speech Transcript Cleanup Assistant (Marathi)
  @override
  String get voiceTranscriptReviewTitle => 'व्हॉइस ट्रान्सक्रिप्ट पुनरावलोकन';
  @override
  String get originalTranscriptLabel => 'मूळ ट्रान्सक्रिप्ट (स्पीच-टू-टेक्स्ट)';
  @override
  String get geminiCleanedDraftLabel => 'एआय सुधारित ट्रान्सक्रिप्ट मसुदा';
  @override
  String get useCleanedVersion => 'सुधारित आवृत्ती वापरा';
  @override
  String get useOriginal => 'मूळ आवृत्ती वापरा';
  @override
  String get editManually => 'संपादित करा';
  @override
  String get doneEditing => 'संपादन पूर्ण';
  @override
  String get cleanAgain => 'पुन्हा सुधारित करा';
  @override
  String get cleanAgainTitle => 'नवीन मसुदा सुधारू इच्छिता?';
  @override
  String get cleanAgainPrompt =>
      'मूळ ट्रान्सक्रिप्टवरून नवीन सुधारित मसुदा तयार करायचा? तुमची संपादने वापरली जाणार नाहीत.';
  @override
  String get cleanAgainConfirm => 'पुन्हा सुधारित करा';
  @override
  String get aiDraftNotice =>
      'एआय सुधारणा हा केवळ मसुदा आहे. कृपया स्वीकारण्यापूर्वी खात्री करा.';
  @override
  String get aiCleaningInProgress => 'एआय ट्रान्सक्रिप्ट सुधारत आहे...';
  @override
  String get cleanupUnavailable =>
      'एआय सुधारणा उपलब्ध नाही. आपण मूळ ट्रान्सक्रिप्ट वापरू शकता किंवा व्यक्तिशः संपादित करू शकता.';
  @override
  String get transcriptTooLong =>
      'ट्रान्सक्रिप्ट एआय सुधारणेसाठी खूप मोठी आहे. कृपया संपादन करा.';
  @override
  String get unclearPhraseWarning => 'अस्पष्ट शब्द आढळला — कृपया पडताळा.';
  @override
  String get editModeNotice => 'संपादन मोड सक्रिय. बदल करा आणि स्वीकारा.';
  @override
  String get aiAssistedBadge => 'एआय सहाय्यक';
  @override
  String get devModeBadge => 'डेव्ह मोड';

  // Phase D11: Reports, Investigations & Visit PDF
  @override
  String get investigationCategoryLabel => 'प्रवर्ग';
  @override
  String get labCategory => 'प्रयोगशाळा';
  @override
  String get radiologyCategory => 'रेडिओलॉजी';
  @override
  String get diagnosticCategory => 'निदान';
  @override
  String get otherCategory => 'इतर';
  @override
  String get requestInvestigationButton => '+ तपासणीची विनंती करा';
  @override
  String get requestInvestigationDialogTitle => 'वैद्यकीय तपासणीची विनंती';
  @override
  String get reportsReviewTitle => 'डॉक्टर अहवाल आणि निदान';
  @override
  String get tabRequested => 'मागवलेले';
  @override
  String get tabUploaded => 'अपलोड केलेले (तपासणी बाकी)';
  @override
  String get tabReviewed => 'तपासलेले';
  @override
  String get markAsReviewedButton => 'तपासले म्हणून चिन्हांकित करा';
  @override
  String get reportReviewedNotice => 'अहवाल उपस्थित डॉक्टरांनी तपासल्याची नोंद झाली.';
  @override
  String get noReportsInTab => 'या विभागात कोणतेही अहवाल नाहीत.';
  @override
  String get viewReportButton => 'अहवाल पहा';
  @override
  String get uploadReportButton => 'अहवाल अपलोड करा';
  @override
  String get previewVisitReportButton => 'भेट अहवाल पूर्वावलोकन';
  @override
  String get visitReportPreviewTitle => 'आयुसाथी — केस आणि भेट दस्तऐवजीकरण (मसुदा)';
  @override
  String get generatePdfButton => 'भेट PDF तयार करा';
  @override
  String get printPdfButton => 'PDF मुद्रित / निर्यात करा';
  @override
  String get pdfGatingWarning =>
      'अहवाल तयार करण्यापूर्वी सर्व आवश्यक सल्लामसलत माहिती भरा आणि भेट सारांश मंजूर करा.';
  @override
  String get pdfGeneratedSuccess => 'अधिकृत आयुसाथी भेट अहवाल PDF यशस्वीरित्या तयार झाली.';

  // Phase D11.1: PDF Output, Open & Save As (Marathi)
  @override
  String get pdfCreatedSuccessTitle => 'भेट अहवाल PDF तयार झाला';
  @override
  String get openPdfButton => 'PDF उघडा';
  @override
  String get saveAsButton => 'या नावाने जतन करा';
  @override
  String get pdfLocationLabel => 'जतन केलेले स्थान';
  @override
  String get pdfOpenError => 'PDF तयार झाली, परंतु विंडोज फाइल उघडू शकले नाही.';
  @override
  String get pdfSaveAsSuccess => 'PDF प्रत यशस्वीरित्या जतन केली.';
  @override
  String get pdfSaveAsCancelled => 'जतन करण्याची प्रक्रिया रद्द केली.';
  @override
  String get pdfSavedToDesktopNotice => 'अहवाल PDF प्रत आपल्या डेस्कटॉपवर जतन केली आहे.';

  // Phase D12: Visit Completion, Case Lifecycle & Doctor Workflow Finalization (Marathi)
  @override
  String get completeVisitDialogTitle => 'भेट पूर्ण करा';
  @override
  String get completeVisitExplanation =>
      'ही भेट पूर्ण केल्याने हा सल्लामसलत पूर्ण नोंदवला जाईल. नंतर स्पष्टपणे बंद करेपर्यंत केस पुढील भेटींसाठी खुली राहील.';
  @override
  String get prerequisitesChecklistTitle => 'ही भेट पूर्ण करण्यापूर्वी पुष्टी करा:';
  @override
  String get consultationDocsCompleteCheck =>
      'आवश्यक सल्लामसलत दस्तऐवजीकरण पूर्ण (8 फील्ड)';
  @override
  String get summaryApprovedCheck => 'डॉक्टर-मंजूर सारांश उपस्थित';
  @override
  String get investigationsRecordedCheck => 'अहवाल / तपासण्या नोंदवल्या';
  @override
  String get pdfGeneratedCheck => 'भेट अहवाल तयार';
  @override
  String get caseRemainsOpenNote =>
      'नोंद: ही भेट पूर्ण केल्याने केस बंद होत नाही.';
  @override
  String get doctorDeclarationCheckbox =>
      'मी पुष्टी करतो/करते की मी या सल्लामसलतीसाठी दस्तऐवजीकरणाचे पुनरावलोकन केले आहे आणि ते पूर्ण केले आहे.';
  @override
  String get doctorDeclarationText =>
      'मी पुष्टी करतो/करते की या सल्लामसलतीसाठी दस्तऐवजीकरण पूर्ण आहे आणि ही भेट पूर्ण म्हणून चिन्हांकित केली जाऊ शकते.';
  @override
  String get completeVisitSubmitButton => 'भेट पूर्ण करा';
  @override
  String get visitCompletedSuccessTitle => 'भेट यशस्वीरित्या पूर्ण झाली';
  @override
  String get visitCompletedSuccessSubtitle =>
      'सल्लामसलत सत्र पूर्ण झाले आहे. रुग्णाची केस खुली (OPEN) राहील.';
  @override
  String get historicalVisitReadOnlyTitle => 'मागील भेटीचा तपशील (केवळ वाचण्यासाठी)';
  @override
  String get historicalVisitNotice =>
      'ही पूर्ण झालेली भेट नोंद संग्रहित आणि केवळ वाचनीय आहे.';
  @override
  String get viewVisitDetailsButton => 'भेट पहा';
  @override
  String get continueExistingCaseButton => '+ नवीन भेट';
  @override
  String get newVisitCreatedNotice =>
      'या चालू केससाठी नवीन सक्रिय भेट सुरू केली.';
  @override
  String get visitCompletionFailedNotice =>
      'ही भेट पूर्ण करण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get caseStatusOpenBadge => 'उघडी (चालू)';
  @override
  String get caseStatusClosedBadge => 'बंद';
  @override
  String get completedAtLabel => 'पूर्ण वेळ';
  @override
  String get backToDashboardButton => 'डॅशबोर्डवर परत जा';

  // Phase D13: Doctor Transfer & Inter-Department Referral (Marathi)
  @override
  String get transferPatientTitle => 'रुग्ण हस्तांतरण';
  @override
  String get transferPatientSubtitle =>
      'विशेष मूल्यमापनासाठी रुग्णाला दुसऱ्या वैद्यकीय विभागात रेफर करा.';
  @override
  String get transferPatientDialogSubtitle =>
      'गंतव्य ओपीडी विभाग निवडा आणि हस्तांतरणाचे क्लिनिकल कारण स्पष्ट करा.';
  @override
  String get continueButton => 'पुढे जा';
  @override
  String get reviewTransferButton => 'हस्तांतरणाचे पुनरावलोकन करा';
  @override
  String get selectDestinationDepartment => 'गंतव्य विभाग निवडा';
  @override
  String get currentDepartmentLabel => 'सध्याचा विभाग';
  @override
  String get destinationDepartmentLabel => 'गंतव्य विभाग';
  @override
  String get transferReasonLabel => 'हस्तांतरण / रेफरलचे कारण';
  @override
  String get transferReasonHint =>
      'हस्तांतरणाचे क्लिनिकल कारण प्रविष्ट करा (उदा. न्यूरोलॉजिकल मूल्यमापन आवश्यक)...';
  @override
  String get transferReasonRequiredError => 'हस्तांतरणाचे कारण आवश्यक आहे.';
  @override
  String get transferReasonTooLongError =>
      'हस्तांतरणाचे कारण 1000 अक्षरांपेक्षा जास्त असू शकत नाही.';
  @override
  String get cannotTransferToSameDepartmentError =>
      'गंतव्य विभाग सध्याच्या विभागासारखाच असू शकत नाही.';
  @override
  String get transferPreservesCaseNote =>
      'महत्त्वाचे: हस्तांतरणामुळे रुग्णाचा सध्याचा केस आणि भेट इतिहास जतन केला जाईल.';
  @override
  String get reviewTransferTitle => 'हस्तांतरणाचे पुनरावलोकन करा';
  @override
  String get reviewTransferSubtitle =>
      'सबमिट करण्यापूर्वी आंतर-विभागीय रुग्ण रेफरल तपशीलांची पुष्टी करा.';
  @override
  String get confirmTransferButton => 'हस्तांतरणाची पुष्टी करा';
  @override
  String get transferSubmittedSuccess =>
      'रुग्ण यशस्वीरित्या हस्तांतरित झाला. डॅशबोर्डवर परत जात आहे...';
  @override
  String get transferFailedNotice =>
      'रुग्ण हस्तांतरित करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get transferredFromBanner => 'येथून हस्तांतरित';
  @override
  String get transferRequestBadge => 'हस्तांतरण विनंती';
  @override
  String get fromDepartmentLabel => 'कडून';
  @override
  String get transferReasonCardLabel => 'कारण';
  @override
  String get cancelTransferTitle => 'हस्तांतरण रद्द करायचे?';
  @override
  String get cancelTransferConfirmation =>
      'तुम्हाला खात्री आहे की तुम्ही ही हस्तांतरण विनंती रद्द करू इच्छिता?';
  @override
  String get cancelTransferButton => 'हस्तांतरण रद्द करा';
  @override
  String get keepTransferButton => 'हस्तांतरण ठेवा';
  @override
  String get transferCancelledSuccess =>
      'हस्तांतरण विनंती यशस्वीरित्या रद्द केली.';
  @override
  String get transferAlreadyAcceptedNotice =>
      'ही हस्तांतरण विनंती आधीच दुसऱ्या डॉक्टरांनी स्वीकारली आहे.';
  @override
  String get awaitingTransferDoctorBadge => 'डॉक्टरांची प्रतीक्षा';
  @override
  String get transferAssignedBadge => 'हस्तांतरण नियुक्त';

  // Phase D14: Doctor Case Continuation & Follow-Up Workflow (Marathi)
  @override
  String get continueCaseButton => 'केस सुरू ठेवा';
  @override
  String get viewHistoryButton => 'इतिहास पहा';
  @override
  String get caseTimelineTab => 'केस टाइमलाइन';
  @override
  String get visitHistoryTab => 'भेट इतिहास';
  @override
  String get startNewVisitTitle => 'नवीन भेट सुरू करा';
  @override
  String get startNewVisitSubtitle =>
      'या विद्यमान केस अंतर्गत एक नवीन सल्लामसलत भेट तयार केली जाईल.';
  @override
  String get startNewVisitButton => '+ नवीन भेट';
  @override
  String get confirmStartNewVisitButton => 'नवीन भेट सुरू करा';
  @override
  String get activeVisitExistsTitle => 'सक्रिय सल्लामसलत अस्तित्वात आहे';
  @override
  String get activeVisitExistsNotice =>
      'या केससाठी आधीच एक सक्रिय सल्लामसलत भेट अस्तित्वात आहे.';
  @override
  String get returnToActiveVisitButton => 'सल्लामसलतीवर परत जा';
  @override
  String get caseInformationTitle => 'केस माहिती';
  @override
  String get createdDateLabel => 'निर्मिती तारीख';
  @override
  String get lastUpdatedLabel => 'शेवटचे अद्यतन';
  @override
  String get caseTimeline => 'केस टाइमलाइन';
  @override
  String get timelineFilterAll => 'सर्व';
  @override
  String get timelineFilterCompleted => 'पूर्ण';
  @override
  String get timelineFilterTransferred => 'हस्तांतरित';
  @override
  String get timelineFilterActive => 'सक्रिय';
  @override
  String get currentVitalsNotRecorded => 'सध्याचे वाइटल्स नोंदवले नाहीत.';
  @override
  String get historicalVitalsLabel => 'ऐतिहासिक वाइटल्स';
  @override
  String get caseContinuedSuccess =>
      'विद्यमान केस सुरू ठेवली. नवीन भेट सुरू झाली.';
  @override
  String get openCasesTitle => 'सक्रिय केसेस';
  @override
  String get closedCasesTitle => 'बंद केसेस (केवळ वाचनासाठी)';
  @override
  String get previousCaseHistoryTitle => 'मागील केस इतिहास';

  // Phase D15: Doctor Case Closure, Standalone Cases & Diagnostics Desks
  @override
  String get closeCaseButton => 'केस बंद करा';
  @override
  String get closeCaseTitle => 'केस बंद करा';
  @override
  String get closeCaseSubtitle => 'रुग्णाचा हा क्लिनिकल उपचार टप्पा पूर्ण करा.';
  @override
  String get closeCaseExplanation =>
      'ही केस बंद करण्यापूर्वी, खात्री करा की या केसशी संबंधित रुग्णाची समस्या सुटली आहे किंवा या केस अंतर्गत पुढील सल्लामसलतीची आवश्यकता नाही.';
  @override
  String get closeCaseDeclarationCheckbox =>
      'मी पुष्टी करतो/करते की मी ही केस बंद करत आहे कारण या केसशी संबंधित क्लिनिकल समस्येचे निराकरण झाले आहे / योग्यरित्या निष्कर्ष काढला गेला आहे.';
  @override
  String get closureDeclarationError => 'तुम्हाला केस समाप्ती घोषणा चेकबॉक्सची पुष्टी करणे आवश्यक आहे.';
  @override
  String get closureNoteLabel => 'समाप्ती नोंद';
  @override
  String get closureNoteHint => 'डॉक्टरांची समाप्ती नोंद / क्लिनिकल निष्कर्ष प्रविष्ट करा (कमाल 1,000 अक्षरे)...';
  @override
  String get closureNoteRequiredError => 'समाप्ती नोंद आवश्यक आहे.';
  @override
  String get closureNoteTooLongError => 'समाप्ती नोंद 1,000 अक्षरांपेक्षा जास्त असू शकत नाही.';
  @override
  String get activeVisitBlocksClosureError =>
      'ही केस बंद करण्यापूर्वी सक्रिय सल्लामसलत पूर्ण करा किंवा हस्तांतरित करा.';
  @override
  String get pendingTransferBlocksClosureError =>
      'ही केस बंद करण्यापूर्वी प्रलंबित आंतर-विभागीय हस्तांतरण निकाली काढणे आवश्यक आहे.';
  @override
  String get caseClosedSuccessTitle => 'केस बंद झाली';
  @override
  String get caseClosedSuccessSubtitle =>
      'मागील सर्व भेटी आणि क्लिनिकल नोंदी सुरक्षित राहतील.';
  @override
  String get closedByDoctorLabel => 'द्वारे बंद केले';
  @override
  String get closureDateLabel => 'तारीख';
  @override
  String get closureNoteCardLabel => 'समाप्ती नोंद';
  @override
  String get viewCaseHistoryButton => 'केस इतिहास पहा';
  @override
  String get closedCaseReadOnlyNotice =>
      'ही केस बंद आणि संग्रहित आहे. सर्व ऐतिहासिक नोंदी केवळ वाचनासाठी उपलब्ध आहेत.';
  @override
  String get cannotAddVisitToClosedCase => 'बंद केलेल्या केस अंतर्गत नवीन भेट सुरू करता येत नाही.';
  @override
  String get casesAndVisitsTitle => 'केसेस आणि क्लिनिकल भेटी';
  @override
  String get casesAndVisitsSubtitle => 'ओपीडी अनुदैर्ध्य रुग्ण इतिहास';
  @override
  String get tabAllCases => 'सर्व केसेस';
  @override
  String get tabOpenCases => 'सक्रिय केसेस';
  @override
  String get tabClosedCases => 'बंद केसेस';
  @override
  String get searchCasesHint => 'रुग्ण आयडी, केस आयडी किंवा विभागानुसार शोधा...';
  @override
  String get openCaseButton => 'केस उघडा';
  @override
  String get noCasesInFilter => 'या श्रेणीसाठी कोणतीही क्लिनिकल केस आढळली नाही.';
  @override
  String get reportsAndDiagnosticsTitle => 'निदान अहवाल';
  @override
  String get reportsAndDiagnosticsSubtitle => 'लॅब चाचण्या आणि रेडिओलॉजी नोंदी';
  @override
  String get tabVisitReports => 'भेट अहवाल (PDF)';
  @override
  String get searchReportsHint => 'रुग्ण आयडी किंवा चाचणी नावाने शोधा...';
  @override
  String get markReviewedSuccess => 'निदान अहवाल डॉक्टरांद्वारे तपासला गेल्याचे चिन्हांकित केले.';
  @override
  String get officialVisitPdf => 'अधिकृत भेट अहवाल PDF';
  @override
  String get caseClosedTimelineTitle => 'केस बंद';
  @override
  String get caseClosedTimelineBadge => 'केस बंद';
  @override
  String get createdLabel => 'तयार केले';
  @override
  String get unauthorizedCaseAccess =>
      'आपण ही क्लिनिकल केस पाहण्यासाठी किंवा ऍक्सेस करण्यासाठी अधिकृत नाही.';

  // Phase A8: Case Escalation (Marathi)
  @override
  String get escalateCaseButton => 'केस एस्केलेट करा';
  @override
  String get escalateCaseDialogTitle => 'उच्च प्राधिकरणाकडे पुनरावलोकन विनंती';
  @override
  String get escalateCaseDialogSubtitle => 'क्लिनिकल केस एस्केलेशन प्रोटोकॉल';
  @override
  String get escalationReasonPrompt =>
      'प्रशासकीय पुनरावलोकनासाठी प्राथमिक वैद्यकीय कारण निवडा:';
  @override
  String get reasonClinicalDeterioration => 'क्लिनिकल स्थिती खालावणे';
  @override
  String get reasonRepeatedVisits => 'निवारणाशिवाय वारंवार भेटी';
  @override
  String get reasonHigherAuthority => 'उच्च प्राधिकारी पुनरावलोकन आवश्यक';
  @override
  String get reasonDoctorConcern => 'डॉक्टरांची चिंता / संशय';
  @override
  String get reasonOther => 'इतर';
  @override
  String get escalationNoteLabel => 'अतिरिक्त क्लिनिकल संदर्भ / कारण';
  @override
  String get escalationNoteHint =>
      'उच्च प्राधिकारी पुनरावलोकनासाठी संक्षिप्त कारण प्रविष्ट करा...';
  @override
  String get escalationNoteRequiredError =>
      'इतर निवडताना कृपया स्पष्टीकरण द्या.';
  @override
  String get confirmEscalatePrompt =>
      'ही क्लिनिकल केस ॲडमिन पुनरावलोकनासाठी एस्केलेट करायची आहे का?';
  @override
  String get confirmEscalateNotice =>
      'केस आणि चालू सल्लामसलत सक्रिय व खुली राहील.';
  @override
  String get caseAlreadyEscalatedMessage =>
      'ही केस आधीच ॲडमिन पुनरावलोकनासाठी एस्केलेट केली आहे.';
  @override
  String get caseEscalatedSuccess => 'केस ॲडमिन पुनरावलोकनासाठी एस्केलेट केली.';
  @override
  String get escalating => 'एस्केलेट होत आहे...';

  // Patient Uploaded Reports (Past Visits & Clinical Workspace)
  @override
  String get patientUploadedReportsHeader => 'रुग्णाने अपलोड केलेले अहवाल';
  @override
  String get noPatientReportsForVisit =>
      'या भेटीसाठी कोणतेही रुग्ण अहवाल अपलोड केलेले नाहीत.';
  @override
  String get waitingForPatientReport => 'रुग्णाच्या अहवालाची प्रतीक्षा आहे.';
  @override
  String get aiSummarizeReportButton => 'एआय अहवाल सारांश';
  @override
  String get aiSummaryTitle => 'एआय अहवाल सारांश सहाय्यक';
  @override
  String get aiSummaryNotice =>
      'एआय-निर्मित सारांश — डॉक्टरांचे प्रमाणीकरण आवश्यक आहे.';
  @override
  String get aiSummaryDisclaimer =>
      'एआय रुग्णाचे निदान किंवा उपचार ठरवू शकत नाही.';
  @override
  String get unauthorizedReportAccess =>
      'आपण या रुग्ण भेटीचे अहवाल पाहण्यासाठी अधिकृत नाही.';
  @override
  String get analyzingReport => 'अहवालाचे विश्लेषण सुरू आहे...';
  @override
  String get unableToSummarizeReport => 'या अहवालाचा सारांश तयार करण्यात अक्षम.';
  @override
  String get unableToSummarizeReportTryAgain =>
      'या अहवालाचा सारांश तयार करण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get reviewRequiredBadge => 'पुनरावलोकन आवश्यक';
  @override
  String get approvedByDoctorBadge => 'डॉक्टरांनी मंजूर केले';
  @override
  String get editSummaryButton => 'सारांश संपादित करा';
  @override
  String get regenerateConfirmationTitle => 'एआय सारांश पुन्हा तयार करायचा?';
  @override
  String get regenerateConfirmationMessage =>
      'पुन्हा तयार केल्याने मंजूर केलेला सारांश बदलला जाईल आणि स्थिती पुनरावलोकन आवश्यक वर रीसेट होईल. आपण पुढे जाऊ इच्छिता?';
  @override
  String get reportOverviewHeader => '1. अहवाल विहंगावलोकन';
  @override
  String get keyFindingsHeader => '2. मुख्य निष्कर्ष';
  @override
  String get reportedMeasurementsHeader => '3. नोंदवलेले मोजमाप';
  @override
  String get reportedFindingsHeader => '4. नोंदवलेले निष्कर्ष';
  @override
  String get reportedImpressionHeader => '5. नोंदवलेला प्रभाव / निष्कर्ष';
  @override
  String get itemsToReviewHeader => '6. पुनरावलोकनासाठी बाबी';
  @override
  String get dataQualityHeader => '7. डेटा गुणवत्ता / अनिश्चितता';
  @override
  String get summarySavedNotice =>
      'एआय सारांश डॉक्टरांनी मंजूर केला आणि जतन केला.';
  @override
  String get saveChangesButton => 'बदल जतन करा';
}
