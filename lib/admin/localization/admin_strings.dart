/// Localized string definitions for the AAYUSATHI Administrative Portal.
/// Supports English (en), Hindi (hi), and Marathi (mr).
abstract class AdminStrings {
  // Portal & Branding
  String get adminPortalTitle;
  String get administrationPortal;
  String get healthcareManagementSystem;
  String get appTagline;
  String get centralAdminConsole;
  String get terminalOnline;
  String get protectedAdminSession;
  String get touchToBegin;
  String get touchToBeginSubtitle;

  // Login Screen
  String get adminLoginTitle;
  String get adminLoginSubtitle;
  String get username;
  String get usernameHint;
  String get password;
  String get passwordHint;
  String get loginButton;
  String get back;
  String get emptyUsernameError;
  String get emptyPasswordError;
  String get invalidCredentialsError;
  String get authenticating;
  String get secureSessionNotice;
  String get level1AdminNotice;

  // Header & Profile
  String get systemAdministrator;
  String get level1Authority;
  String get viewProfile;
  String get logout;
  String get hospitalWorkstation;

  // Sidebar Items
  String get navDashboard;
  String get navDoctors;
  String get navAvailability;
  String get navAppointmentEscalations;
  String get navCaseEscalations;
  String get adminConsole;

  // Dashboard Overview
  String get systemOverview;
  String get systemOverviewSubtitle;
  String get totalDoctors;
  String get totalDoctorsDesc;
  String get availableDoctors;
  String get availableDoctorsDesc;
  String get pendingAppointments;
  String get pendingAppointmentsDesc;
  String get activeEscalations;
  String get activeEscalationsDesc;
  String get activeCases;
  String get activeCasesDesc;

  // Doctor Action Cards
  String get addNewDoctorTitle;
  String get addNewDoctorDesc;
  String get addNewDoctorButton;
  String get manageDoctorsTitle;
  String get manageDoctorsDesc;
  String get manageDoctorsButton;

  // Availability Section
  String get doctorAvailabilityTitle;
  String get doctorAvailabilitySubtitle;
  String get domainColumn;
  String get availableColumn;
  String get onlineColumn;
  String get inConsultationColumn;
  String get totalColumn;
  String get statusColumn;

  // Waiting Appointments & Active Cases Cards
  String get waitingAppointmentsCardTitle;
  String get waitingAppointmentsSubtitle;
  String get noWaitingAppointments;
  String get activeCasesCardTitle;
  String get activeCasesSubtitle;
  String get noActiveCases;
  String get casesByDomain;
  String get refresh;
  String get refreshing;
  String get retry;
  String get errorLoadingDashboard;

  // Escalation Sections
  String get appointmentEscalationsTitle;
  String get appointmentEscalationsSubtitle;
  String get noAppointmentEscalations;
  String get noAppointmentEscalationsDesc;

  String get caseEscalationsTitle;
  String get caseEscalationsSubtitle;
  String get noCaseEscalations;
  String get noCaseEscalationsDesc;

  // A4 Doctor Provisioning Form & Success Screen
  String get addNewDoctorSubtitle;
  String get backToDashboard;
  String get doctorInformationSection;
  String get fullNameLabel;
  String get fullNamePlaceholder;
  String get registeredPhoneLabel;
  String get registeredPhonePlaceholder;
  String get qualificationLabel;
  String get qualificationPlaceholder;
  String get departmentLabel;
  String get selectDepartmentHint;
  String get optionalEmailLabel;
  String get optionalEmailPlaceholder;
  String get createDoctorButton;
  String get creatingDoctorButton;
  String get doctorCreatedTitle;
  String get doctorCreatedSubtitle;
  String get generatedDoctorIdLabel;
  String get generatedPasswordLabel;
  String get savePasswordWarning;
  String get copyDoctorIdButton;
  String get copyPasswordButton;
  String get copiedFeedback;
  String get addAnotherDoctorButton;
  String get doneButton;

  // A5 Manage Doctors Strings
  String get manageDoctorsHeaderTitle;
  String get manageDoctorsHeaderSubtitle;
  String get searchDoctorPlaceholder;
  String get filterAllDepartments;
  String get filterAllStatuses;
  String get statusActive;
  String get statusInactive;
  String get sortBy;
  String get sortNewest;
  String get sortNameAsc;
  String get sortDepartment;
  String get sortStatus;
  String get totalDoctorsCount;
  String get activeDoctorsCount;
  String get inactiveDoctorsCount;
  String get noDoctorsFound;
  String get noDoctorsFoundSubtitle;
  String get tableColDoctorId;
  String get tableColName;
  String get tableColDepartment;
  String get tableColPhone;
  String get tableColStatus;
  String get tableColActions;
  String get actionViewDetails;
  String get actionEditDoctor;
  String get actionDeactivate;
  String get actionActivate;
  String get doctorDetailsModalTitle;
  String get doctorDetailsModalSubtitle;
  String get doctorEditModalTitle;
  String get doctorEditModalSubtitle;
  String get doctorDeactivateModalTitle;
  String get doctorActivateModalTitle;
  String get doctorDeactivateConfirmMessage;
  String get doctorActivateConfirmMessage;
  String get consultationBlockedWarning;
  String get departmentChangeWarning;
  String get saveChangesButton;
  String get savingChangesButton;
  String get confirmButton;
  String get cancelButton;
  String get doctorUpdatedSuccess;
  String get doctorStatusUpdatedSuccess;
  String get viewFullHistory;

  // Phase A6: Doctor Availability Management
  String get availabilityHeaderTitle;
  String get availabilityHeaderSubtitle;
  String get viewAllDoctors;
  String get totalActiveDoctors;
  String get onlineAvailable;
  String get inConsultation;
  String get offline;
  String get domainCapacityTitle;
  String get searchAvailabilityPlaceholder;
  String get filterAvailabilityAll;
  String get filterAvailabilityOffline;
  String get filterAvailabilityAvailable;
  String get filterAvailabilityInConsultation;
  String get sortAvailability;
  String get sortLastActivity;
  String get tableColDoctor;
  String get tableColDoctorIdA6;
  String get tableColDepartmentA6;
  String get tableColAccount;
  String get tableColAvailability;
  String get tableColLastActivity;
  String get actionSetAvailable;
  String get actionSetOffline;
  String get actionDoctorInConsultation;
  String get setAvailableModalTitle;
  String get setAvailableConfirmMessage;
  String get setOfflineModalTitle;
  String get setOfflineConfirmMessage;
  String get consultationLockedTitle;
  String get consultationLockedMessage;
  String get noActiveDoctorsTitle;
  String get noActiveDoctorsSubtitle;
  String get errorLoadingAvailability;
  String get doctorSetAvailableSuccess;
  String get doctorSetOfflineSuccess;

  // Phase A7: Appointment Escalations
  String get appointmentEscalationsHeaderTitle;
  String get appointmentEscalationsHeaderSubtitle;
  String get summaryEscalatedAppointments;
  String get summaryWaitingAppointments;
  String get summaryResolvedToday;
  String get searchEscalationPlaceholder;
  String get filterStatusAll;
  String get filterStatusEscalated;
  String get filterStatusWaiting;
  String get filterStatusResolved;
  String get sortOldestWaiting;
  String get sortEscalationTime;
  String get tableColQueue;
  String get tableColAppointmentId;
  String get tableColDepartmentA7;
  String get tableColWaitingSince;
  String get tableColWaitingDuration;
  String get tableColEscalatedAt;
  String get tableColCurrentStatus;
  String get tableColAction;
  String get actionAssignDoctor;
  String get actionInspectDetails;
  String get statusBadgeEscalated;
  String get statusBadgeWaiting;
  String get statusBadgeResolved;
  String get detailsModalTitle;
  String get detailsModalSubtitle;
  String get assignDoctorModalTitle;
  String get assignDoctorModalSubtitle;
  String get eligibleDoctorsFound;
  String get noEligibleDoctorsTitle;
  String get noEligibleDoctorsMessage;
  String get confirmAssignmentButton;
  String get assigningButton;
  String get assignmentSuccessMessage;
  String get assignmentFailedMessage;
  String get doctorUnavailableError;
  String get previousDoctorRestrictionWarning;
  String get emptyEscalationsTitle;
  String get emptyEscalationsSubtitle;
  String get errorLoadingEscalations;

  // Phase A8: Case Escalations
  String get caseEscalationsHeaderTitle;
  String get caseEscalationsHeaderSubtitle;
  String get summaryTotalCaseEscalations;
  String get summaryPendingReview;
  String get summaryUnderReview;
  String get summaryRepeatedVisits;
  String get searchCaseEscalationPlaceholder;
  String get filterReasonAll;
  String get filterReasonDeterioration;
  String get filterReasonRepeatedVisits;
  String get filterReasonHigherAuthority;
  String get filterReasonDoctorConcern;
  String get filterReasonOther;
  String get filterReviewStatusAll;
  String get filterReviewStatusEscalated;
  String get filterReviewStatusUnderReview;
  String get sortCaseOldest;
  String get sortCaseNewest;
  String get sortCaseDepartment;
  String get sortCaseVisitCount;
  String get sortCaseReason;
  String get tableColCaseId;
  String get tableColPatientId;
  String get tableColDepartmentA8;
  String get tableColReason;
  String get tableColSourceVisit;
  String get tableColEscalatedAtA8;
  String get tableColEscalatedBy;
  String get tableColCaseStatus;
  String get tableColReviewStatus;
  String get tableColActionA8;
  String get actionReviewCase;
  String get statusBadgePendingReview;
  String get statusBadgeUnderReview;
  String get caseReviewModalTitle;
  String get caseReviewModalSubtitle;
  String get startReviewButton;
  String get startingReviewButton;
  String get reviewStartedSuccess;
  String get currentlyUnderReviewNotice;
  String get reviewedByLabel;
  String get reviewTimeLabel;
  String get futureWorkspaceNotice;
  String get emptyCaseEscalationsTitle;
  String get emptyCaseEscalationsSubtitle;
  String get errorLoadingCaseEscalations;

  // Phase A9: Escalated Patient Clinical Workspace
  String get escalatedWorkspaceTitle;
  String get escalatedWorkspaceSubtitle;
  String get readOnlyBadge;
  String get backToCaseEscalations;
  String get openClinicalWorkspace;
  String get clinicalCaseEscalationBannerTitle;
  String get escalationBannerSubtitle;
  String get reasonLabel;
  String get escalatedAtLabel;
  String get escalatedByLabel;
  String get sourceVisitLabel;
  String get doctorExplanationLabel;
  String get activeConsultationTitle;
  String get activeConsultationSubtitle;
  String get patientClinicalReview;
  String get patientDetailsSection;
  String get patientIdLabel;
  String get patientNameLabel;
  String get ageGenderLabel;
  String get bloodGroupLabel;
  String get departmentDomainLabel;
  String get caseSummarySection;
  String get caseIdLabel;
  String get caseTitleLabel;
  String get caseStatusLabel;
  String get totalVisitsLabel;
  String get openedDateLabel;
  String get lastVisitLabel;
  String get relevantHistoryLabel;
  String get currentVitalsSection;
  String get heartRateLabel;
  String get spo2Label;
  String get temperatureLabel;
  String get lastRecordedLabel;
  String get caseTimelineSection;
  String get timelineFilterAll;
  String get timelineFilterVisits;
  String get timelineFilterTransfers;
  String get timelineFilterEscalations;
  String get visitHistorySection;
  String get visitLabel;
  String get attendingPhysicianSection;
  String get doctorQualificationLabel;
  String get structuredConsultationSection;
  String get chiefComplaintLabel;
  String get onsetDurationLabel;
  String get associatedSymptomsLabel;
  String get medicalHistoryLabel;
  String get currentMedicationLabel;
  String get clinicalObservationsLabel;
  String get assessmentLabel;
  String get planLabel;
  String get prescriptionsSection;
  String get medicineLabel;
  String get dosageLabel;
  String get durationLabel;
  String get instructionsLabel;
  String get noPrescriptionsRecorded;
  String get doctorApprovedSummarySection;
  String get statusApprovedByDoctor;
  String get statusReviewRequired;
  String get statusDraft;
  String get investigationsReportsSection;
  String get tabRequestedInvestigations;
  String get tabUploadedReports;
  String get tabReviewedReports;
  String get noInvestigationsOrReports;
  String get actionViewReport;
  String get actionOpenReport;
  String get reportFileNameLabel;
  String get reportFileTypeLabel;
  String get reportFileSizeLabel;
  String get reportUploadDateLabel;
  String get planFollowUpSection;
  String get followUpLabel;
  String get patientInstructionsLabel;
  String get visitCompletionSection;
  String get officialVisitPdfLabel;
  String get actionViewVisitPdf;
  String get actionOpenPdf;
  String get noVisitPdfAvailable;
  String get transferHistorySection;
  String get fromDepartmentLabel;
  String get toDepartmentLabel;
  String get sourceDoctorLabel;
  String get destinationDoctorLabel;
  String get transferReasonLabel;
  String get noTransfersRecorded;
  String get escalationGovernanceHistorySection;
  String get reviewStartedByLabel;
  String get reviewStartedAtLabel;
  String get errorLoadingClinicalRecord;
  String get caseNotFoundTitle;
  String get caseNotFoundSubtitle;

