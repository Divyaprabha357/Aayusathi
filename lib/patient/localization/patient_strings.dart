/// Trilingual localization strings for the AAYUSATHI Patient App.
/// Supports English, Hindi (हिंदी), and Marathi (मराठी).
class PatientStrings {
  const PatientStrings();

  // Branding & General
  String get appName => 'AAYUSATHI';
  String get appTagline => 'LIVE BETTER, TOGETHER';
  String get loading => 'Loading...';
  String get retry => 'Try Again';
  String get back => 'Back';
  String get close => 'Close';
  String get errorTitle => 'Something went wrong';
  String get errorMessage => 'Unable to complete your request. Please try again.';
  String get noData => 'No information available';

  // Navigation Tabs (Icon + Label)
  String get tabHome => 'Dashboard';
  String get tabDashboard => 'Dashboard';
  String get tabCases => 'Cases';
  String get tabReports => 'Reports';
  String get tabCalendar => 'Calendar';
  String get tabProfile => 'Profile';

  // Patient Login Screen
  String get loginHeading => 'Patient Login';
  String get loginDescription => 'Enter your AAYUSATHI Patient ID to continue.';
  String get loginInputLabel => 'Patient ID';
  String get loginInputHint => 'e.g. AAYU-102938';
  String get loginButton => 'Continue';
  String get loginErrorEmpty => 'Please enter your Patient ID.';
  String get loginErrorInvalid => 'Please enter a valid Patient ID format.';

  // OTP Screen Shell
  String get otpHeading => 'Verify Your Mobile Number';
  String get otpDescription => 'An OTP will be sent to your registered mobile number.';
  String get otpInputLabel => 'Enter 6-Digit Code';
  String get otpVerifyButton => 'Verify OTP';
  String get otpResendButton => 'Resend OTP';
  String get otpDevNotice => 'Development Shell: Enter any 6 digits to proceed';
  String get otpErrorInvalid => 'Please enter a valid 6-digit code.';

  // Dashboard Shell
  String greeting(String name) => 'Hello, $name';
  String greetingMorning(String name) => 'Good Morning, $name';
  String greetingAfternoon(String name) => 'Good Afternoon, $name';
  String greetingEvening(String name) => 'Good Evening, $name';
  String get goodMorning => 'Good Morning';
  String get goodAfternoon => 'Good Afternoon';
  String get goodEvening => 'Good Evening';
  String get defaultPatientName => 'Patient';
  String get dashboardSubtitle => 'Welcome to your healthcare portal';
  String get nextVisitTitle => 'NEXT VISIT';
  String get nextVisitEmpty => 'No Upcoming Visits';
  String get noUpcomingVisitsTitle => nextVisitEmpty;
  String get nextVisitEmptySubtitle => "You don't have a scheduled visit yet.";
  String get noUpcomingVisitsSubtitle => nextVisitEmptySubtitle;
  String get ongoingCasesTitle => 'ONGOING CASES';
  String get ongoingCasesLabel => 'Active medical investigations';
  String get noOngoingCasesTitle => 'No Ongoing Cases';
  String get noOngoingCasesSubtitle => 'You currently have no active cases.';
  String get quickAccessTitle => 'QUICK ACCESS';
  String get quickAccessCases => 'View Cases';
  String get quickAccessCasesDesc => 'View open and past health cases';
  String get quickAccessReports => 'View Reports';
  String get quickAccessReportsDesc => 'Access lab test documents';
  String get quickAccessUpcoming => 'Upcoming Visit';
  String get quickAccessUpcomingDesc => 'Check next consultation date';
  String get quickAccessCalendar => 'Calendar';
  String get quickAccessCalendarDesc => 'View medical schedule';
  String get healthSummaryTitle => 'Health Summary';
  String get unableToLoadData => 'Unable to load your information.';

  // Cases Screen Shell
  String get casesScreenTitle => 'Cases';
  String get casesTabActive => 'Active';
  String get casesTabCompleted => 'Completed';
  String get casesEmptyActive => 'No Ongoing Cases';
  String get casesEmptyActiveDesc => 'You currently have no active cases.';
  String get casesEmptyCompleted => 'No Completed Cases';
  String get casesEmptyCompletedDesc => "You don't have any completed cases yet.";
  String get casesErrorLoading => 'Unable to load your cases.\nPlease try again.';
  String get caseDetailTitle => 'Case Details';
  String get caseHistoryTitle => 'Case History';
  String get visitHistoryTitle => 'Visit History';
  String get caseStatusOpen => 'Ongoing';
  String get caseStatusOngoing => 'Ongoing';
  String get caseStatusClosed => 'Completed';
  String get caseStatusEscalated => 'Under Specialist Review';
  String get caseVisitsCount => 'Visits';
  String formatVisits(int count) => count == 1 ? '1 Visit' : '$count Visits';
  String visitNumberLabel(int number) => 'Visit $number';
  String get caseStartedDate => 'Started on';
  String get caseCompletedDate => 'Completed on';
  String get caseLastVisit => 'Last visit';
  String get visitDetailTitle => 'Visit Details';
  String get visitDoctor => 'Attending Doctor';
  String get visitDoctorTitle => 'Doctor';
  String get visitDate => 'Consultation Date';
  String get visitDepartment => 'Department';
  String get noVisitsYet => 'No Visits Yet';
  String get noVisitsYetDesc => 'No consultation visits have been recorded for this case yet.';
  String get unableToLoadCaseDetails => 'Unable to load case details.\nPlease try again.';
  String get unableToLoadVisitHistory => 'Unable to load visit history.\nPlease try again.';
  String get notRecorded => 'Not recorded';
  String get vitalsTitle => 'Vitals';
  String get spo2Label => 'SpO₂';
  String get heartRateLabel => 'Heart Rate';
  String get temperatureLabel => 'Temperature';
  String get consultationSummaryTitle => 'Consultation Summary';
  String get consultationDetailsTitle => 'Consultation Details';
  String get chiefComplaintLabel => 'Chief Complaint';
  String get onsetDurationLabel => 'Onset / Duration';
  String get associatedSymptomsLabel => 'Associated Symptoms';
  String get medicalHistoryLabel => 'Medical History';
  String get currentMedicationLabel => 'Current Medication';
  String get clinicalObservationsLabel => 'Clinical Observations';
  String get assessmentLabel => 'Assessment';
  String get planLabel => 'Plan';
  String get prescriptionsTitle => 'Prescriptions';
  String get followUpTitle => 'Follow-up';
  String get patientInstructionsTitle => 'Instructions';
  String get requestedInvestigationsTitle => 'Requested Investigations';
  String get doctorApprovedNotice => 'APPROVED BY DOCTOR';
  String get pendingDoctorApprovalNotice => 'PENDING DOCTOR APPROVAL';
  String get visitOverviewTitle => 'Visit Overview';
  String get doctorApprovedSummaryTitle => 'Doctor-Approved Summary';
  String get consultationTitle => 'Consultation';
  String get prescriptionTitle => 'Prescription';
  String get investigationsTitle => 'Investigations';
  String get reportRequiredAction => 'Report Required';
  String get reportSubmittedStatus => 'Report Submitted';
  String get reportReviewedStatus => 'Report Reviewed';
  String get pendingUploadStatus => 'Pending Upload';
  String get uploadedStatus => 'Uploaded';
  String get reviewedStatus => 'Reviewed';
  String get noReportsRequiredTitle => 'No Reports Required';
  String get summaryNotAvailable => 'Summary not available.';
  String get viewDashboardAction => 'View Dashboard';
  String get examinationFindingsLabel => 'Examination Findings';
  String get treatmentPlanLabel => 'Treatment Plan';
  String get dietaryAdviceLabel => 'Dietary Advice';
  String get lifestyleAdviceLabel => 'Lifestyle Advice';
  String get warningSignsLabel => 'Warning Signs / Red Flags';
  String get historyOfPresentIllnessLabel => 'History of Present Illness';
  String get statusPendingUpload => 'Pending Upload';
  String get statusAvailableForDownload => 'Available for Download';