  // Phase A10: Higher-Authority Doctor Assignment
  String get higherAuthorityReviewSection;
  String get higherAuthorityAssignmentSection;
  String get assignHigherAuthorityButton;
  String get assigningHigherAuthorityButton;
  String get reassignHigherAuthorityButton;
  String get assignHigherAuthorityDialogTitle;
  String get assignHigherAuthorityDialogSubtitle;
  String get eligibleDoctorsSectionTitle;
  String get sourceDoctorAuthorityLabel;
  String get targetAuthorityLevelLabel;
  String get crossDepartmentTransferOption;
  String get crossDepartmentTransferHelp;
  String get crossDepartmentReasonLabel;
  String get crossDepartmentReasonHint;
  String get confirmAssignmentDialogTitle;
  String get confirmAssignmentDialogMessage;
  String get assignmentSuccessNotification;
  String get noEligibleDoctorsExplanation;
  String get statusBadgeAssigned;
  String get statusBadgeAccepted;
  String get assignedToDoctorLabel;
  String get assignedDoctorCol;
  String get assignedDeptCol;
  String get assignedStatusCol;
  String get assignedAtLabel;
  String get acceptedAtLabel;
  String get assignedByAdminLabel;
  String get assignedByLabel;
  String get assignmentReasonLabel;
  String get assignedToHigherAuthorityBadge;
  String get higherAuthorityCaseBannerTitle;
  String get acceptAssignmentButton;
  String get acceptingAssignmentButton;
  String get assignmentAcceptedSuccess;

  // Generic & Future Placeholders
  String get featureComingSoon;
  String get placeholderNotice;
  String get close;

  factory AdminStrings.fromLocale(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return const _AdminStringsHi();
      case 'mr':
        return const _AdminStringsMr();
      case 'en':
      default:
        return const _AdminStringsEn();
    }
  }
}

/// English localization for Admin Portal
class _AdminStringsEn implements AdminStrings {
  const _AdminStringsEn();

  @override
  String get adminPortalTitle => 'ADMIN PORTAL';
  @override
  String get administrationPortal => 'ADMINISTRATION PORTAL';
  @override
  String get healthcareManagementSystem => 'Healthcare Management System';
  @override
  String get appTagline => 'LIVE BETTER, TOGETHER.';
  @override
  String get centralAdminConsole => 'CENTRAL ADMINISTRATIVE CONSOLE';
  @override
  String get terminalOnline => 'TERMINAL ONLINE';
  @override
  String get protectedAdminSession => 'Protected Hospital Administrative Session';
  @override
  String get touchToBegin => 'TOUCH TO BEGIN';
  @override
  String get touchToBeginSubtitle => 'Click or press Enter to access central administration';

  @override
  String get adminLoginTitle => 'ADMIN LOGIN';
  @override
  String get adminLoginSubtitle => 'Administrative Terminal Access';
  @override
  String get username => 'Username';
  @override
  String get usernameHint => 'Enter admin username';
  @override
  String get password => 'Password';
  @override
  String get passwordHint => 'Enter admin password';
  @override
  String get loginButton => 'LOGIN';
  @override
  String get back => 'BACK';
  @override
  String get emptyUsernameError => 'Please enter your username';
  @override
  String get emptyPasswordError => 'Please enter your password';
  @override
  String get invalidCredentialsError => 'Invalid username or password.';
  @override
  String get authenticating => 'Authenticating...';
  @override
  String get secureSessionNotice => 'All administrative operations are encrypted and audited.';
  @override
  String get level1AdminNotice => 'Level-1 Administrative Authority Required';

  @override
  String get systemAdministrator => 'System Administrator';
  @override
  String get level1Authority => 'Level-1 Authority';
  @override
  String get viewProfile => 'View Profile';
  @override
  String get logout => 'Logout';
  @override
  String get hospitalWorkstation => 'Hospital Administration Console';

  @override
  String get navDashboard => 'Dashboard';
  @override
  String get navDoctors => 'Doctors';
  @override
  String get navAvailability => 'Availability';
  @override
  String get navAppointmentEscalations => 'Appointment Escalations';
  @override
  String get navCaseEscalations => 'Case Escalations';
  @override
  String get adminConsole => 'ADMIN CONSOLE';

  @override
  String get systemOverview => 'SYSTEM OVERVIEW';
  @override
  String get systemOverviewSubtitle => 'Real-time hospital operations snapshot';
  @override
  String get totalDoctors => 'Total Doctors';
  @override
  String get totalDoctorsDesc => 'Registered clinical practitioners';
  @override
  String get availableDoctors => 'Available Doctors';
  @override
  String get availableDoctorsDesc => 'Currently online & accepting patients';
  @override
  String get pendingAppointments => 'Pending Appointments';
  @override
  String get pendingAppointmentsDesc => 'Patients waiting in OPD queues';
  @override
  String get activeEscalations => 'Active Escalations';
  @override
  String get activeEscalationsDesc => 'Requires administrative intervention';
  @override
  String get activeCases => 'Active Cases';
  @override
  String get activeCasesDesc => 'Open clinical cases in system';

  @override
  String get addNewDoctorTitle => 'ADD NEW DOCTOR';
  @override
  String get addNewDoctorDesc => 'Register and provision a new doctor';
  @override
  String get addNewDoctorButton => 'ADD DOCTOR';
  @override
  String get manageDoctorsTitle => 'MANAGE DOCTORS';
  @override
  String get manageDoctorsDesc => 'View and manage registered doctors';
  @override
  String get manageDoctorsButton => 'MANAGE DOCTORS';

  @override
  String get doctorAvailabilityTitle => 'DOCTOR AVAILABILITY';
  @override
  String get doctorAvailabilitySubtitle => 'Domain-level active clinician distribution';
  @override
  String get domainColumn => 'Specialty Domain';
  @override
  String get availableColumn => 'Available';
  @override
  String get onlineColumn => 'Online';
  @override
  String get inConsultationColumn => 'In Consultation';
  @override
  String get totalColumn => 'Total Provisioned';
  @override
  String get statusColumn => 'Status';

  @override
  String get waitingAppointmentsCardTitle => 'WAITING APPOINTMENTS';
  @override
  String get waitingAppointmentsSubtitle => 'Incoming patient consultation requests in OPD queues';
  @override
  String get noWaitingAppointments => 'No patients currently waiting in OPD queues';
  @override
  String get activeCasesCardTitle => 'ACTIVE CLINICAL CASES';
  @override
  String get activeCasesSubtitle => 'Open episodes of care and specialty domain distribution';
  @override
  String get noActiveCases => 'No active clinical cases found';
  @override
  String get casesByDomain => 'Cases by Specialty Domain';
  @override
  String get refresh => 'Refresh';
  @override
  String get refreshing => 'Refreshing...';
  @override
  String get retry => 'RETRY';
  @override
  String get errorLoadingDashboard => 'Unable to load live dashboard data.';

  @override
  String get appointmentEscalationsTitle => 'APPOINTMENT ESCALATIONS';
  @override
  String get appointmentEscalationsSubtitle => 'Appointments waiting without doctor allocation for >20 minutes';
  @override
  String get noAppointmentEscalations => 'No appointment escalations';
  @override
  String get noAppointmentEscalationsDesc => 'All patient appointments are currently assigned within normal threshold';

  @override
  String get caseEscalationsTitle => 'CASE ESCALATIONS';
  @override
  String get caseEscalationsSubtitle => 'Cases requiring administrative intervention due to deterioration or repeated visits';
  @override
  String get noCaseEscalations => 'No active case escalations';
  @override
  String get noCaseEscalationsDesc => 'All clinical cases are proceeding without administrative alerts';

  // A4 Doctor Provisioning Form & Success Screen
  @override
  String get addNewDoctorSubtitle => 'Provision a secure Doctor Portal account.';
  @override
  String get backToDashboard => 'Back to Dashboard';
  @override
  String get doctorInformationSection => 'DOCTOR INFORMATION';
  @override
  String get fullNameLabel => 'FULL NAME';
  @override
  String get fullNamePlaceholder => 'Dr. Rahul Sharma';
  @override
  String get registeredPhoneLabel => 'REGISTERED MOBILE NUMBER';
  @override
  String get registeredPhonePlaceholder => '9876543210';
  @override
  String get qualificationLabel => 'QUALIFICATION / DEGREE';
  @override
  String get qualificationPlaceholder => 'MBBS, MD';
  @override
  String get departmentLabel => 'DEPARTMENT / DOMAIN';
  @override
  String get selectDepartmentHint => 'Select specialty department';
  @override
  String get optionalEmailLabel => 'EMAIL (OPTIONAL)';
  @override
  String get optionalEmailPlaceholder => 'doctor@hospital.aayusathi.in';
  @override
  String get createDoctorButton => 'CREATE DOCTOR';
  @override
  String get creatingDoctorButton => 'CREATING DOCTOR ACCOUNT...';
  @override
  String get doctorCreatedTitle => 'DOCTOR ACCOUNT CREATED';
  @override
  String get doctorCreatedSubtitle => 'Physician provisioned and credentialed for the Doctor Portal.';
  @override
  String get generatedDoctorIdLabel => 'Doctor ID';
  @override
  String get generatedPasswordLabel => 'Temporary Password';
  @override
  String get savePasswordWarning => 'Save this temporary password securely. It will not be displayed again.';
  @override
  String get copyDoctorIdButton => 'COPY DOCTOR ID';
  @override
  String get copyPasswordButton => 'COPY PASSWORD';
  @override
  String get copiedFeedback => 'Copied';
  @override
  String get addAnotherDoctorButton => 'ADD ANOTHER DOCTOR';
  @override
  String get doneButton => 'DONE';

  // A5 Manage Doctors Strings
  @override
  String get manageDoctorsHeaderTitle => 'MANAGE DOCTORS';
  @override
  String get manageDoctorsHeaderSubtitle => 'Physician registry, access governance, and credential records.';
  @override
  String get searchDoctorPlaceholder => 'Search by Doctor ID, name, or phone...';
  @override
  String get filterAllDepartments => 'All Departments';
  @override
  String get filterAllStatuses => 'All Statuses';
  @override
  String get statusActive => 'Active';
  @override
  String get statusInactive => 'Inactive';
  @override
  String get sortBy => 'Sort by';
  @override
  String get sortNewest => 'Newest First';
  @override
  String get sortNameAsc => 'Name (A-Z)';
  @override
  String get sortDepartment => 'Department';
  @override
  String get sortStatus => 'Status';
  @override
  String get totalDoctorsCount => 'Total Provisioned';
  @override
  String get activeDoctorsCount => 'Active Doctors';
  @override
  String get inactiveDoctorsCount => 'Deactivated Doctors';
  @override
  String get noDoctorsFound => 'No doctors match your query';
  @override
  String get noDoctorsFoundSubtitle => 'Try changing your search terms or clearing the active department/status filters.';
  @override
  String get tableColDoctorId => 'Doctor ID';
  @override
  String get tableColName => 'Doctor Name';
  @override
  String get tableColDepartment => 'Department';
  @override
  String get tableColPhone => 'Mobile';
  @override
  String get tableColStatus => 'Status';
  @override
  String get tableColActions => 'Actions';
  @override
  String get actionViewDetails => 'View Details';
  @override
  String get actionEditDoctor => 'Edit Profile';
  @override
  String get actionDeactivate => 'Deactivate';
  @override
  String get actionActivate => 'Activate';
  @override
  String get doctorDetailsModalTitle => 'PHYSICIAN PROFILE RECORD';
  @override
  String get doctorDetailsModalSubtitle => 'Verified clinician credentials and hospital registration data.';
  @override
  String get doctorEditModalTitle => 'EDIT DOCTOR PROFILE';
  @override
  String get doctorEditModalSubtitle => 'Update clinician contact details or clinical department.';
  @override
  String get doctorDeactivateModalTitle => 'DEACTIVATE DOCTOR ACCOUNT';
  @override
  String get doctorActivateModalTitle => 'ACTIVATE DOCTOR ACCOUNT';
  @override
  String get doctorDeactivateConfirmMessage => 'Are you sure you want to deactivate this doctor? The physician will no longer be able to log in or accept patient appointments.';
  @override
  String get doctorActivateConfirmMessage => 'Are you sure you want to reactivate this doctor? The physician will be able to log in and accept clinical consultations.';
  @override
  String get consultationBlockedWarning => 'Doctor is currently IN CONSULTATION. Cannot deactivate or transfer department during active clinical care.';
  @override
  String get departmentChangeWarning => 'Changing the doctor\'s department affects future appointment routing. Historical clinical records remain unchanged.';
  @override
  String get saveChangesButton => 'SAVE CHANGES';
  @override
  String get savingChangesButton => 'SAVING CHANGES...';
  @override
  String get confirmButton => 'CONFIRM';
  @override
  String get cancelButton => 'CANCEL';
  @override
  String get doctorUpdatedSuccess => 'Doctor profile updated successfully.';
  @override
  String get doctorStatusUpdatedSuccess => 'Doctor status updated successfully.';
  @override
  String get viewFullHistory => 'Historical Records Intact';

  // Phase A6: Doctor Availability Management
  @override
  String get availabilityHeaderTitle => 'DOCTOR AVAILABILITY';
  @override
  String get availabilityHeaderSubtitle => 'Monitor and manage real-time Doctor workstation availability.';
  @override
  String get viewAllDoctors => 'VIEW ALL DOCTORS';
  @override
  String get totalActiveDoctors => 'TOTAL ACTIVE DOCTORS';
  @override
  String get onlineAvailable => 'ONLINE / AVAILABLE';
  @override
  String get inConsultation => 'IN CONSULTATION';
  @override
  String get offline => 'OFFLINE';
  @override
  String get domainCapacityTitle => 'CLINICAL DOMAIN CAPACITY';
  @override
  String get searchAvailabilityPlaceholder => 'Search by Doctor Name, ID, or Department...';
  @override
  String get filterAvailabilityAll => 'All Availability';
  @override
  String get filterAvailabilityOffline => 'Offline';
  @override
  String get filterAvailabilityAvailable => 'Available';
  @override
  String get filterAvailabilityInConsultation => 'In Consultation';
  @override
  String get sortAvailability => 'Availability';
  @override
  String get sortLastActivity => 'Last Activity';
  @override
  String get tableColDoctor => 'DOCTOR';
  @override
  String get tableColDoctorIdA6 => 'DOCTOR ID';
  @override
  String get tableColDepartmentA6 => 'DEPARTMENT';
  @override
  String get tableColAccount => 'ACCOUNT';
  @override
  String get tableColAvailability => 'AVAILABILITY';
  @override
  String get tableColLastActivity => 'LAST ACTIVITY';
  @override
  String get actionSetAvailable => 'SET AVAILABLE';
  @override
  String get actionSetOffline => 'SET OFFLINE';
  @override
  String get actionDoctorInConsultation => 'DOCTOR IN CONSULTATION';
  @override
  String get setAvailableModalTitle => 'SET DOCTOR AS AVAILABLE';
  @override
  String get setAvailableConfirmMessage => 'This will make the Doctor eligible for new appointment requests.';
  @override
  String get setOfflineModalTitle => 'SET DOCTOR OFFLINE';
  @override
  String get setOfflineConfirmMessage => 'The Doctor will no longer receive new appointment requests.';
  @override
  String get consultationLockedTitle => 'DOCTOR IN CONSULTATION';
  @override
  String get consultationLockedMessage => 'Availability cannot be manually changed while the Doctor is consulting a patient.';
  @override
  String get noActiveDoctorsTitle => 'NO ACTIVE DOCTORS';
  @override
  String get noActiveDoctorsSubtitle => 'Provision a Doctor through Add New Doctor.';
  @override
  String get errorLoadingAvailability => 'Unable to load Doctor availability.';
  @override
  String get doctorSetAvailableSuccess => 'Doctor marked as Available.';
  @override
  String get doctorSetOfflineSuccess => 'Doctor marked as Offline.';

  // Phase A7: Appointment Escalations
  @override
  String get appointmentEscalationsHeaderTitle => 'APPOINTMENT ESCALATIONS';
  @override
  String get appointmentEscalationsHeaderSubtitle => 'Appointments waiting longer than 20 minutes require administrative attention.';
  @override
  String get summaryEscalatedAppointments => 'Escalated Appointments';
  @override
  String get summaryWaitingAppointments => 'Waiting Appointments';
  @override
  String get summaryResolvedToday => 'Resolved Today';
  @override
  String get searchEscalationPlaceholder => 'Search by Queue Number or Appointment ID...';
  @override
  String get filterStatusAll => 'All Statuses';
  @override
  String get filterStatusEscalated => 'Escalated';
  @override
  String get filterStatusWaiting => 'Waiting';
  @override
  String get filterStatusResolved => 'Assigned / Resolved';
  @override
  String get sortOldestWaiting => 'Oldest Waiting';
  @override
  String get sortEscalationTime => 'Escalation Time';
  @override
  String get tableColQueue => 'QUEUE';
  @override
  String get tableColAppointmentId => 'APPOINTMENT ID';
  @override
  String get tableColDepartmentA7 => 'DEPARTMENT';
  @override
  String get tableColWaitingSince => 'WAITING SINCE';
  @override
  String get tableColWaitingDuration => 'WAITING DURATION';
  @override
  String get tableColEscalatedAt => 'ESCALATED AT';
  @override
  String get tableColCurrentStatus => 'CURRENT STATUS';
  @override
  String get tableColAction => 'ACTION';
  @override
  String get actionAssignDoctor => 'ASSIGN DOCTOR';
  @override
  String get actionInspectDetails => 'VIEW DETAILS';
  @override
  String get statusBadgeEscalated => 'ESCALATED';
  @override
  String get statusBadgeWaiting => 'WAITING';
  @override
  String get statusBadgeResolved => 'RESOLVED';
  @override
  String get detailsModalTitle => 'APPOINTMENT ESCALATION DETAILS';
  @override
  String get detailsModalSubtitle => 'Review clinical queue SLA and patient triage parameters.';
  @override
  String get assignDoctorModalTitle => 'MANUAL DOCTOR ASSIGNMENT';
  @override
  String get assignDoctorModalSubtitle => 'Select an eligible available physician to handle this escalated appointment.';
  @override
  String get eligibleDoctorsFound => 'Eligible Doctors';
  @override
  String get noEligibleDoctorsTitle => 'NO AVAILABLE DOCTORS';
  @override
  String get noEligibleDoctorsMessage => 'There are currently no active, available doctors in this specialty department.';
  @override
  String get confirmAssignmentButton => 'CONFIRM ASSIGNMENT';
  @override
  String get assigningButton => 'ASSIGNING DOCTOR...';
  @override
  String get assignmentSuccessMessage => 'Doctor assigned successfully.';
  @override
  String get assignmentFailedMessage => 'Assignment could not be completed because the appointment state changed. Please review the current status.';
  @override
  String get doctorUnavailableError => 'Doctor is no longer available. Please select another doctor.';
  @override
  String get previousDoctorRestrictionWarning => 'This appointment is specifically requested for the previous doctor and cannot be reassigned to another physician.';
  @override
  String get emptyEscalationsTitle => 'No appointment escalations';
  @override
  String get emptyEscalationsSubtitle => 'All waiting appointments are within the standard 20-minute response window.';
  @override
  String get errorLoadingEscalations => 'Unable to load appointment escalations.';

  // Phase A8: Case Escalations (English)
  @override
  String get caseEscalationsHeaderTitle => 'CLINICAL CASE ESCALATIONS';
  @override
  String get caseEscalationsHeaderSubtitle => 'Physician-escalated clinical cases requiring higher-authority administrative governance.';
  @override
  String get summaryTotalCaseEscalations => 'TOTAL ESCALATIONS';
  @override
  String get summaryPendingReview => 'PENDING REVIEW';
  @override
  String get summaryUnderReview => 'UNDER REVIEW';
  @override
  String get summaryRepeatedVisits => 'REPEATED VISITS';
  @override
  String get searchCaseEscalationPlaceholder => 'Search by Case ID, Patient ID, or Doctor ID...';
  @override
  String get filterReasonAll => 'All Reasons';
  @override
  String get filterReasonDeterioration => 'Clinical Deterioration';
  @override
  String get filterReasonRepeatedVisits => 'Repeated Visits';
  @override
  String get filterReasonHigherAuthority => 'Higher Authority Review';
  @override
  String get filterReasonDoctorConcern => 'Doctor Concern';
  @override
  String get filterReasonOther => 'Other';
  @override
  String get filterReviewStatusAll => 'All Statuses';
  @override
  String get filterReviewStatusEscalated => 'Escalated (Pending)';
  @override
  String get filterReviewStatusUnderReview => 'Under Review';
  @override
  String get sortCaseOldest => 'Oldest Escalation';
  @override
  String get sortCaseNewest => 'Newest Escalation';
  @override
  String get sortCaseDepartment => 'Department';
  @override
  String get sortCaseVisitCount => 'Visit Count';
  @override
  String get sortCaseReason => 'Escalation Reason';
  @override
  String get tableColCaseId => 'CASE ID';
  @override
  String get tableColPatientId => 'PATIENT ID';
  @override
  String get tableColDepartmentA8 => 'DEPARTMENT';
  @override
  String get tableColReason => 'REASON';
  @override
  String get tableColSourceVisit => 'SOURCE VISIT';
  @override
  String get tableColEscalatedAtA8 => 'ESCALATED AT';
  @override
  String get tableColEscalatedBy => 'ESCALATED BY';
  @override
  String get tableColCaseStatus => 'CASE STATUS';
  @override
  String get tableColReviewStatus => 'REVIEW STATUS';
  @override
  String get tableColActionA8 => 'ACTION';
  @override
  String get actionReviewCase => 'REVIEW';
  @override
  String get statusBadgePendingReview => 'PENDING REVIEW';
  @override
  String get statusBadgeUnderReview => 'UNDER REVIEW';
  @override
  String get caseReviewModalTitle => 'CASE ESCALATION REVIEW';
  @override
  String get caseReviewModalSubtitle => 'Clinical escalation metadata and administrative review assessment.';
  @override
  String get startReviewButton => 'START REVIEW';
  @override
  String get startingReviewButton => 'STARTING REVIEW...';
  @override
  String get reviewStartedSuccess => 'Case marked as under administrative review.';
  @override
  String get currentlyUnderReviewNotice => 'Currently Under Administrative Review';
  @override
  String get reviewedByLabel => 'Review Started By';
  @override
  String get reviewTimeLabel => 'Review Started At';
  @override
  String get futureWorkspaceNotice => 'Full clinical review workspace will be available in the next phase (A9).';
  @override
  String get emptyCaseEscalationsTitle => 'No clinical case escalations';
  @override
  String get emptyCaseEscalationsSubtitle => 'No physician-escalated clinical cases match the current filter criteria.';
  @override
  String get errorLoadingCaseEscalations => 'Unable to load clinical case escalations.';