  // Reports Screen Shell
  String get reportsScreenTitle => 'Reports';
  String get reportsTabSubmitted => 'SUBMITTED';
  String get reportsTabYetToSubmit => 'YET TO SUBMIT';
  String get reportsEmptySubmitted => 'No Submitted Reports';
  String get reportsEmptySubmittedDesc => "You haven't submitted any reports yet.";
  String get reportsEmptyYetToSubmit => 'No Reports Required';
  String get reportsEmptyYetToSubmitDesc => "You currently don't have any reports waiting for submission.";
  String get reportDetailTitle => 'Report Details';
  String get reportInvestigationName => 'Investigation Name';
  String get reportRequestedDate => 'Visit Date';
  String get reportSubmissionDate => 'Submission Date';
  String get reportCaseLabel => 'Case';
  String get reportPriorityLabel => 'Priority';
  String get reportRequiredStatus => 'Report Required';
  String get submitReportAction => 'Submit Report';
  String get submitReportGuidanceTitle => 'Report Submission Guidance';
  String get submitReportGuidanceDesc => 'Please submit your physical report at the hospital collection center or during your next consultation visit. Online report upload will be enabled in the next update.';
  String get unableToLoadReports => 'Unable to load your reports.\nPlease try again.';
  String get unableToLoadAppointments => 'Unable to load upcoming visits.\nPlease try again.';
  String get reportStatusUploaded => 'Submitted';
  String get reportStatusPending => 'Report Required';
  String get viewReportButton => 'View Report';

  // Phase P8 — Report Upload Strings
  String get uploadReportTitle => 'Upload Report';
  String get takePhotoAction => 'Take Photo';
  String get chooseFromGalleryAction => 'Choose from Gallery';
  String get previewTitle => 'Preview';
  String get retakeAction => 'Retake';
  String get chooseAnotherAction => 'Choose Another';
  String get submitReportConfirmTitle => 'Submit this report?';
  String get submitReportConfirmDesc => 'Your report photo will be securely submitted to your attending doctor for clinical review.';
  String get uploadingReportProgress => 'Uploading report...';
  String get reportSubmittedSuccessTitle => 'Report Submitted Successfully';
  String get reportSubmittedSuccessDesc => 'Your report has been submitted for review.';
  String get uploadFailedTitle => 'Upload failed';
  String get uploadFailedDesc => 'Please try again.';
  String get cameraPermissionRequired => 'Camera permission is required to take a report photo.';
  String get photoAccessRequired => 'Photo access is required to choose a report.';
  String get cancelAction => 'Cancel';
  String get doneAction => 'Done';
  String get addAnotherPhotoAction => 'Add Another Photo';
  String get removePhotoAction => 'Remove';
  String pageNumberLabel(int current, int total) => 'Page $current of $total';
  String get viewVisitReportPdfButton => 'View Visit Report PDF';
  String get officialVisitReportTitle => 'Official Visit Report';
  String get visitReportPdfNotAvailable => 'Visit report PDF is not available yet.';
  String get visitReportPdfNotAvailableDesc => "Your doctor's signed consultation report will appear here once finalized.";
  String get visitReportPdfViewerTitle => 'Visit Report PDF';
  String get loadingVisitReportPdf => 'Loading visit report PDF...';
  String get unableToLoadVisitPdf => 'Unable to load visit report PDF. Please try again.';
  String get retryButton => 'Retry';

  // Calendar Screen Shell
  String get calendarScreenTitle => 'My Health Calendar';
  String get calendar => 'Calendar';
  String get calendarToday => 'Today';
  String get previousMonth => 'Previous Month';
  String get nextMonth => 'Next Month';
  String get calendarUpcomingAppointments => 'Upcoming Appointments';
  String get calendarNoEvents => 'No appointments or follow-ups scheduled for this day.';
  String get calendarEventVisit => 'OPD Consultation';
  String get calendarEventFollowUp => 'Follow-up Review';
  String get followUpVisit => 'Follow-up Visit';
  String get upcomingFollowUp => 'Upcoming Follow-up';
  String get pastFollowUp => 'Past Follow-up';
  String get noFollowUpScheduled => 'No Follow-up Scheduled';
  String get noFollowUpScheduledDesc => 'There are no scheduled follow-ups for this date.';
  String get noUpcomingVisits => 'No Upcoming Visits';
  String get noUpcomingVisitsDesc => "You don't have a scheduled visit yet.";
  String get viewDetails => 'View Details';

  String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  // Profile Shell
  String get profileScreenTitle => 'Patient Profile';
  String get profileFullName => 'Full Name';
  String get profilePatientId => 'Patient ID';
  String get profileAge => 'Age';
  String get profileGender => 'Gender';
  String get profileBloodGroup => 'Blood Group';
  String get profileMobile => 'Registered Mobile';
  String get profileReadOnlyNotice => 'Identity information is managed by hospital administration.';
  String get logout => 'Log Out';
  String get logoutConfirm => 'Are you sure you want to log out?';
  String get resendInSeconds => 'Resend OTP in';
  String get seconds => 's';
  String get otpSentSuccess => 'OTP sent successfully.';
  String get invalidOtp => 'Invalid OTP. Please check the code and try again.';
  String get otpCooldownWait => 'Please wait before requesting a new OTP.';