  // Phase A9: Escalated Patient Clinical Workspace (English)
  @override
  String get escalatedWorkspaceTitle => 'PATIENT CLINICAL REVIEW';
  @override
  String get escalatedWorkspaceSubtitle => 'Longitudinal clinical record inspection for escalated case governance.';
  @override
  String get readOnlyBadge => 'READ ONLY';
  @override
  String get backToCaseEscalations => 'BACK TO CASE ESCALATIONS';
  @override
  String get openClinicalWorkspace => 'OPEN CLINICAL WORKSPACE';
  @override
  String get clinicalCaseEscalationBannerTitle => 'CLINICAL CASE ESCALATION';
  @override
  String get escalationBannerSubtitle => 'This case was escalated by the attending physician for Higher Authority Review.';
  @override
  String get reasonLabel => 'Reason';
  @override
  String get escalatedAtLabel => 'Escalated At';
  @override
  String get escalatedByLabel => 'Escalated By';
  @override
  String get sourceVisitLabel => 'Source Visit';
  @override
  String get doctorExplanationLabel => 'Physician Explanation / Clinical Note';
  @override
  String get activeConsultationTitle => 'CONSULTATION ACTIVE';
  @override
  String get activeConsultationSubtitle => 'An active clinical consultation is currently in progress for this patient.';
  @override
  String get patientClinicalReview => 'PATIENT CLINICAL REVIEW';
  @override
  String get patientDetailsSection => 'PATIENT IDENTITY';
  @override
  String get patientIdLabel => 'Patient ID';
  @override
  String get patientNameLabel => 'Patient Name';
  @override
  String get ageGenderLabel => 'Age / Gender';
  @override
  String get bloodGroupLabel => 'Blood Group';
  @override
  String get departmentDomainLabel => 'Department';
  @override
  String get caseSummarySection => 'CASE SUMMARY';
  @override
  String get caseIdLabel => 'Case ID';
  @override
  String get caseTitleLabel => 'Case Title';
  @override
  String get caseStatusLabel => 'Case Status';
  @override
  String get totalVisitsLabel => 'Total Visits';
  @override
  String get openedDateLabel => 'Opened Date';
  @override
  String get lastVisitLabel => 'Last Visit';
  @override
  String get relevantHistoryLabel => 'Previous Relevant History';
  @override
  String get currentVitalsSection => 'CURRENT VITALS';
  @override
  String get heartRateLabel => 'Heart Rate';
  @override
  String get spo2Label => 'SpO2';
  @override
  String get temperatureLabel => 'Temperature';
  @override
  String get lastRecordedLabel => 'Recorded';
  @override
  String get caseTimelineSection => 'CASE TIMELINE';
  @override
  String get timelineFilterAll => 'All Events';
  @override
  String get timelineFilterVisits => 'Visits';
  @override
  String get timelineFilterTransfers => 'Transfers';
  @override
  String get timelineFilterEscalations => 'Escalations';
  @override
  String get visitHistorySection => 'VISIT HISTORY';
  @override
  String get visitLabel => 'Visit';
  @override
  String get attendingPhysicianSection => 'Attending Physician';
  @override
  String get doctorQualificationLabel => 'Qualification';
  @override
  String get structuredConsultationSection => 'Structured Consultation (8 Clinical Fields)';
  @override
  String get chiefComplaintLabel => 'Chief Complaint';
  @override
  String get onsetDurationLabel => 'Onset / Duration';
  @override
  String get associatedSymptomsLabel => 'Associated Symptoms';
  @override
  String get medicalHistoryLabel => 'Medical History';
  @override
  String get currentMedicationLabel => 'Current Medication';
  @override
  String get clinicalObservationsLabel => 'Clinical Observations';
  @override
  String get assessmentLabel => 'Assessment';
  @override
  String get planLabel => 'Plan';
  @override
  String get prescriptionsSection => 'Prescriptions';
  @override
  String get medicineLabel => 'Medicine';
  @override
  String get dosageLabel => 'Dosage / Times';
  @override
  String get durationLabel => 'Duration';
  @override
  String get instructionsLabel => 'Instructions';
  @override
  String get noPrescriptionsRecorded => 'No medications prescribed for this visit.';
  @override
  String get doctorApprovedSummarySection => 'Doctor-Approved Visit Summary';
  @override
  String get statusApprovedByDoctor => 'APPROVED BY DOCTOR';
  @override
  String get statusReviewRequired => 'REVIEW REQUIRED';
  @override
  String get statusDraft => 'DRAFT';
  @override
  String get investigationsReportsSection => 'Diagnostic Investigations & Reports';
  @override
  String get tabRequestedInvestigations => 'Requested';
  @override
  String get tabUploadedReports => 'Uploaded Reports';
  @override
  String get tabReviewedReports => 'Reviewed';
  @override
  String get noInvestigationsOrReports => 'No diagnostic reports or investigations recorded for this visit.';
  @override
  String get actionViewReport => 'VIEW REPORT';
  @override
  String get actionOpenReport => 'OPEN FILE';
  @override
  String get reportFileNameLabel => 'File Name';
  @override
  String get reportFileTypeLabel => 'File Type';
  @override
  String get reportFileSizeLabel => 'File Size';
  @override
  String get reportUploadDateLabel => 'Uploaded';
  @override
  String get planFollowUpSection => 'Plan & Follow-up';
  @override
  String get followUpLabel => 'Follow-up Advice';
  @override
  String get patientInstructionsLabel => 'Patient Instructions';
  @override
  String get visitCompletionSection => 'Visit Completion & Documentation';
  @override
  String get officialVisitPdfLabel => 'Official AAYUSATHI Visit Documentation PDF';
  @override
  String get actionViewVisitPdf => 'VIEW VISIT PDF';
  @override
  String get actionOpenPdf => 'OPEN PDF';
  @override
  String get noVisitPdfAvailable => 'Visit PDF not yet generated for this active encounter.';
  @override
  String get transferHistorySection => 'INTER-DEPARTMENT TRANSFER HISTORY';
  @override
  String get fromDepartmentLabel => 'From Department';
  @override
  String get toDepartmentLabel => 'To Department';
  @override
  String get sourceDoctorLabel => 'Source Doctor';
  @override
  String get destinationDoctorLabel => 'Destination Doctor';
  @override
  String get transferReasonLabel => 'Transfer Reason';
  @override
  String get noTransfersRecorded => 'No inter-department transfers recorded for this case.';
  @override
  String get escalationGovernanceHistorySection => 'ESCALATION & GOVERNANCE HISTORY';
  @override
  String get reviewStartedByLabel => 'Review Started By';
  @override
  String get reviewStartedAtLabel => 'Review Started At';
  @override
  String get errorLoadingClinicalRecord => 'Unable to load clinical record.';
  @override
  String get caseNotFoundTitle => 'Case Not Found';
  @override
  String get caseNotFoundSubtitle => 'The requested clinical case could not be located in the repository.';

  // Phase A10: Higher-Authority Doctor Assignment (English)
  @override
  String get higherAuthorityReviewSection => 'HIGHER-AUTHORITY CLINICAL ASSIGNMENT';
  @override
  String get higherAuthorityAssignmentSection => 'HIGHER-AUTHORITY CLINICAL ASSIGNMENT';
  @override
  String get assignHigherAuthorityButton => 'ASSIGN HIGHER AUTHORITY';
  @override
  String get assigningHigherAuthorityButton => 'ASSIGNING...';
  @override
  String get reassignHigherAuthorityButton => 'REASSIGN HIGHER AUTHORITY';
  @override
  String get assignHigherAuthorityDialogTitle => 'ASSIGN HIGHER-AUTHORITY DOCTOR';
  @override
  String get assignHigherAuthorityDialogSubtitle => 'Select an authorized senior physician or department specialist to assume governance of this escalated clinical case.';
  @override
  String get eligibleDoctorsSectionTitle => 'ELIGIBLE HIGHER-AUTHORITY PHYSICIANS';
  @override
  String get sourceDoctorAuthorityLabel => 'Source Authority';
  @override
  String get targetAuthorityLevelLabel => 'Authority Level';
  @override
  String get crossDepartmentTransferOption => 'Transfer to another clinical department';
  @override
  String get crossDepartmentTransferHelp => 'Enable if specialist review requires an inter-departmental transfer.';
  @override
  String get crossDepartmentReasonLabel => 'Transfer Reason & Administrative Rationale';
  @override
  String get crossDepartmentReasonHint => 'Enter clinical justification for cross-specialty higher-authority assignment...';
  @override
  String get confirmAssignmentDialogTitle => 'Confirm Higher-Authority Assignment';
  @override
  String get confirmAssignmentDialogMessage => 'Are you sure you want to assign this clinical case to the selected higher-authority doctor? The case continuity, visits, and clinical records will remain intact.';
  @override
  String get assignmentSuccessNotification => 'Case successfully assigned to higher-authority doctor.';
  @override
  String get noEligibleDoctorsExplanation => 'An active doctor with clinical authority higher than the escalating physician and AVAILABLE presence is required.';
  @override
  String get statusBadgeAssigned => 'HIGHER AUTHORITY ASSIGNED';
  @override
  String get statusBadgeAccepted => 'ASSIGNMENT ACCEPTED';
  @override
  String get assignedToDoctorLabel => 'Assigned Doctor';
  @override
  String get assignedDoctorCol => 'Assigned Doctor';
  @override
  String get assignedDeptCol => 'Department';
  @override
  String get assignedStatusCol => 'Assignment Status';
  @override
  String get assignedAtLabel => 'Assigned At';
  @override
  String get acceptedAtLabel => 'Accepted At';
  @override
  String get assignedByAdminLabel => 'Assigned By';
  @override
  String get assignedByLabel => 'Assigned By';
  @override
  String get assignmentReasonLabel => 'Assignment Reason';
  @override
  String get assignedToHigherAuthorityBadge => 'HIGHER AUTHORITY ASSIGNED';
  @override
  String get higherAuthorityCaseBannerTitle => 'ESCALATED CASE ASSIGNED FOR HIGHER-AUTHORITY REVIEW';
  @override
  String get acceptAssignmentButton => 'ACCEPT CASE';
  @override
  String get acceptingAssignmentButton => 'ACCEPTING...';
  @override
  String get assignmentAcceptedSuccess => 'Higher-authority case assignment accepted.';

  @override
  String get featureComingSoon => 'This feature will be available in the next administrative phase.';
  @override
  String get placeholderNotice => 'Phase A1 Architectural Preview';
  @override
  String get close => 'Close';
}

/// Hindi localization for Admin Portal
class _AdminStringsHi extends _AdminStringsEn {
  const _AdminStringsHi();

  @override
  String get adminPortalTitle => 'प्रशासन पोर्टल';
  @override
  String get administrationPortal => 'प्रशासन पोर्टल';
  @override
  String get healthcareManagementSystem => 'स्वास्थ्य सेवा प्रबंधन प्रणाली';
  @override
  String get centralAdminConsole => 'केंद्रीय प्रशासनिक कंसोल';
  @override
  String get touchToBegin => 'शुरू करने के लिए स्पर्श करें';
  @override
  String get adminLoginTitle => 'प्रशासक लॉगिन';
  @override
  String get username => 'उपयोगकर्ता नाम';
  @override
  String get password => 'पासवर्ड';
  @override
  String get loginButton => 'लॉगिन';
  @override
  String get back => 'वापस';
  @override
  String get navDashboard => 'डैशबोर्ड';
  @override
  String get navDoctors => 'डॉक्टर';
  @override
  String get navAvailability => 'उपलब्धता';
  @override
  String get navAppointmentEscalations => 'अपॉइंटमेंट एस्केलेशन';
  @override
  String get navCaseEscalations => 'केस एस्केलेशन';
  @override
  String get systemOverview => 'प्रणाली अवलोकन';
  @override
  String get totalDoctors => 'कुल डॉक्टर';
  @override
  String get availableDoctors => 'उपलब्ध डॉक्टर';
  @override
  String get pendingAppointments => 'लंबित अपॉइंटमेंट';
  @override
  String get activeEscalations => 'सक्रिय एस्केलेशन';
  @override
  String get activeCases => 'सक्रिय केस';
  @override
  String get activeCasesDesc => 'प्रणाली में खुले नैदानिक मामले';
  @override
  String get noAppointmentEscalations => 'कोई अपॉइंटमेंट एस्केलेशन नहीं';
  @override
  String get noCaseEscalations => 'कोई सक्रिय केस एस्केलेशन नहीं';
  @override
  String get manageDoctorsHeaderTitle => 'डॉक्टर प्रबंधन';
  @override
  String get searchDoctorPlaceholder => 'डॉक्टर आईडी, नाम या फोन से खोजें...';
  @override
  String get statusActive => 'सक्रिय';
  @override
  String get statusInactive => 'निष्क्रिय';
  @override
  String get noDoctorsFound => 'कोई डॉक्टर नहीं मिला';
  @override
  String get actionViewDetails => 'विवरण देखें';
  @override
  String get actionEditDoctor => 'प्रोफ़ाइल संपादित करें';
  @override
  String get actionDeactivate => 'निष्क्रिय करें';
  @override
  String get actionActivate => 'सक्रिय करें';
  @override
  String get saveChangesButton => 'परिवर्तन सहेजें';
  @override
  String get confirmButton => 'पुष्टि करें';
  @override
  String get cancelButton => 'रद्द करें';
  @override
  String get availabilityHeaderTitle => 'डॉक्टर उपलब्धता';
  @override
  String get availabilityHeaderSubtitle => 'वास्तविक समय में डॉक्टर वर्कस्टेशन उपलब्धता की निगरानी और प्रबंधन करें।';
  @override
  String get viewAllDoctors => 'सभी डॉक्टर देखें';
  @override
  String get totalActiveDoctors => 'कुल सक्रिय डॉक्टर';
  @override
  String get onlineAvailable => 'ऑनलाइन / उपलब्ध';
  @override
  String get inConsultation => 'परामर्श में';
  @override
  String get offline => 'ऑफलाइन';
  @override
  String get actionSetAvailable => 'उपलब्ध सेट करें';
  @override
  String get actionSetOffline => 'ऑफलाइन सेट करें';
  @override
  String get actionDoctorInConsultation => 'डॉक्टर परामर्श में हैं';
  @override
  String get errorLoadingAvailability => 'डॉक्टर उपलब्धता लोड करने में असमर्थ।';

  // Phase A7: Hindi
  @override
  String get appointmentEscalationsHeaderTitle => 'अपॉइंटमेंट एस्केलेशन';
  @override
  String get appointmentEscalationsHeaderSubtitle => '20 मिनट से अधिक समय से प्रतीक्षारत अपॉइंटमेंट पर प्रशासनिक ध्यान देने की आवश्यकता है।';
  @override
  String get summaryEscalatedAppointments => 'एस्केलेटेड अपॉइंटमेंट्स';
  @override
  String get summaryWaitingAppointments => 'प्रतीक्षारत अपॉइंटमेंट्स';
  @override
  String get summaryResolvedToday => 'आज हल किए गए';
  @override
  String get searchEscalationPlaceholder => 'कतार संख्या या अपॉइंटमेंट आईडी से खोजें...';
  @override
  String get filterStatusAll => 'सभी स्थितियां';
  @override
  String get filterStatusEscalated => 'एस्केलेटेड';
  @override
  String get filterStatusWaiting => 'प्रतीक्षारत';
  @override
  String get filterStatusResolved => 'असाइन किया गया / हल किया गया';
  @override
  String get sortOldestWaiting => 'सबसे पुराना प्रतीक्षारत';
  @override
  String get sortEscalationTime => 'एस्केलेशन समय';
  @override
  String get tableColQueue => 'कतार';
  @override
  String get tableColAppointmentId => 'अपॉइंटमेंट आईडी';
  @override
  String get tableColDepartmentA7 => 'विभाग';
  @override
  String get tableColWaitingSince => 'प्रतीक्षा समय से';
  @override
  String get tableColWaitingDuration => 'प्रतीक्षा अवधि';
  @override
  String get tableColEscalatedAt => 'एस्केलेट हुआ';
  @override
  String get tableColCurrentStatus => 'वर्तमान स्थिति';
  @override
  String get tableColAction => 'कार्रवाई';
  @override
  String get actionAssignDoctor => 'डॉक्टर असाइन करें';
  @override
  String get actionInspectDetails => 'विवरण देखें';
  @override
  String get statusBadgeEscalated => 'एस्केलेटेड';
  @override
  String get statusBadgeWaiting => 'प्रतीक्षारत';
  @override
  String get statusBadgeResolved => 'हल किया गया';
  @override
  String get detailsModalTitle => 'अपॉइंटमेंट एस्केलेशन विवरण';
  @override
  String get detailsModalSubtitle => 'नैदानिक कतार एसएलए और रोगी ट्राइएज मानकों की समीक्षा करें।';
  @override
  String get assignDoctorModalTitle => 'मैन्युअल डॉक्टर असाइनमेंट';
  @override
  String get assignDoctorModalSubtitle => 'इस एस्केलेटेड अपॉइंटमेंट के लिए एक योग्य उपलब्ध डॉक्टर का चयन करें।';
  @override
  String get eligibleDoctorsFound => 'योग्य डॉक्टर';
  @override
  String get noEligibleDoctorsTitle => 'कोई डॉक्टर उपलब्ध नहीं';
  @override
  String get noEligibleDoctorsMessage => 'इस विशेषता विभाग में वर्तमान में कोई सक्रिय, उपलब्ध डॉक्टर नहीं हैं।';
  @override
  String get confirmAssignmentButton => 'असाइनमेंट की पुष्टि करें';
  @override
  String get assigningButton => 'डॉक्टर असाइन किया जा रहा है...';
  @override
  String get assignmentSuccessMessage => 'डॉक्टर सफलतापूर्वक असाइन किया गया।';
  @override
  String get assignmentFailedMessage => 'अपॉइंटमेंट की स्थिति बदलने के कारण असाइनमेंट पूरा नहीं हो सका।';
  @override
  String get doctorUnavailableError => 'डॉक्टर अब उपलब्ध नहीं हैं। कृपया किसी अन्य डॉक्टर का चयन करें।';
  @override
  String get previousDoctorRestrictionWarning => 'यह अपॉइंटमेंट विशेष रूप से पिछले डॉक्टर के लिए अनुरोधित है और इसे पुनः असाइन नहीं किया जा सकता है।';
  @override
  String get emptyEscalationsTitle => 'कोई अपॉइंटमेंट एस्केलेशन नहीं';
  @override
  String get emptyEscalationsSubtitle => 'सभी प्रतीक्षारत अपॉइंटमेंट्स 20 मिनट की मानक प्रतिक्रिया सीमा के भीतर हैं।';
  @override
  String get errorLoadingEscalations => 'अपॉइंटमेंट एस्केलेशन लोड करने में असमर्थ।';

  // Phase A8: Case Escalations (Hindi)
  @override
  String get caseEscalationsHeaderTitle => 'क्लिनिकल केस एस्केलेशन';
  @override
  String get caseEscalationsHeaderSubtitle => 'चिकित्सक द्वारा एस्केलेट किए गए केस एवं प्रशासनिक समीक्षा कतार।';
  @override
  String get summaryTotalCaseEscalations => 'कुल एस्केलेशन';
  @override
  String get summaryPendingReview => 'लंबित समीक्षा';
  @override
  String get summaryUnderReview => 'समीक्षाधीन';
  @override
  String get summaryRepeatedVisits => 'बार-बार विज़िट';
  @override
  String get searchCaseEscalationPlaceholder => 'केस आईडी, मरीज़ आईडी या डॉक्टर आईडी से खोजें...';
  @override
  String get filterReasonAll => 'सभी कारण';
  @override
  String get filterReasonDeterioration => 'क्लिनिकल गिरावट';
  @override
  String get filterReasonRepeatedVisits => 'बार-बार विज़िट';
  @override
  String get filterReasonHigherAuthority => 'उच्च प्राधिकारी समीक्षा';
  @override
  String get filterReasonDoctorConcern => 'डॉक्टर चिंता';
  @override
  String get filterReasonOther => 'अन्य';
  @override
  String get filterReviewStatusAll => 'सभी स्थितियाँ';
  @override
  String get filterReviewStatusEscalated => 'एस्केलेटेड (लंबित)';
  @override
  String get filterReviewStatusUnderReview => 'समीक्षाधीन';
  @override
  String get sortCaseOldest => 'सबसे पुराना एस्केलेशन';
  @override
  String get sortCaseNewest => 'नवीनतम एस्केलेशन';
  @override
  String get sortCaseDepartment => 'विभाग';
  @override
  String get sortCaseVisitCount => 'विज़िट संख्या';
  @override
  String get sortCaseReason => 'एस्केलेशन कारण';
  @override
  String get tableColCaseId => 'केस आईडी';
  @override
  String get tableColPatientId => 'मरीज़ आईडी';
  @override
  String get tableColDepartmentA8 => 'विभाग';
  @override
  String get tableColReason => 'कारण';
  @override
  String get tableColSourceVisit => 'स्रोत विज़िट';
  @override
  String get tableColEscalatedAtA8 => 'एस्केलेट समय';
  @override
  String get tableColEscalatedBy => 'द्वारा एस्केलेट';
  @override
  String get tableColCaseStatus => 'केस स्थिति';
  @override
  String get tableColReviewStatus => 'समीक्षा स्थिति';
  @override
  String get tableColActionA8 => 'कार्रवाई';
  @override
  String get actionReviewCase => 'समीक्षा करें';
  @override
  String get statusBadgePendingReview => 'लंबित समीक्षा';
  @override
  String get statusBadgeUnderReview => 'समीक्षाधीन';
  @override
  String get caseReviewModalTitle => 'केस एस्केलेशन समीक्षा';
  @override
  String get caseReviewModalSubtitle => 'क्लिनिकल एस्केलेशन मेटाडेटा एवं प्रशासनिक समीक्षा आकलन।';
  @override
  String get startReviewButton => 'समीक्षा शुरू करें';
  @override
  String get startingReviewButton => 'समीक्षा शुरू की जा रही है...';
  @override
  String get reviewStartedSuccess => 'केस प्रशासनिक समीक्षा के अधीन चिह्नित किया गया।';
  @override
  String get currentlyUnderReviewNotice => 'वर्तमान में प्रशासनिक समीक्षा के अधीन';
  @override
  String get reviewedByLabel => 'समीक्षा प्रारंभकर्ता';
  @override
  String get reviewTimeLabel => 'समीक्षा प्रारंभ समय';
  @override
  String get futureWorkspaceNotice => 'पूर्ण क्लिनिकल समीक्षा वर्कस्पेस अगले चरण (A9) में उपलब्ध होगा।';
  @override
  String get emptyCaseEscalationsTitle => 'कोई क्लिनिकल केस एस्केलेशन नहीं';
  @override
  String get emptyCaseEscalationsSubtitle => 'कोई भी चिकित्सक-एस्केलेटेड केस वर्तमान फ़िल्टर मानदंडों से मेल नहीं खाता है।';
  @override
  String get errorLoadingCaseEscalations => 'क्लिनिकल केस एस्केलेशन लोड करने में असमर्थ।';