  // Phase P10: Notifications & Profile
  String get notifications => 'Notifications';
  String get noNotifications => 'No Notifications';
  String get youreAllCaughtUp => "You're all caught up.";
  String get followUpReminder => 'Follow-up Reminder';
  String get followUpTomorrow => 'Follow-up Tomorrow';
  String get yourFollowUpIsScheduledTomorrow => 'Your follow-up visit is scheduled for tomorrow.';
  String get notificationSettings => 'Notification Settings';
  String get notificationsEnabled => 'Notifications Enabled';
  String get notificationsDisabled => 'Notifications Disabled';
  String get allowNotifications => 'Allow Notifications';
  String get notNow => 'Not Now';
  String get notificationRationale => 'Get reminders for your upcoming follow-up visits.';
  String get patientInformation => 'Patient Information';
  String get copiedToClipboard => 'Copied to clipboard';
  String get enabled => 'Enabled';
  String get disabled => 'Disabled';
  String get cancel => 'Cancel';
  String get markAllAsRead => 'Mark All as Read';
  String get viewNotificationCenter => 'View Notification Center';
}

/// Hindi Translations for the Patient App.
class PatientStringsHindi extends PatientStrings {
  const PatientStringsHindi();

  @override
  String get appTagline => 'बेहतर जीवन, साथ मिलकर';
  @override
  String get loading => 'लोड हो रहा है...';
  @override
  String get retry => 'पुनः प्रयास करें';
  @override
  String get back => 'वापस';
  @override
  String get close => 'बंद करें';
  @override
  String get errorTitle => 'कुछ त्रुटि हुई';
  @override
  String get errorMessage => 'अनुरोध पूरा नहीं हो सका। कृपया पुनः प्रयास करें।';
  @override
  String get noData => 'कोई जानकारी उपलब्ध नहीं है';

  @override
  String get tabHome => 'डैशबोर्ड';
  @override
  String get tabDashboard => 'डैशबोर्ड';
  @override
  String get tabCases => 'केस';
  @override
  String get tabReports => 'रिपोर्ट्स';
  @override
  String get tabCalendar => 'कैलेंडर';
  @override
  String get tabProfile => 'प्रोफाइल';

  @override
  String get loginHeading => 'मरीज लॉगिन';
  @override
  String get loginDescription => 'जारी रखने के लिए अपनी आयुसाथी मरीज आईडी दर्ज करें।';
  @override
  String get loginInputLabel => 'मरीज आईडी';
  @override
  String get loginInputHint => 'उदा. AAYU-102938';
  @override
  String get loginButton => 'आगे बढ़ें';
  @override
  String get loginErrorEmpty => 'कृपया अपनी मरीज आईडी दर्ज करें।';
  @override
  String get loginErrorInvalid => 'कृपया वैध मरीज आईडी प्रारूप दर्ज करें।';

  @override
  String get otpHeading => 'मोबाइल नंबर सत्यापित करें';
  @override
  String get otpDescription => 'आपके पंजीकृत मोबाइल नंबर पर ओटीपी भेजा जाएगा।';
  @override
  String get otpInputLabel => '6-अंकीय कोड दर्ज करें';
  @override
  String get otpVerifyButton => 'ओटीपी सत्यापित करें';
  @override
  String get otpResendButton => 'ओटीपी पुनः भेजें';
  @override
  String get otpDevNotice => 'विकास मोड: आगे बढ़ने के लिए कोई भी 6 अंक दर्ज करें';
  @override
  String get otpErrorInvalid => 'कृपया एक वैध 6-अंकीय कोड दर्ज करें।';

  @override
  String greeting(String name) => 'नमस्ते, $name';
  @override
  String greetingMorning(String name) => 'शुभ प्रभात, $name';
  @override
  String greetingAfternoon(String name) => 'शुभ दोपहर, $name';
  @override
  String greetingEvening(String name) => 'शुभ संध्या, $name';
  @override
  String get goodMorning => 'शुभ प्रभात';
  @override
  String get goodAfternoon => 'शुभ दोपहर';
  @override
  String get goodEvening => 'शुभ संध्या';
  @override
  String get defaultPatientName => 'मरीज';
  @override
  String get dashboardSubtitle => 'आपके स्वास्थ्य पोर्टल में आपका स्वागत है';
  @override
  String get nextVisitTitle => 'अगली मुलाकात';
  @override
  String get nextVisitEmpty => 'कोई आगामी मुलाकात नहीं';
  @override
  String get nextVisitEmptySubtitle => 'आपके पास कोई निर्धारित डॉक्टर अपॉइंटमेंट नहीं है।';
  @override
  String get ongoingCasesTitle => 'सक्रिय केस';
  @override
  String get ongoingCasesLabel => 'सक्रिय स्वास्थ्य जांच';
  @override
  String get noOngoingCasesTitle => 'कोई सक्रिय केस नहीं';
  @override
  String get noOngoingCasesSubtitle => 'इस समय आपका कोई सक्रिय मेडिकल केस नहीं है।';
  @override
  String get quickAccessTitle => 'त्वरित पहुंच';
  @override
  String get quickAccessCases => 'केस देखें';
  @override
  String get quickAccessCasesDesc => 'सक्रिय और पुराने केस देखें';
  @override
  String get quickAccessReports => 'रिपोर्ट्स देखें';
  @override
  String get quickAccessReportsDesc => 'जांच रिपोर्ट देखें';
  @override
  String get quickAccessUpcoming => 'आगामी मुलाकात';
  @override
  String get quickAccessUpcomingDesc => 'परामर्श की तारीख देखें';
  @override
  String get quickAccessCalendar => 'कैलेंडर';
  @override
  String get quickAccessCalendarDesc => 'स्वास्थ्य कार्यक्रम देखें';
  @override
  String get healthSummaryTitle => 'स्वास्थ्य सारांश';
  @override
  String get unableToLoadData => 'जानकारी लोड नहीं हो सकी।';

  @override
  String get casesScreenTitle => 'केस';
  @override
  String get casesTabActive => 'सक्रिय';
  @override
  String get casesTabCompleted => 'पूर्ण';
  @override
  String get casesEmptyActive => 'कोई सक्रिय केस नहीं';
  @override
  String get casesEmptyActiveDesc => 'इस समय आपका कोई सक्रिय मेडिकल केस नहीं है।';
  @override
  String get casesEmptyCompleted => 'कोई पूर्ण केस नहीं';
  @override
  String get casesEmptyCompletedDesc => 'आपके पास अभी कोई पूर्ण केस नहीं है।';
  @override
  String get casesErrorLoading => 'केस लोड नहीं किए जा सके।\nकृपया पुनः प्रयास करें।';
  @override
  String get caseDetailTitle => 'केस विवरण';
  @override
  String get caseHistoryTitle => 'केस इतिहास';
  @override
  String get visitHistoryTitle => 'मुलाकात इतिहास';
  @override
  String get caseStatusOpen => 'सक्रिय';
  @override
  String get caseStatusOngoing => 'सक्रिय';
  @override
  String get caseStatusClosed => 'पूर्ण';
  @override
  String get caseStatusEscalated => 'विशेषज्ञ समीक्षाधीन';
  @override
  String get caseVisitsCount => 'मुलाकातें';
  @override
  String formatVisits(int count) => count == 1 ? '1 मुलाकात' : '$count मुलाकातें';
  @override
  String visitNumberLabel(int number) => 'मुलाकात $number';
  @override
  String get caseStartedDate => 'शुरुआत की तारीख';
  @override
  String get caseCompletedDate => 'पूर्ण होने की तारीख';
  @override
  String get caseLastVisit => 'अंतिम मुलाकात';
  @override
  String get visitDetailTitle => 'मुलाकात विवरण';
  @override
  String get visitDoctor => 'उपस्थित डॉक्टर';
  @override
  String get visitDoctorTitle => 'डॉक्टर';
  @override
  String get visitDate => 'परामर्श तारीख';
  @override
  String get visitDepartment => 'विभाग';
  @override
  String get noVisitsYet => 'कोई मुलाकात नहीं';
  @override
  String get noVisitsYetDesc => 'इस केस के अंतर्गत अभी तक कोई परामर्श दर्ज नहीं हुआ है।';
  @override
  String get unableToLoadCaseDetails => 'केस विवरण लोड नहीं किया जा सका।\nकृपया पुनः प्रयास करें।';
  @override
  String get unableToLoadVisitHistory => 'मुलाकात इतिहास लोड नहीं किया जा सका।\nकृपया पुनः प्रयास करें।';
  @override
  String get notRecorded => 'दर्ज नहीं किया गया';
  @override
  String get vitalsTitle => 'वाइटल्स (शारीरिक माप)';
  @override
  String get spo2Label => 'SpO₂';
  @override
  String get heartRateLabel => 'हृदय गति';
  @override
  String get temperatureLabel => 'तापमान';
  @override
  String get consultationSummaryTitle => 'परामर्श सारांश';
  @override
  String get consultationDetailsTitle => 'परामर्श विवरण';
  @override
  String get chiefComplaintLabel => 'मुख्य शिकायत';
  @override
  String get onsetDurationLabel => 'शुरुआत / अवधि';
  @override
  String get associatedSymptomsLabel => 'संबंधित लक्षण';
  @override
  String get medicalHistoryLabel => 'चिकित्सा इतिहास';
  @override
  String get currentMedicationLabel => 'वर्तमान दवाएं';
  @override
  String get clinicalObservationsLabel => 'क्लिनिकल अवलोकन';
  @override
  String get assessmentLabel => 'मूल्यांकन';
  @override
  String get planLabel => 'योजना';
  @override
  String get prescriptionsTitle => 'दवाएं / नुस्खा';
  @override
  String get followUpTitle => 'फॉलो-अप';
  @override
  String get patientInstructionsTitle => 'निर्देश';
  @override
  String get requestedInvestigationsTitle => 'आवश्यक जांचें';
  @override
  String get doctorApprovedNotice => 'डॉक्टर द्वारा स्वीकृत';
  @override
  String get pendingDoctorApprovalNotice => 'डॉक्टर की मंजूरी लंबित';
  @override
  String get visitOverviewTitle => 'मुलाकात विवरण';
  @override
  String get doctorApprovedSummaryTitle => 'डॉक्टर द्वारा स्वीकृत सारांश';
  @override
  String get consultationTitle => 'परामर्श';
  @override
  String get prescriptionTitle => 'दवाइयाँ';
  @override
  String get investigationsTitle => 'जांच और परीक्षण';
  @override
  String get reportRequiredAction => 'रिपोर्ट आवश्यक';
  @override
  String get reportSubmittedStatus => 'रिपोर्ट जमा की गई';
  @override
  String get reportReviewedStatus => 'रिपोर्ट जांची गई';
  @override
  String get pendingUploadStatus => 'अपलोड बाकी';
  @override
  String get uploadedStatus => 'अपलोड किया गया';
  @override
  String get reviewedStatus => 'समीक्षित';
  @override
  String get noReportsRequiredTitle => 'कोई रिपोर्ट आवश्यक नहीं';
  @override
  String get summaryNotAvailable => 'सारांश उपलब्ध नहीं है।';
  @override
  String get viewDashboardAction => 'डैशबोर्ड देखें';
  @override
  String get examinationFindingsLabel => 'परीक्षण निष्कर्ष';
  @override
  String get treatmentPlanLabel => 'उपचार योजना';
  @override
  String get dietaryAdviceLabel => 'आहार संबंधी सलाह';
  @override
  String get lifestyleAdviceLabel => 'जीवनशैली सलाह';
  @override
  String get warningSignsLabel => 'चेतावनी संकेत / खतरे के लक्षण';
  @override
  String get historyOfPresentIllnessLabel => 'वर्तमान बीमारी का इतिहास';
  @override
  String get statusPendingUpload => 'अपलोड करना बाकी';
  @override
  String get statusAvailableForDownload => 'डाउनलोड के लिए उपलब्ध';

  @override
  String get reportsScreenTitle => 'रिपोर्ट्स';
  @override
  String get reportsTabSubmitted => 'जमा की गई';
  @override
  String get reportsTabYetToSubmit => 'जमा करनी बाकी';
  @override
  String get reportsEmptySubmitted => 'कोई रिपोर्ट जमा नहीं है';
  @override
  String get reportsEmptySubmittedDesc => 'आपकी जमा की गई लैब रिपोर्ट यहाँ दिखाई देंगी।';
  @override
  String get reportsEmptyYetToSubmit => 'कोई रिपोर्ट आवश्यक नहीं';
  @override
  String get reportsEmptyYetToSubmitDesc => 'इस समय आपकी कोई रिपोर्ट जमा करने हेतु लंबित नहीं है।';
  @override
  String get reportDetailTitle => 'रिपोर्ट विवरण';
  @override
  String get reportInvestigationName => 'जांच का नाम';
  @override
  String get reportRequestedDate => 'मुलाकात तारीख';
  @override
  String get reportSubmissionDate => 'जमा करने की तारीख';
  @override
  String get reportCaseLabel => 'केस';
  @override
  String get reportPriorityLabel => 'प्राथमिकता';
  @override
  String get reportRequiredStatus => 'रिपोर्ट आवश्यक';
  @override
  String get submitReportAction => 'रिपोर्ट जमा करें';
  @override
  String get submitReportGuidanceTitle => 'रिपोर्ट जमा करने के निर्देश';
  @override
  String get submitReportGuidanceDesc => 'कृपया अपनी रिपोर्ट अस्पताल के संकलन केंद्र पर या अपनी अगली परामर्श मुलाकात के दौरान जमा करें। ऑनलाइन रिपोर्ट अपलोड जल्द शुरू किया जाएगा।';
  @override
  String get unableToLoadReports => 'रिपोर्ट लोड नहीं की जा सकीं।\nकृपया पुनः प्रयास करें।';
  @override
  String get unableToLoadAppointments => 'आगामी मुलाकात लोड नहीं की जा सकी।\nकृपया पुनः प्रयास करें।';
  @override
  String get reportStatusUploaded => 'जमा की गई';
  @override
  String get reportStatusPending => 'रिपोर्ट आवश्यक';
  @override
  String get viewReportButton => 'रिपोर्ट देखें';