  // Phase A9: Escalated Patient Clinical Workspace (Hindi)
  @override
  String get escalatedWorkspaceTitle => 'मरीज़ क्लिनिकल समीक्षा';
  @override
  String get escalatedWorkspaceSubtitle => 'एस्केलेटेड केस शासन के लिए विस्तृत क्लिनिकल रिकॉर्ड निरीक्षण।';
  @override
  String get readOnlyBadge => 'केवल पढ़ने के लिए';
  @override
  String get backToCaseEscalations => 'केस एस्केलेशन पर वापस जाएँ';
  @override
  String get openClinicalWorkspace => 'क्लिनिकल वर्कस्पेस खोलें';
  @override
  String get clinicalCaseEscalationBannerTitle => 'क्लिनिकल केस एस्केलेशन';
  @override
  String get escalationBannerSubtitle => 'यह केस उच्च प्राधिकारी समीक्षा के लिए उपस्थित चिकित्सक द्वारा एस्केलेट किया गया है।';
  @override
  String get reasonLabel => 'कारण';
  @override
  String get escalatedAtLabel => 'एस्केलेट समय';
  @override
  String get escalatedByLabel => 'द्वारा एस्केलेट';
  @override
  String get sourceVisitLabel => 'स्रोत विज़िट';
  @override
  String get doctorExplanationLabel => 'चिकित्सक स्पष्टीकरण / क्लिनिकल नोट';
  @override
  String get activeConsultationTitle => 'परामर्श सक्रिय है';
  @override
  String get activeConsultationSubtitle => 'इस मरीज़ के लिए वर्तमान में एक क्लिनिकल परामर्श प्रगति पर है।';
  @override
  String get patientClinicalReview => 'मरीज़ क्लिनिकल समीक्षा';
  @override
  String get patientDetailsSection => 'मरीज़ पहचान';
  @override
  String get patientIdLabel => 'मरीज़ आईडी';
  @override
  String get patientNameLabel => 'मरीज़ का नाम';
  @override
  String get ageGenderLabel => 'आयु / लिंग';
  @override
  String get bloodGroupLabel => 'रक्त समूह';
  @override
  String get departmentDomainLabel => 'विभाग';
  @override
  String get caseSummarySection => 'केस सारांश';
  @override
  String get caseIdLabel => 'केस आईडी';
  @override
  String get caseTitleLabel => 'केस शीर्षक';
  @override
  String get caseStatusLabel => 'केस स्थिति';
  @override
  String get totalVisitsLabel => 'कुल विज़िट';
  @override
  String get openedDateLabel => 'प्रारंभ तिथि';
  @override
  String get lastVisitLabel => 'अंतिम विज़िट';
  @override
  String get relevantHistoryLabel => 'पिछला प्रासंगिक इतिहास';
  @override
  String get currentVitalsSection => 'वर्तमान वाइटल्स';
  @override
  String get heartRateLabel => 'हृदय गति';
  @override
  String get spo2Label => 'SpO2';
  @override
  String get temperatureLabel => 'तापमान';
  @override
  String get lastRecordedLabel => 'दर्ज समय';
  @override
  String get caseTimelineSection => 'केस टाइमलाइन';
  @override
  String get timelineFilterAll => 'सभी घटनाएँ';
  @override
  String get timelineFilterVisits => 'विज़िट';
  @override
  String get timelineFilterTransfers => 'स्थानांतरण';
  @override
  String get timelineFilterEscalations => 'एस्केलेशन';
  @override
  String get visitHistorySection => 'विज़िट इतिहास';
  @override
  String get visitLabel => 'विज़िट';
  @override
  String get attendingPhysicianSection => 'उपस्थित चिकित्सक';
  @override
  String get doctorQualificationLabel => 'योग्यता';
  @override
  String get structuredConsultationSection => 'संरचित परामर्श (8 क्लिनिकल क्षेत्र)';
  @override
  String get chiefComplaintLabel => 'मुख्य शिकायत';
  @override
  String get onsetDurationLabel => 'शुरुआत / अवधि';
  @override
  String get associatedSymptomsLabel => 'संबंधित लक्षण';
  @override
  String get medicalHistoryLabel => 'चिकित्सा इतिहास';
  @override
  String get currentMedicationLabel => 'वर्तमान दवाइयाँ';
  @override
  String get clinicalObservationsLabel => 'क्लिनिकल अवलोकन';
  @override
  String get assessmentLabel => 'आकलन';
  @override
  String get planLabel => 'योजना';
  @override
  String get prescriptionsSection => 'पर्चे (दवाइयाँ)';
  @override
  String get medicineLabel => 'दवा';
  @override
  String get dosageLabel => 'खुराक / समय';
  @override
  String get durationLabel => 'अवधि';
  @override
  String get instructionsLabel => 'निर्देश';
  @override
  String get noPrescriptionsRecorded => 'इस विज़िट के लिए कोई दवा निर्धारित नहीं की गई।';
  @override
  String get doctorApprovedSummarySection => 'डॉक्टर-स्वीकृत विज़िट सारांश';
  @override
  String get statusApprovedByDoctor => 'डॉक्टर द्वारा स्वीकृत';
  @override
  String get statusReviewRequired => 'समीक्षा आवश्यक';
  @override
  String get statusDraft => 'ड्राफ्ट';
  @override
  String get investigationsReportsSection => 'जाँच एवं रिपोर्ट';
  @override
  String get tabRequestedInvestigations => 'अनुरोधित';
  @override
  String get tabUploadedReports => 'अपलोड की गई रिपोर्ट';
  @override
  String get tabReviewedReports => 'समीक्षित';
  @override
  String get noInvestigationsOrReports => 'इस विज़िट के लिए कोई जाँच या रिपोर्ट उपलब्ध नहीं है।';
  @override
  String get actionViewReport => 'रिपोर्ट देखें';
  @override
  String get actionOpenReport => 'फ़ाइल खोलें';
  @override
  String get reportFileNameLabel => 'फ़ाइल नाम';
  @override
  String get reportFileTypeLabel => 'फ़ाइल प्रकार';
  @override
  String get reportFileSizeLabel => 'फ़ाइल आकार';
  @override
  String get reportUploadDateLabel => 'अपलोड तिथि';
  @override
  String get planFollowUpSection => 'योजना एवं फॉलो-अप';
  @override
  String get followUpLabel => 'फॉलो-अप सलाह';
  @override
  String get patientInstructionsLabel => 'मरीज़ निर्देश';
  @override
  String get visitCompletionSection => 'विज़िट पूर्णता एवं दस्तावेज़ीकरण';
  @override
  String get officialVisitPdfLabel => 'आधिकारिक AAYUSATHI विज़िट दस्तावेज़ PDF';
  @override
  String get actionViewVisitPdf => 'विज़िट PDF देखें';
  @override
  String get actionOpenPdf => 'PDF खोलें';
  @override
  String get noVisitPdfAvailable => 'इस सक्रिय परामर्श के लिए अभी विज़िट PDF तैयार नहीं किया गया है।';
  @override
  String get transferHistorySection => 'अंतर-विभागीय स्थानांतरण इतिहास';
  @override
  String get fromDepartmentLabel => 'स्रोत विभाग';
  @override
  String get toDepartmentLabel => 'गंतव्य विभाग';
  @override
  String get sourceDoctorLabel => 'स्रोत डॉक्टर';
  @override
  String get destinationDoctorLabel => 'गंतव्य डॉक्टर';
  @override
  String get transferReasonLabel => 'स्थानांतरण कारण';
  @override
  String get noTransfersRecorded => 'इस केस के लिए कोई अंतर-विभागीय स्थानांतरण दर्ज नहीं है।';
  @override
  String get escalationGovernanceHistorySection => 'एस्केलेशन एवं शासन इतिहास';
  @override
  String get reviewStartedByLabel => 'समीक्षा प्रारंभकर्ता';
  @override
  String get reviewStartedAtLabel => 'समीक्षा प्रारंभ समय';
  @override
  String get errorLoadingClinicalRecord => 'क्लिनिकल रिकॉर्ड लोड करने में असमर्थ।';
  @override
  String get caseNotFoundTitle => 'केस नहीं मिला';
  @override
  String get caseNotFoundSubtitle => 'अनुरोधित क्लिनिकल केस रिपॉजिटरी में नहीं मिला।';

  // Phase A10: Higher-Authority Doctor Assignment (Hindi)
  @override
  String get higherAuthorityReviewSection => 'उच्च-प्राधिकरण क्लिनिकल आवंटन';
  @override
  String get assignHigherAuthorityButton => 'उच्च प्राधिकरण को सौंपें';
  @override
  String get assigningHigherAuthorityButton => 'आवंटित किया जा रहा है...';
  @override
  String get assignHigherAuthorityDialogTitle => 'उच्च-प्राधिकरण डॉक्टर आवंटित करें';
  @override
  String get assignHigherAuthorityDialogSubtitle => 'इस एस्केलेटेड केस की समीक्षा के लिए अधिकृत वरिष्ठ डॉक्टर या विशेषज्ञ का चयन करें।';
  @override
  String get eligibleDoctorsSectionTitle => 'योग्य उच्च-प्राधिकरण डॉक्टर';
  @override
  String get sourceDoctorAuthorityLabel => 'स्रोत प्राधिकरण स्तर';
  @override
  String get targetAuthorityLevelLabel => 'प्राधिकरण स्तर';
  @override
  String get crossDepartmentTransferOption => 'अन्य क्लिनिकल विभाग में स्थानांतरित करें';
  @override
  String get crossDepartmentTransferHelp => 'यदि विशेषज्ञ समीक्षा के लिए अंतर-विभागीय स्थानांतरण की आवश्यकता हो तो चालू करें।';
  @override
  String get crossDepartmentReasonLabel => 'स्थानांतरण कारण एवं प्रशासनिक औचित्य';
  @override
  String get crossDepartmentReasonHint => 'अन्य विभाग में आवंटन के लिए क्लिनिकल कारण दर्ज करें...';
  @override
  String get confirmAssignmentDialogTitle => 'उच्च-प्राधिकरण आवंटन की पुष्टि करें';
  @override
  String get confirmAssignmentDialogMessage => 'क्या आप इस केस को चयनित उच्च-प्राधिकरण डॉक्टर को सौंपना चाहते हैं? केस और विज़िट रिकॉर्ड सुरक्षित रहेंगे।';
  @override
  String get assignmentSuccessNotification => 'केस सफलतापूर्वक उच्च-प्राधिकरण डॉक्टर को आवंटित किया गया।';
  @override
  String get noEligibleDoctorsExplanation => 'स्रोत डॉक्टर से उच्च प्राधिकरण और उपलब्ध (AVAILABLE) स्थिति वाला डॉक्टर आवश्यक है।';
  @override
  String get statusBadgeAssigned => 'उच्च प्राधिकरण को आवंटित';
  @override
  String get statusBadgeAccepted => 'आवंटन स्वीकृत';
  @override
  String get assignedToDoctorLabel => 'आवंटित डॉक्टर';
  @override
  String get assignedAtLabel => 'आवंटन समय';
  @override
  String get assignedByAdminLabel => 'आवंटनकर्ता';
  @override
  String get higherAuthorityCaseBannerTitle => 'उच्च-प्राधिकरण समीक्षा के लिए आवंटित केस';
  @override
  String get acceptAssignmentButton => 'केस स्वीकार करें';
  @override
  String get acceptingAssignmentButton => 'स्वीकार किया जा रहा है...';
  @override
  String get assignmentAcceptedSuccess => 'उच्च-प्राधिकरण आवंटन सफलतापूर्वक स्वीकार किया गया।';
}

/// Marathi localization for Admin Portal
class _AdminStringsMr extends _AdminStringsEn {
  const _AdminStringsMr();