  // Phase P8 — Report Upload Strings
  @override
  String get uploadReportTitle => 'रिपोर्ट अपलोड करें';
  @override
  String get takePhotoAction => 'फोटो लें';
  @override
  String get chooseFromGalleryAction => 'गैलरी से चुनें';
  @override
  String get previewTitle => 'पूर्वावलोकन';
  @override
  String get retakeAction => 'पुनः लें';
  @override
  String get chooseAnotherAction => 'दूसरा चुनें';
  @override
  String get submitReportConfirmTitle => 'क्या आप यह रिपोर्ट सबमिट करना चाहते हैं?';
  @override
  String get submitReportConfirmDesc => 'आपकी रिपोर्ट फोटो सुरक्षित रूप से समीक्षा के लिए आपके उपस्थित डॉक्टर को भेजी जाएगी।';
  @override
  String get uploadingReportProgress => 'रिपोर्ट अपलोड हो रहा है...';
  @override
  String get reportSubmittedSuccessTitle => 'रिपोर्ट सफलतापूर्वक सबमिट की गई';
  @override
  String get reportSubmittedSuccessDesc => 'आपकी रिपोर्ट समीक्षा के लिए जमा कर दी गई है।';
  @override
  String get uploadFailedTitle => 'अपलोड विफल रहा';
  @override
  String get uploadFailedDesc => 'कृपया पुनः प्रयास करें।';
  @override
  String get cameraPermissionRequired => 'रिपोर्ट का फोटो लेने के लिए कैमरा अनुमति आवश्यक है।';
  @override
  String get photoAccessRequired => 'रिपोर्ट चुनने के लिए फोटो एक्सेस आवश्यक है।';
  @override
  String get cancelAction => 'रद्द करें';
  @override
  String get doneAction => 'पूर्ण';
  @override
  String get addAnotherPhotoAction => 'अन्य फोटो जोड़ें';
  @override
  String get removePhotoAction => 'हटाएं';
  @override
  String pageNumberLabel(int current, int total) => 'पृष्ठ $current / $total';
  @override
  String get viewVisitReportPdfButton => 'विज़िट रिपोर्ट पीडीएफ देखें';
  @override
  String get officialVisitReportTitle => 'आधिकारिक विज़िट रिपोर्ट';
  @override
  String get visitReportPdfNotAvailable => 'विज़िट रिपोर्ट पीडीएफ अभी उपलब्ध नहीं है।';
  @override
  String get visitReportPdfNotAvailableDesc => 'डॉक्टर द्वारा हस्ताक्षरित रिपोर्ट तैयार होने पर यहाँ उपलब्ध होगी।';
  @override
  String get visitReportPdfViewerTitle => 'विज़िट रिपोर्ट पीडीएफ';
  @override
  String get loadingVisitReportPdf => 'विज़िट रिपोर्ट लोड हो रही है...';
  @override
  String get unableToLoadVisitPdf => 'विज़िट रिपोर्ट पीडीएफ लोड करने में असमर्थ। कृपया पुनः प्रयास करें।';
  @override
  String get retryButton => 'पुनः प्रयास करें';

  @override
  String get calendarScreenTitle => 'स्वास्थ्य कैलेंडर';
  @override
  String get calendar => 'कैलेंडर';
  @override
  String get calendarToday => 'आज';
  @override
  String get previousMonth => 'पिछला महीना';
  @override
  String get nextMonth => 'अगला महीना';
  @override
  String get calendarUpcomingAppointments => 'आगामी अपॉइंटमेंट्स';
  @override
  String get calendarNoEvents => 'इस दिन के लिए कोई अपॉइंटमेंट या फॉलो-अप निर्धारित नहीं है।';
  @override
  String get calendarEventVisit => 'ओपीडी परामर्श';
  @override
  String get calendarEventFollowUp => 'फॉलो-अप समीक्षा';
  @override
  String get followUpVisit => 'फॉलो-अप परामर्श';
  @override
  String get upcomingFollowUp => 'आगामी फॉलो-अप';
  @override
  String get pastFollowUp => 'पिछला फॉलो-अप';
  @override
  String get noFollowUpScheduled => 'कोई फॉलो-अप निर्धारित नहीं';
  @override
  String get noFollowUpScheduledDesc => 'इस तिथि के लिए कोई फॉलो-अप निर्धारित नहीं है।';
  @override
  String get noUpcomingVisits => 'कोई आगामी मुलाकात नहीं';
  @override
  String get noUpcomingVisitsDesc => 'आपके पास अभी कोई निर्धारित मुलाकात नहीं है।';
  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String monthName(int month) {
    const months = [
      'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  String get profileScreenTitle => 'मरीज प्रोफाइल';
  @override
  String get profileFullName => 'पूरा नाम';
  @override
  String get profilePatientId => 'मरीज आईडी';
  @override
  String get profileAge => 'आयु';
  @override
  String get profileGender => 'लिंग';
  @override
  String get profileBloodGroup => 'रक्त समूह';
  @override
  String get profileMobile => 'पंजीकृत मोबाइल';
  @override
  String get profileReadOnlyNotice => 'पहचान संबंधी जानकारी अस्पताल प्रशासन द्वारा प्रबंधित की जाती है।';
  @override
  String get logout => 'लॉग आउट';
  @override
  String get logoutConfirm => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';
  @override
  String get resendInSeconds => 'ओटीपी पुनः भेजें';
  @override
  String get seconds => 'सेकंड';
  @override
  String get otpSentSuccess => 'ओटीपी सफलतापूर्वक भेजा गया।';
  @override
  String get invalidOtp => 'अमान्य ओटीपी। कृपया कोड जांचें और पुनः प्रयास करें।';
  @override
  String get otpCooldownWait => 'कृपया नया ओटीपी अनुरोध करने से पहले प्रतीक्षा करें।';

  // Phase P10: Notifications & Profile
  @override
  String get notifications => 'सूचनाएं';
  @override
  String get noNotifications => 'कोई सूचना नहीं';
  @override
  String get youreAllCaughtUp => 'आप पूरी तरह से अपडेट हैं।';
  @override
  String get followUpReminder => 'फॉलो-अप अनुस्मारक';
  @override
  String get followUpTomorrow => 'कल फॉलो-अप';
  @override
  String get yourFollowUpIsScheduledTomorrow => 'आपकी फॉलो-अप मुलाकात कल के लिए निर्धारित है।';
  @override
  String get notificationSettings => 'सूचना सेटिंग्स';
  @override
  String get notificationsEnabled => 'सूचनाएं सक्रिय';
  @override
  String get notificationsDisabled => 'सूचनाएं निष्क्रिय';
  @override
  String get allowNotifications => 'सूचनाओं की अनुमति दें';
  @override
  String get notNow => 'अभी नहीं';
  @override
  String get notificationRationale => 'अपनी आगामी फॉलो-अप मुलाकातों के लिए अनुस्मारक प्राप्त करें।';
  @override
  String get patientInformation => 'रोगी जानकारी';
  @override
  String get copiedToClipboard => 'क्लिपबोर्ड पर कॉपी किया गया';
  @override
  String get enabled => 'सक्रिय';
  @override
  String get disabled => 'निष्क्रिय';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get markAllAsRead => 'सभी को पढ़ा हुआ चिह्नित करें';
  @override
  String get viewNotificationCenter => 'सूचना केंद्र देखें';
}

/// Marathi Translations for the Patient App.
class PatientStringsMarathi extends PatientStrings {
  const PatientStringsMarathi();

  @override
  String get appTagline => 'चांगले जगा, एकत्र';
  @override
  String get loading => 'लोड होत आहे...';
  @override
  String get retry => 'पुन्हा प्रयत्न करा';
  @override
  String get back => 'मागे';
  @override
  String get close => 'बंद करा';
  @override
  String get errorTitle => 'काहीतरी त्रुटी झाली';
  @override
  String get errorMessage => 'विनंती पूर्ण होऊ शकली नाही. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get noData => 'माहिती उपलब्ध नाही';

  @override
  String get tabHome => 'डॅशबोर्ड';
  @override
  String get tabDashboard => 'डॅशबोर्ड';
  @override
  String get tabCases => 'केसेस';
  @override
  String get tabReports => 'अहवाल';
  @override
  String get tabCalendar => 'कॅलेंडर';
  @override
  String get tabProfile => 'प्रोफाइल';

  @override
  String get loginHeading => 'रुग्ण लॉगिन';
  @override
  String get loginDescription => 'पुढे जाण्यासाठी आपली आयुसाथी रुग्ण आयडी प्रविष्ट करा.';
  @override
  String get loginInputLabel => 'रुग्ण आयडी';
  @override
  String get loginInputHint => 'उदा. AAYU-102938';
  @override
  String get loginButton => 'पुढे चला';
  @override
  String get loginErrorEmpty => 'कृपया आपली रुग्ण आयडी प्रविष्ट करा.';
  @override
  String get loginErrorInvalid => 'कृपया वैध रुग्ण आयडी प्रविष्ट करा.';

  @override
  String get otpHeading => 'मोबाईल क्रमांक सत्यापित करा';
  @override
  String get otpDescription => 'आपल्या नोंदणीकृत मोबाईल क्रमांकावर ओटीपी पाठवला जाईल.';
  @override
  String get otpInputLabel => '६-अंकी कोड प्रविष्ट करा';
  @override
  String get otpVerifyButton => 'ओटीपी सत्यापित करा';
  @override
  String get otpResendButton => 'ओटीपी पुन्हा पाठवा';
  @override
  String get otpDevNotice => 'विकास मोड: पुढे जाण्यासाठी कोणतेही ६ अंक प्रविष्ट करा';
  @override
  String get otpErrorInvalid => 'कृपया वैध ६-अंकी कोड प्रविष्ट करा.';

  @override
  String greeting(String name) => 'नमस्कार, $name';
  @override
  String greetingMorning(String name) => 'शुभ प्रभात, $name';
  @override
  String greetingAfternoon(String name) => 'शुभ दुपार, $name';
  @override
  String greetingEvening(String name) => 'शुभ संध्याकाळ, $name';
  @override
  String get goodMorning => 'शुभ प्रभात';
  @override
  String get goodAfternoon => 'शुभ दुपार';
  @override
  String get goodEvening => 'शुभ संध्याकाळ';
  @override
  String get defaultPatientName => 'रुग्ण';
  @override
  String get dashboardSubtitle => 'आपल्या आरोग्य पोर्टलवर आपले स्वागत आहे';
  @override
  String get nextVisitTitle => 'पुढील भेट';
  @override
  String get nextVisitEmpty => 'कोणतीही आगामी भेट नाही';
  @override
  String get nextVisitEmptySubtitle => 'आपल्याकडे कोणतीही नियोजित भेट नाही.';
  @override
  String get ongoingCasesTitle => 'सुरू असलेल्या केसेस';
  @override
  String get ongoingCasesLabel => 'सक्रिय वैद्यकीय तपासणी';
  @override
  String get noOngoingCasesTitle => 'कोणतीही सक्रिय केस नाही';
  @override
  String get noOngoingCasesSubtitle => 'सध्या आपल्याकडे कोणतीही सक्रिय केस नाही.';
  @override
  String get quickAccessTitle => 'जलद प्रवेश';
  @override
  String get quickAccessCases => 'केसेस पहा';
  @override
  String get quickAccessCasesDesc => 'सक्रिय आणि मागील केसेस पहा';
  @override
  String get quickAccessReports => 'अहवाल पहा';
  @override
  String get quickAccessReportsDesc => 'चाचणी अहवाल पहा';
  @override
  String get quickAccessUpcoming => 'आगामी भेट';
  @override
  String get quickAccessUpcomingDesc => 'सल्लामसलत तारीख तपासा';
  @override
  String get quickAccessCalendar => 'कॅलेंडर';
  @override
  String get quickAccessCalendarDesc => 'आरोग्य वेळापत्रक पहा';
  @override
  String get healthSummaryTitle => 'आरोग्य सारांश';
  @override
  String get unableToLoadData => 'माहिती लोड करणे अशक्य झाले.';

  @override
  String get casesScreenTitle => 'केसेस';
  @override
  String get casesTabActive => 'सक्रिय';
  @override
  String get casesTabCompleted => 'पूर्ण';
  @override
  String get casesEmptyActive => 'कोणतीही सक्रिय केस नाही';
  @override
  String get casesEmptyActiveDesc => 'सध्या आपल्याकडे कोणतीही सक्रिय केस नाही.';
  @override
  String get casesEmptyCompleted => 'कोणतीही पूर्ण केस नाही';
  @override
  String get casesEmptyCompletedDesc => 'आपल्याकडे अद्याप कोणतीही पूर्ण केस नाही.';
  @override
  String get casesErrorLoading => 'केसेस लोड करणे शक्य झाले नाही.\nकृपया पुन्हा प्रयत्न करा.';
  @override
  String get caseDetailTitle => 'केस तपशील';
  @override
  String get caseHistoryTitle => 'केस इतिहास';
  @override
  String get visitHistoryTitle => 'भेट इतिहास';
  @override
  String get caseStatusOpen => 'सुरू';
  @override
  String get caseStatusOngoing => 'सुरू';
  @override
  String get caseStatusClosed => 'पूर्ण';
  @override
  String get caseStatusEscalated => 'तज्ज्ञ पुनरावलोकनाधीन';
  @override
  String get caseVisitsCount => 'भेटी';
  @override
  String formatVisits(int count) => count == 1 ? '1 भेट' : '$count भेटी';
  @override
  String visitNumberLabel(int number) => 'भेट $number';
  @override
  String get caseStartedDate => 'सुरुवात तारीख';
  @override
  String get caseCompletedDate => 'पूर्ण झाल्याची तारीख';
  @override
  String get caseLastVisit => 'शेवटची भेट';
  @override
  String get visitDetailTitle => 'भेट तपशील';
  @override
  String get visitDoctor => 'उपस्थित डॉक्टर';
  @override
  String get visitDoctorTitle => 'डॉक्टर';
  @override
  String get visitDate => 'सल्लामसलत तारीख';
  @override
  String get visitDepartment => 'विभाग';
  @override
  String get noVisitsYet => 'कोणतीही भेट नाही';
  @override
  String get noVisitsYetDesc => 'या केससाठी अद्याप कोणतीही भेट नोंदवली गेलेली नाही.';
  @override
  String get unableToLoadCaseDetails => 'केस तपशील लोड करणे शक्य झाले नाही.\nकृपया पुन्हा प्रयत्न करा.';
  @override
  String get unableToLoadVisitHistory => 'भेट इतिहास लोड करणे शक्य झाले नाही.\nकृपया पुन्हा प्रयत्न करा.';
  @override
  String get notRecorded => 'नोंदवले नाही';
  @override
  String get vitalsTitle => 'व्हायटल्स (शारीरिक मापे)';
  @override
  String get spo2Label => 'SpO₂';
  @override
  String get heartRateLabel => 'हृदय गती';
  @override
  String get temperatureLabel => 'तापमान';
  @override
  String get consultationSummaryTitle => 'सल्लामसलत सारांश';
  @override
  String get consultationDetailsTitle => 'सल्लामसलत तपशील';
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
  String get prescriptionsTitle => 'औषधे / प्रिस्क्रिप्शन';
  @override
  String get followUpTitle => 'फॉलो-अप';
  @override
  String get patientInstructionsTitle => 'सूचना';
  @override
  String get requestedInvestigationsTitle => 'मागणी केलेल्या तपासण्या';
  @override
  String get doctorApprovedNotice => 'डॉक्टरांद्वारे मंजूर';
  @override
  String get pendingDoctorApprovalNotice => 'डॉक्टरांची मंजुरी प्रलंबित';
  @override
  String get visitOverviewTitle => 'भेट तपशील';
  @override
  String get doctorApprovedSummaryTitle => 'डॉक्टरांनी मंजूर केलेला सारांश';
  @override
  String get consultationTitle => 'सल्लामसलत';
  @override
  String get prescriptionTitle => 'औषधे / प्रिस्क्रिप्शन';
  @override
  String get investigationsTitle => 'तपासण्या';
  @override
  String get reportRequiredAction => 'अहवाल आवश्यक';
  @override
  String get reportSubmittedStatus => 'अहवाल सादर केला';
  @override
  String get reportReviewedStatus => 'अहवाल पुनरावलोकन पूर्ण';
  @override
  String get pendingUploadStatus => 'अपलोड प्रलंबित';
  @override
  String get uploadedStatus => 'अपलोड केले';
  @override
  String get reviewedStatus => 'पुनरावलोकन केले';
  @override
  String get noReportsRequiredTitle => 'कोणत्याही अहवालाची आवश्यकता नाही';
  @override
  String get summaryNotAvailable => 'सारांश उपलब्ध नाही.';
  @override
  String get viewDashboardAction => 'डॅशबोर्ड पहा';
  @override
  String get examinationFindingsLabel => 'तपासणी निष्कर्ष';
  @override
  String get treatmentPlanLabel => 'उपचार योजना';
  @override
  String get dietaryAdviceLabel => 'आहारविषयक सल्ला';
  @override
  String get lifestyleAdviceLabel => 'जीवनशैली सल्ला';
  @override
  String get warningSignsLabel => 'धोक्याची चिन्हे / लक्षणे';
  @override
  String get historyOfPresentIllnessLabel => 'सध्याच्या आजाराचा इतिहास';
  @override
  String get statusPendingUpload => 'अपलोड करणे बाकी';
  @override
  String get statusAvailableForDownload => 'डाऊनलोडसाठी उपलब्ध';

  @override
  String get reportsScreenTitle => 'अहवाल';
  @override
  String get reportsTabSubmitted => 'सादर केलेले';
  @override
  String get reportsTabYetToSubmit => 'सादर करायचे बाकी';
  @override
  String get reportsEmptySubmitted => 'कोणतेही अहवाल सादर केलेले नाहीत';
  @override
  String get reportsEmptySubmittedDesc => 'आपण अद्याप कोणतेही अहवाल सादर केलेले नाहीत.';
  @override
  String get reportsEmptyYetToSubmit => 'कोणत्याही अहवालाची आवश्यकता नाही';
  @override
  String get reportsEmptyYetToSubmitDesc => 'सध्या कोणताही अहवाल सादर करण्यासाठी प्रलंबित नाही.';
  @override
  String get reportDetailTitle => 'अहवाल तपशील';
  @override
  String get reportInvestigationName => 'तपासणीचे नाव';
  @override
  String get reportRequestedDate => 'भेट तारीख';
  @override
  String get reportSubmissionDate => 'सादर केल्याची तारीख';
  @override
  String get reportCaseLabel => 'केस';
  @override
  String get reportPriorityLabel => 'प्राधान्य';
  @override
  String get reportRequiredStatus => 'अहवाल आवश्यक';
  @override
  String get submitReportAction => 'अहवाल सादर करा';
  @override
  String get submitReportGuidanceTitle => 'अहवाल सादर करण्याबाबत मार्गदर्शन';
  @override
  String get submitReportGuidanceDesc => 'कृपया आपला अहवाल रुग्णालयाच्या संकलन केंद्रात किंवा पुढील भेटीच्या वेळी जमा करा. ऑनलाइन अहवाल अपलोड लवकरच उपलब्ध होईल.';
  @override
  String get unableToLoadReports => 'अहवाल लोड करणे शक्य झाले नाही.\nकृपया पुन्हा प्रयत्न करा.';
  @override
  String get unableToLoadAppointments => 'आगामी भेटी लोड करणे शक्य झाले नाही.\nकृपया पुन्हा प्रयत्न करा.';
  @override
  String get reportStatusUploaded => 'सादर केले';
  @override
  String get reportStatusPending => 'अहवाल आवश्यक';
  @override
  String get viewReportButton => 'अहवाल पहा';

  // Phase P8 — Report Upload Strings
  @override
  String get uploadReportTitle => 'अहवाल अपलोड करा';
  @override
  String get takePhotoAction => 'फोटो काढा';
  @override
  String get chooseFromGalleryAction => 'गॅलरीमधून निवडा';
  @override
  String get previewTitle => 'पूर्वावलोकन';
  @override
  String get retakeAction => 'पुन्हा काढा';
  @override
  String get chooseAnotherAction => 'दुसरा निवडा';
  @override
  String get submitReportConfirmTitle => 'तुम्ही हा अहवाल सबमिट करू इच्छिता?';
  @override
  String get submitReportConfirmDesc => 'तुमचा अहवाल फोटो तपासणीसाठी तुमच्या डॉक्टरांकडे सुरक्षितपणे पाठवला जाईल.';
  @override
  String get uploadingReportProgress => 'अहवाल अपलोड होत आहे...';
  @override
  String get reportSubmittedSuccessTitle => 'अहवाल यशस्वीरित्या सादर केला';
  @override
  String get reportSubmittedSuccessDesc => 'तुमचा अहवाल तपासणीसाठी सादर करण्यात आला आहे.';
  @override
  String get uploadFailedTitle => 'अपलोड अयशस्वी झाले';
  @override
  String get uploadFailedDesc => 'कृपया पुन्हा प्रयत्न करा.';
  @override
  String get cameraPermissionRequired => 'अहवालाचा फोटो काढण्यासाठी कॅमेरा परवानगी आवश्यक आहे.';
  @override
  String get photoAccessRequired => 'अहवाल निवडण्यासाठी फोटो ॲक्सेस आवश्यक आहे.';
  @override
  String get cancelAction => 'रद्द करा';
  @override
  String get doneAction => 'पूर्ण';
  @override
  String get addAnotherPhotoAction => 'आणखी फोटो जोडा';
  @override
  String get removePhotoAction => 'काढून टाका';
  @override
  String pageNumberLabel(int current, int total) => 'पान $current / $total';
  @override
  String get viewVisitReportPdfButton => 'भेट अहवाल पीडीएफ पहा';
  @override
  String get officialVisitReportTitle => 'अधिकृत भेट अहवाल';
  @override
  String get visitReportPdfNotAvailable => 'भेट अहवाल पीडीएफ अद्याप उपलब्ध नाही.';
  @override
  String get visitReportPdfNotAvailableDesc => 'डॉक्टरांनी स्वाक्षरी केलेला अहवाल तयार झाल्यावर येथे दिसेल.';
  @override
  String get visitReportPdfViewerTitle => 'भेट अहवाल पीडीएफ';
  @override
  String get loadingVisitReportPdf => 'भेट अहवाल लोड होत आहे...';
  @override
  String get unableToLoadVisitPdf => 'भेट अहवाल पीडीएफ लोड करण्यात अक्षम. कृपया पुन्हा प्रयत्न करा.';
  @override
  String get retryButton => 'पुन्हा प्रयत्न करा';

  @override
  String get calendarScreenTitle => 'आरोग्य कॅलेंडर';
  @override
  String get calendar => 'कॅलेंडर';
  @override
  String get calendarToday => 'आज';
  @override
  String get previousMonth => 'मागील महिना';
  @override
  String get nextMonth => 'पुढील महिना';
  @override
  String get calendarUpcomingAppointments => 'आगामी भेटी';
  @override
  String get calendarNoEvents => 'या दिवसासाठी कोणतीही भेट किंवा तपासणी नियोजित नाही.';
  @override
  String get calendarEventVisit => 'ओपीडी सल्लामसलत';
  @override
  String get calendarEventFollowUp => 'पुढील तपासणी';
  @override
  String get followUpVisit => 'पुढील तपासणी भेट';
  @override
  String get upcomingFollowUp => 'आगामी पुढील तपासणी';
  @override
  String get pastFollowUp => 'मागील पुढील तपासणी';
  @override
  String get noFollowUpScheduled => 'कोणतीही पुढील तपासणी नियोजित नाही';
  @override
  String get noFollowUpScheduledDesc => 'या तारखेसाठी कोणतीही पुढील तपासणी नियोजित नाही.';
  @override
  String get noUpcomingVisits => 'कोणतीही आगामी भेट नाही';
  @override
  String get noUpcomingVisitsDesc => 'आपल्याकडे अद्याप कोणतीही नियोजित भेट नाही.';
  @override
  String get viewDetails => 'तपशील पहा';

  @override
  String monthName(int month) {
    const months = [
      'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
      'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  @override
  String get profileScreenTitle => 'रुग्ण प्रोफाइल';
  @override
  String get profileFullName => 'पूर्ण नाव';
  @override
  String get profilePatientId => 'रुग्ण आयडी';
  @override
  String get profileAge => 'वय';
  @override
  String get profileGender => 'लिंग';
  @override
  String get profileBloodGroup => 'रक्तगट';
  @override
  String get profileMobile => 'नोंदणीकृत मोबाईल';
  @override
  String get profileReadOnlyNotice => 'ओळख माहिती रुग्णालय प्रशासनाद्वारे व्यवस्थापित केली जाते.';
  @override
  String get logout => 'लॉग आउट';
  @override
  String get logoutConfirm => 'आपण नक्की लॉग आउट करू इच्छिता?';
  @override
  String get resendInSeconds => 'ओटीपी पुन्हा पाठवा';
  @override
  String get seconds => 'सेकंद';
  @override
  String get otpSentSuccess => 'ओटीपी यशस्वीरित्या पाठवला गेला.';
  @override
  String get invalidOtp => 'अवैध ओटीपी. कृपया कोड तपासा आणि पुन्हा प्रयत्न करा.';
  @override
  String get otpCooldownWait => 'कृपया नवीन ओटीपी मागण्यापूर्वी प्रतीक्षा करा.';

  // Phase P10: Notifications & Profile
  @override
  String get notifications => 'सूचना';
  @override
  String get noNotifications => 'कोणतीही सूचना नाही';
  @override
  String get youreAllCaughtUp => 'आपण पूर्णपणे अद्ययावत आहात.';
  @override
  String get followUpReminder => 'पाठपुरावा स्मरणपत्र';
  @override
  String get followUpTomorrow => 'उद्या पाठपुरावा';
  @override
  String get yourFollowUpIsScheduledTomorrow => 'तुमची पाठपुरावा भेट उद्यासाठी नियोजित आहे.';
  @override
  String get notificationSettings => 'सूचना सेटिंग्ज';
  @override
  String get notificationsEnabled => 'सूचना सक्षम';
  @override
  String get notificationsDisabled => 'सूचना अक्षम';
  @override
  String get allowNotifications => 'सूचनांना परवानगी द्या';
  @override
  String get notNow => 'आता नाही';
  @override
  String get notificationRationale => 'आपल्या आगामी पाठपुरावा भेटींसाठी स्मरणपत्रे मिळवा.';
  @override
  String get patientInformation => 'रुग्ण माहिती';
  @override
  String get copiedToClipboard => 'क्लिपबोर्डवर कॉपी केले';
  @override
  String get enabled => 'सक्षम';
  @override
  String get disabled => 'अक्षम';
  @override
  String get cancel => 'रद्द करा';
  @override
  String get markAllAsRead => 'सर्व वाचलेले म्हणून चिन्हांकित करा';
  @override
  String get viewNotificationCenter => 'सूचना केंद्र पहा';
}