  @override
  String get adminPortalTitle => 'प्रशासन पोर्टल';
  @override
  String get administrationPortal => 'प्रशासन पोर्टल';
  @override
  String get healthcareManagementSystem => 'आरोग्य सेवा व्यवस्थापन प्रणाली';
  @override
  String get centralAdminConsole => 'केंद्रीय प्रशासकीय कन्सोल';
  @override
  String get touchToBegin => 'सुरू करण्यासाठी स्पर्श करा';
  @override
  String get adminLoginTitle => 'प्रशासक लॉगिन';
  @override
  String get username => 'वापरकर्ता नाव';
  @override
  String get password => 'पासवर्ड';
  @override
  String get loginButton => 'लॉगिन';
  @override
  String get back => 'मागे';
  @override
  String get navDashboard => 'डॅशबोर्ड';
  @override
  String get navDoctors => 'डॉक्टर';
  @override
  String get navAvailability => 'उपलब्धता';
  @override
  String get navAppointmentEscalations => 'अपॉइंटमेंट एस्केलेशन';
  @override
  String get navCaseEscalations => 'केस एस्केलेशन';
  @override
  String get systemOverview => 'प्रणाली विहंगावलोकन';
  @override
  String get totalDoctors => 'एकूण डॉक्टर';
  @override
  String get availableDoctors => 'उपलब्ध डॉक्टर';
  @override
  String get pendingAppointments => 'प्रलंबित अपॉइंटमेंट्स';
  @override
  String get activeEscalations => 'सक्रिय एस्केलेशन';
  @override
  String get activeCases => 'सक्रिय प्रकरणे';
  @override
  String get activeCasesDesc => 'प्रणालीतील खुली वैद्यकीय प्रकरणे';
  @override
  String get noAppointmentEscalations => 'कोणतेही अपॉइंटमेंट एस्केलेशन नाही';
  @override
  String get noCaseEscalations => 'कोणतेही सक्रिय केस एस्केलेशन नाही';
  @override
  String get manageDoctorsHeaderTitle => 'डॉक्टर व्यवस्थापन';
  @override
  String get searchDoctorPlaceholder => 'डॉक्टर आयडी, नाव किंवा फोनने शोधा...';
  @override
  String get statusActive => 'सक्रिय';
  @override
  String get statusInactive => 'निष्क्रिय';
  @override
  String get noDoctorsFound => 'कोणतेही डॉक्टर आढळले नाहीत';
  @override
  String get actionViewDetails => 'तपशील पहा';
  @override
  String get actionEditDoctor => 'प्रोफाइल संपादित करा';
  @override
  String get actionDeactivate => 'निष्क्रिय करा';
  @override
  String get actionActivate => 'सक्रिय करा';
  @override
  String get saveChangesButton => 'बदल जतन करा';
  @override
  String get confirmButton => 'पुष्टी करा';
  @override
  String get cancelButton => 'रद्द करा';
  @override
  String get availabilityHeaderTitle => 'डॉक्टर उपलब्धता';
  @override
  String get availabilityHeaderSubtitle => 'रिअल-टाइम डॉक्टर वर्कस्टेशन उपलब्धतेचे निरीक्षण आणि व्यवस्थापन करा.';
  @override
  String get viewAllDoctors => 'सर्व डॉक्टर पहा';
  @override
  String get totalActiveDoctors => 'एकूण सक्रिय डॉक्टर';
  @override
  String get onlineAvailable => 'ऑनलाइन / उपलब्ध';
  @override
  String get inConsultation => 'सल्लामसलतीत';
  @override
  String get offline => 'ऑफलाइन';
  @override
  String get actionSetAvailable => 'उपलब्ध सेट करा';
  @override
  String get actionSetOffline => 'ऑफलाइन सेट करा';
  @override
  String get actionDoctorInConsultation => 'डॉक्टर सल्लामसलतीत आहेत';
  @override
  String get errorLoadingAvailability => 'डॉक्टर उपलब्धता लोड करण्यात अक्षम.';

  // Phase A7: Marathi
  @override
  String get appointmentEscalationsHeaderTitle => 'अपॉइंटमेंट एस्केलेशन';
  @override
  String get appointmentEscalationsHeaderSubtitle => '20 मिनिटांपेक्षा जास्त काळ प्रतीक्षेत असलेल्या अपॉइंटमेंट्सवर प्रशासकीय लक्ष आवश्यक आहे.';
  @override
  String get summaryEscalatedAppointments => 'एस्केलेटेड अपॉइंटमेंट्स';
  @override
  String get summaryWaitingAppointments => 'प्रतीक्षेत असलेल्या अपॉइंटमेंट्स';
  @override
  String get summaryResolvedToday => 'आज सोडवलेले';
  @override
  String get searchEscalationPlaceholder => 'रांग क्रमांक किंवा अपॉइंटमेंट आयडीने शोधा...';
  @override
  String get filterStatusAll => 'सर्व स्थिती';
  @override
  String get filterStatusEscalated => 'एस्केलेटेड';
  @override
  String get filterStatusWaiting => 'प्रतीक्षेत';
  @override
  String get filterStatusResolved => 'असाइन केलेले / सोडवलेले';
  @override
  String get sortOldestWaiting => 'सर्वात जुने प्रतीक्षेत';
  @override
  String get sortEscalationTime => 'एस्केलेशन वेळ';
  @override
  String get tableColQueue => 'रांग';
  @override
  String get tableColAppointmentId => 'अपॉइंटमेंट आयडी';
  @override
  String get tableColDepartmentA7 => 'विभाग';
  @override
  String get tableColWaitingSince => 'प्रतीक्षा सुरू वेळ';
  @override
  String get tableColWaitingDuration => 'प्रतीक्षा कालावधी';
  @override
  String get tableColEscalatedAt => 'एस्केलेट झाले';
  @override
  String get tableColCurrentStatus => 'सद्यस्थिती';
  @override
  String get tableColAction => 'कृती';
  @override
  String get actionAssignDoctor => 'डॉक्टर नियुक्त करा';
  @override
  String get actionInspectDetails => 'तपशील पहा';
  @override
  String get statusBadgeEscalated => 'एस्केलेटेड';
  @override
  String get statusBadgeWaiting => 'प्रतीक्षेत';
  @override
  String get statusBadgeResolved => 'सोडवले';
  @override
  String get detailsModalTitle => 'अपॉइंटमेंट एस्केलेशन तपशील';
  @override
  String get detailsModalSubtitle => 'क्लिनिकल रांग एसएलए आणि रुग्ण ट्राइएज घटकांचे पुनरावलोकन करा.';
  @override
  String get assignDoctorModalTitle => 'मॅन्युअल डॉक्टर नियुक्ती';
  @override
  String get assignDoctorModalSubtitle => 'या एस्केलेटेड अपॉइंटमेंटसाठी पात्र उपलब्ध डॉक्टर निवडा.';
  @override
  String get eligibleDoctorsFound => 'पात्र डॉक्टर';
  @override
  String get noEligibleDoctorsTitle => 'कोणतेही डॉक्टर उपलब्ध नाहीत';
  @override
  String get noEligibleDoctorsMessage => 'या विशेष विभागात सध्या कोणतेही सक्रिय, उपलब्ध डॉक्टर नाहीत.';
  @override
  String get confirmAssignmentButton => 'नियुक्तीची पुष्टी करा';
  @override
  String get assigningButton => 'डॉक्टर नियुक्त करत आहे...';
  @override
  String get assignmentSuccessMessage => 'डॉक्टर यशस्वीरित्या नियुक्त केले.';
  @override
  String get assignmentFailedMessage => 'अपॉइंटमेंटची स्थिती बदलल्यामुळे नियुक्ती पूर्ण होऊ शकली नाही.';
  @override
  String get doctorUnavailableError => 'डॉक्टर आता उपलब्ध नाहीत. कृपया इतर डॉक्टर निवडा.';
  @override
  String get previousDoctorRestrictionWarning => 'ही अपॉइंटमेंट विशेषतः मागील डॉक्टरसाठी विनंती केली आहे आणि इतर कोणालाही पुन्हा नियुक्त करता येत नाही.';
  @override
  String get emptyEscalationsTitle => 'कोणतेही अपॉइंटमेंट एस्केलेशन नाही';
  @override
  String get emptyEscalationsSubtitle => 'सर्व प्रतीक्षेत असलेल्या अपॉइंटमेंट्स मानक 20 मिनिटांच्या प्रतिसाद मर्यादेत आहेत.';
  @override
  String get errorLoadingEscalations => 'अपॉइंटमेंट एस्केलेशन लोड करण्यात अक्षम.';

  // Phase A8: Case Escalations (Marathi)
  @override
  String get caseEscalationsHeaderTitle => 'क्लिनिकल केस एस्केलेशन्स';
  @override
  String get caseEscalationsHeaderSubtitle => 'डॉक्टरांनी एस्केलेट केलेल्या केसेस आणि प्रशासकीय पुनरावलोकन रांग.';
  @override
  String get summaryTotalCaseEscalations => 'एकूण एस्केलेशन्स';
  @override
  String get summaryPendingReview => 'प्रलंबित पुनरावलोकन';
  @override
  String get summaryUnderReview => 'पुनरावलोकनाधीन';
  @override
  String get summaryRepeatedVisits => 'वारंवार भेटी';
  @override
  String get searchCaseEscalationPlaceholder => 'केस आयडी, रुग्ण आयडी किंवा डॉक्टर आयडीनुसार शोधा...';
  @override
  String get filterReasonAll => 'सर्व कारणे';
  @override
  String get filterReasonDeterioration => 'क्लिनिकल स्थिती खालावणे';
  @override
  String get filterReasonRepeatedVisits => 'वारंवार भेटी';
  @override
  String get filterReasonHigherAuthority => 'उच्च प्राधिकारी पुनरावलोकन';
  @override
  String get filterReasonDoctorConcern => 'डॉक्टर चिंता';
  @override
  String get filterReasonOther => 'इतर';
  @override
  String get filterReviewStatusAll => 'सर्व स्थिती';
  @override
  String get filterReviewStatusEscalated => 'एस्केलेटेड (प्रलंबित)';
  @override
  String get filterReviewStatusUnderReview => 'पुनरावलोकनाधीन';
  @override
  String get sortCaseOldest => 'सर्वात जुने एस्केलेशन';
  @override
  String get sortCaseNewest => 'नवीनतम एस्केलेशन';
  @override
  String get sortCaseDepartment => 'विभाग';
  @override
  String get sortCaseVisitCount => 'भेट संख्या';
  @override
  String get sortCaseReason => 'एस्केलेशन कारण';
  @override
  String get tableColCaseId => 'केस आयडी';
  @override
  String get tableColPatientId => 'रुग्ण आयडी';
  @override
  String get tableColDepartmentA8 => 'विभाग';
  @override
  String get tableColReason => 'कारण';
  @override
  String get tableColSourceVisit => 'स्रोत भेट';
  @override
  String get tableColEscalatedAtA8 => 'एस्केलेट वेळ';
  @override
  String get tableColEscalatedBy => 'द्वारे एस्केलेट';
  @override
  String get tableColCaseStatus => 'केस स्थिती';
  @override
  String get tableColReviewStatus => 'पुनरावलोकन स्थिती';
  @override
  String get tableColActionA8 => 'कृती';
  @override
  String get actionReviewCase => 'पुनरावलोकन करा';
  @override
  String get statusBadgePendingReview => 'प्रलंबित पुनरावलोकन';
  @override
  String get statusBadgeUnderReview => 'पुनरावलोकनाधीन';
  @override
  String get caseReviewModalTitle => 'केस एस्केलेशन पुनरावलोकन';
  @override
  String get caseReviewModalSubtitle => 'क्लिनिकल एस्केलेशन मेटाडेटा आणि प्रशासकीय पुनरावलोकन मूल्यांकन.';
  @override
  String get startReviewButton => 'पुनरावलोकन सुरू करा';
  @override
  String get startingReviewButton => 'पुनरावलोकन सुरू होत आहे...';
  @override
  String get reviewStartedSuccess => 'केस प्रशासकीय पुनरावलोकनाधीन चिन्हांकित केली.';
  @override
  String get currentlyUnderReviewNotice => 'सध्या प्रशासकीय पुनरावलोकनाधीन';
  @override
  String get reviewedByLabel => 'पुनरावलोकन सुरू करणारे';
  @override
  String get reviewTimeLabel => 'पुनरावलोकन सुरू वेळ';
  @override
  String get futureWorkspaceNotice => 'संपूर्ण क्लिनिकल पुनरावलोकन वर्कस्पेस पुढील टप्प्यात (A9) उपलब्ध होईल.';
  @override
  String get emptyCaseEscalationsTitle => 'कोणतेही क्लिनिकल केस एस्केलेशन नाही';
  @override
  String get emptyCaseEscalationsSubtitle => 'सध्याच्या फिल्टर निकषांशी जुळणारी कोणतीही डॉक्टर-एस्केलेटेड केस आढळली नाही.';
  @override
  String get errorLoadingCaseEscalations => 'क्लिनिकल केस एस्केलेशन्स लोड करण्यात अक्षम.';

  // Phase A9: Escalated Patient Clinical Workspace (Marathi)
  @override
  String get escalatedWorkspaceTitle => 'रुग्ण क्लिनिकल पुनरावलोकन';
  @override
  String get escalatedWorkspaceSubtitle => 'एस्केलेटेड केस प्रशासनासाठी सखोल क्लिनिकल रेकॉर्ड तपासणी.';
  @override
  String get readOnlyBadge => 'केवळ वाचण्यासाठी';
  @override
  String get backToCaseEscalations => 'केस एस्केलेशन्सवर परत जा';
  @override
  String get openClinicalWorkspace => 'क्लिनिकल वर्कस्पेस उघडा';
  @override
  String get clinicalCaseEscalationBannerTitle => 'क्लिनिकल केस एस्केलेशन';
  @override
  String get escalationBannerSubtitle => 'हे प्रकरण उच्च प्राधिकरणाच्या पुनरावलोकनासाठी उपस्थित डॉक्टरांनी एस्केलेट केले आहे.';
  @override
  String get reasonLabel => 'कारण';
  @override
  String get escalatedAtLabel => 'एस्केलेट वेळ';
  @override
  String get escalatedByLabel => 'द्वारे एस्केलेट';
  @override
  String get sourceVisitLabel => 'स्रोत भेट';
  @override
  String get doctorExplanationLabel => 'डॉक्टरांचे स्पष्टीकरण / क्लिनिकल टीप';
  @override
  String get activeConsultationTitle => 'सल्लामसलत सुरू आहे';
  @override
  String get activeConsultationSubtitle => 'या रुग्णासाठी सध्या क्लिनिकल सल्लामसलत सुरू आहे.';
  @override
  String get patientClinicalReview => 'रुग्ण क्लिनिकल पुनरावलोकन';
  @override
  String get patientDetailsSection => 'रुग्ण ओळख';
  @override
  String get patientIdLabel => 'रुग्ण आयडी';
  @override
  String get patientNameLabel => 'रुग्णाचे नाव';
  @override
  String get ageGenderLabel => 'वय / लिंग';
  @override
  String get bloodGroupLabel => 'रक्तगट';
  @override
  String get departmentDomainLabel => 'विभाग';
  @override
  String get caseSummarySection => 'केस सारांश';
  @override
  String get caseIdLabel => 'केस आयडी';
  @override
  String get caseTitleLabel => 'केस शीर्षक';
  @override
  String get caseStatusLabel => 'केस स्थिती';
  @override
  String get totalVisitsLabel => 'एकूण भेटी';
  @override
  String get openedDateLabel => 'सुरू झालेली तारीख';
  @override
  String get lastVisitLabel => 'शेवटची भेट';
  @override
  String get relevantHistoryLabel => 'मागील संबंधित इतिहास';
  @override
  String get currentVitalsSection => 'सध्याचे व्हायटल्स';
  @override
  String get heartRateLabel => 'हृदय गती';
  @override
  String get spo2Label => 'SpO2';
  @override
  String get temperatureLabel => 'तापमान';
  @override
  String get lastRecordedLabel => 'नोंद वेळ';
  @override
  String get caseTimelineSection => 'केस टाइमलाइन';
  @override
  String get timelineFilterAll => 'सर्व घटना';
  @override
  String get timelineFilterVisits => 'भेटी';
  @override
  String get timelineFilterTransfers => 'हस्तांतरण';
  @override
  String get timelineFilterEscalations => 'एस्केलेशन्स';
  @override
  String get visitHistorySection => 'भेट इतिहास';
  @override
  String get visitLabel => 'भेट';
  @override
  String get attendingPhysicianSection => 'उपस्थित डॉक्टर';
  @override
  String get doctorQualificationLabel => 'पात्रता';
  @override
  String get structuredConsultationSection => 'संरचित सल्लामसलत (8 क्लिनिकल घटक)';
  @override
  String get chiefComplaintLabel => 'मुख्य तक्रार';
  @override
  String get onsetDurationLabel => 'सुरुवात / कालावधी';
  @override
  String get associatedSymptomsLabel => 'संबंधित लक्षणे';
  @override
  String get medicalHistoryLabel => 'वैद्यकीय इतिहास';
  @override
  String get currentMedicationLabel => 'सध्याची औषधे';
  @override
  String get clinicalObservationsLabel => 'क्लिनिकल निरीक्षणे';
  @override
  String get assessmentLabel => 'मूल्यांकन';
  @override
  String get planLabel => 'योजना';
  @override
  String get prescriptionsSection => 'औषधोपचार (प्रिस्क्रिप्शन)';
  @override
  String get medicineLabel => 'औषध';
  @override
  String get dosageLabel => 'डोस / वेळ';
  @override
  String get durationLabel => 'कालावधी';
  @override
  String get instructionsLabel => 'सूचना';
  @override
  String get noPrescriptionsRecorded => 'या भेटीसाठी कोणतीही औषधे लिहून दिलेली नाहीत.';
  @override
  String get doctorApprovedSummarySection => 'डॉक्टर-मंजूर भेट सारांश';
  @override
  String get statusApprovedByDoctor => 'डॉक्टरांद्वारे मंजूर';
  @override
  String get statusReviewRequired => 'पुनरावलोकन आवश्यक';
  @override
  String get statusDraft => 'मसुदा';
  @override
  String get investigationsReportsSection => 'तपासणी व अहवाल';
  @override
  String get tabRequestedInvestigations => 'मागणी केलेले';
  @override
  String get tabUploadedReports => 'अपलोड केलेले अहवाल';
  @override
  String get tabReviewedReports => 'तपासलेले';
  @override
  String get noInvestigationsOrReports => 'या भेटीसाठी कोणतीही तपासणी किंवा अहवाल उपलब्ध नाही.';
  @override
  String get actionViewReport => 'अहवाल पहा';
  @override
  String get actionOpenReport => 'फाइल उघडा';
  @override
  String get reportFileNameLabel => 'फाइल नाव';
  @override
  String get reportFileTypeLabel => 'फाइल प्रकार';
  @override
  String get reportFileSizeLabel => 'फाइल आकार';
  @override
  String get reportUploadDateLabel => 'अपलोड तारीख';
  @override
  String get planFollowUpSection => 'योजना व पुढील सल्ला';
  @override
  String get followUpLabel => 'पुढील भेटीचा सल्ला';
  @override
  String get patientInstructionsLabel => 'रुग्णासाठी सूचना';
  @override
  String get visitCompletionSection => 'भेट पूर्णता व दस्तऐवजीकरण';
  @override
  String get officialVisitPdfLabel => 'अधिकृत AAYUSATHI भेट दस्तऐवज PDF';
  @override
  String get actionViewVisitPdf => 'भेट PDF पहा';
  @override
  String get actionOpenPdf => 'PDF उघडा';
  @override
  String get noVisitPdfAvailable => 'या सक्रिय भेटीसाठी अद्याप PDF तयार केलेले नाही.';
  @override
  String get transferHistorySection => 'आंतर-विभागीय हस्तांतरण इतिहास';
  @override
  String get fromDepartmentLabel => 'मूळ विभाग';
  @override
  String get toDepartmentLabel => 'गंतव्य विभाग';
  @override
  String get sourceDoctorLabel => 'मूळ डॉक्टर';
  @override
  String get destinationDoctorLabel => 'गंतव्य डॉक्टर';
  @override
  String get transferReasonLabel => 'हस्तांतरण कारण';
  @override
  String get noTransfersRecorded => 'या केससाठी कोणतेही आंतर-विभागीय हस्तांतरण नोंदवलेले नाही.';
  @override
  String get escalationGovernanceHistorySection => 'एस्केलेशन व प्रशासन इतिहास';
  @override
  String get reviewStartedByLabel => 'पुनरावलोकन सुरू करणारे';
  @override
  String get reviewStartedAtLabel => 'पुनरावलोकन सुरू वेळ';
  @override
  String get errorLoadingClinicalRecord => 'क्लिनिकल रेकॉर्ड लोड करण्यात अक्षम.';
  @override
  String get caseNotFoundTitle => 'केस आढळली नाही';
  @override
  String get caseNotFoundSubtitle => 'मागणी केलेली क्लिनिकल केस रिपॉझिटरीमध्ये आढळली नाही.';

  // Phase A10: Higher-Authority Doctor Assignment (Marathi)
  @override
  String get higherAuthorityReviewSection => 'उच्च-प्राधिकरण क्लिनिकल वाटप';
  @override
  String get assignHigherAuthorityButton => 'उच्च प्राधिकरणाकडे सोपवा';
  @override
  String get assigningHigherAuthorityButton => 'वाटप करत आहे...';
  @override
  String get assignHigherAuthorityDialogTitle => 'उच्च-प्राधिकरण डॉक्टर नियुक्त करा';
  @override
  String get assignHigherAuthorityDialogSubtitle => 'या एस्केलेटेड केसच्या पुनरावलोकनासाठी अधिकृत वरिष्ठ डॉक्टर किंवा तज्ज्ञ निवडा.';
  @override
  String get eligibleDoctorsSectionTitle => 'पात्र उच्च-प्राधिकरण डॉक्टर';
  @override
  String get sourceDoctorAuthorityLabel => 'मूळ प्राधिकरण पातळी';
  @override
  String get targetAuthorityLevelLabel => 'प्राधिकरण पातळी';
  @override
  String get crossDepartmentTransferOption => 'दुसऱ्या विभागात हस्तांतरित करा';
  @override
  String get crossDepartmentTransferHelp => 'तज्ज्ञ पुनरावलोकनासाठी आंतर-विभागीय हस्तांतरण आवश्यक असल्यास निवडा.';
  @override
  String get crossDepartmentReasonLabel => 'हस्तांतरणाचे कारण व प्रशासकीय औचित्य';
  @override
  String get crossDepartmentReasonHint => 'आंतर-विभागीय वाटपाचे क्लिनिकल कारण नोंदवा...';
  @override
  String get confirmAssignmentDialogTitle => 'उच्च-प्राधिकरण वाटपाची पुष्टी करा';
  @override
  String get confirmAssignmentDialogMessage => 'तुम्हाला ही केस निवडलेल्या उच्च-प्राधिकरण डॉक्टरांकडे सोपवायची आहे का? केस आणि मागील नोंदी अबाधित राहतील.';
  @override
  String get assignmentSuccessNotification => 'केस यशस्वीरीत्या उच्च-प्राधिकरण डॉक्टरांकडे सोपवण्यात आली.';
  @override
  String get noEligibleDoctorsExplanation => 'मूळ डॉक्टरांपेक्षा उच्च प्राधिकरण पातळी असलेले व उपलब्ध (AVAILABLE) असलेले डॉक्टर आवश्यक आहेत.';
  @override
  String get statusBadgeAssigned => 'उच्च प्राधिकरणाकडे सोपवले';
  @override
  String get statusBadgeAccepted => 'वाटप स्वीकारले';
  @override
  String get assignedToDoctorLabel => 'नियुक्त डॉक्टर';
  @override
  String get assignedAtLabel => 'वाटप वेळ';
  @override
  String get assignedByAdminLabel => 'वाटपकर्ता';
  @override
  String get higherAuthorityCaseBannerTitle => 'उच्च-प्राधिकरण पुनरावलोकनासाठी नियुक्त केस';
  @override
  String get acceptAssignmentButton => 'केस स्वीकारा';
  @override
  String get acceptingAssignmentButton => 'स्वीकारत आहे...';
  @override
  String get assignmentAcceptedSuccess => 'उच्च-प्राधिकरण वाटप यशस्वीरीत्या स्वीकारले.';
}
