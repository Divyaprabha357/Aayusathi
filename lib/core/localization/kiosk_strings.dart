import 'kiosk_locale.dart';

/// Centralized typed dictionary holding all UI text for AAYUSATHI Kiosk
/// across English, Hindi, and Marathi.
class KioskStrings {
  final KioskLocale locale;

  const KioskStrings(this.locale);

  // Standby Screen
  String get appName => 'AAYUSATHI';
  String get appTagline => 'LIVE BETTER, TOGETHER';
  String get healthJourney => switch (locale) {
        KioskLocale.english => 'Your health, your care, your journey.',
        KioskLocale.hindi => 'आपका स्वास्थ्य, आपकी देखभाल, आपका सफर।',
        KioskLocale.marathi => 'तुमचे आरोग्य, तुमची काळजी, तुमचा प्रवास.',
      };
  String get touchToBegin => switch (locale) {
        KioskLocale.english => 'TOUCH ANYWHERE TO BEGIN',
        KioskLocale.hindi => 'शुरू करने के लिए कहीं भी स्पर्श करें',
        KioskLocale.marathi => 'सुरू करण्यासाठी कुठेही स्पर्श करा',
      };

  // Language Selection Screen
  String get selectLanguage => switch (locale) {
        KioskLocale.english => 'Select Your Language',
        KioskLocale.hindi => 'अपनी भाषा चुनें',
        KioskLocale.marathi => 'आपली भाषा निवडा',
      };
  String get chooseLanguageSubtitle => switch (locale) {
        KioskLocale.english => 'Please choose your preferred language to proceed with the OPD registration.',
        KioskLocale.hindi => 'ओपीडी पंजीकरण जारी रखने के लिए कृपया अपनी पसंदीदा भाषा चुनें।',
        KioskLocale.marathi => 'कृपया ओपीडी नोंदणीसाठी आपली प्राधान्य दिलेली भाषा निवडा.',
      };

  // User Type (New / Existing) Screen
  String get howCanWeHelp => switch (locale) {
        KioskLocale.english => 'How can we help you today?',
        KioskLocale.hindi => 'आज हम आपकी क्या मदद कर सकते हैं?',
        KioskLocale.marathi => 'आज आम्ही तुम्हाला कशी मदत करू शकतो?',
      };
  String get patientCheckIn => switch (locale) {
        KioskLocale.english => 'Patient Check-In',
        KioskLocale.hindi => 'मरीज चेक-इन',
        KioskLocale.marathi => 'रुग्ण चेक-इन',
      };
  String get selectRegistrationType => switch (locale) {
        KioskLocale.english => 'Choose an option below to proceed with your OPD consultation.',
        KioskLocale.hindi => 'अपने ओपीडी परामर्श के लिए नीचे दिए गए विकल्पों में से एक चुनें।',
        KioskLocale.marathi => 'तुमच्या ओपीडी तपासणीसाठी खालीलपैकी एक पर्याय निवडा.',
      };
  String get newUserOptionTitle => switch (locale) {
        KioskLocale.english => 'New User',
        KioskLocale.hindi => 'नया उपयोगकर्ता',
        KioskLocale.marathi => 'नवीन वापरकर्ता',
      };
  String get newUserOptionSubtitle => switch (locale) {
        KioskLocale.english => 'Register for the first time',
        KioskLocale.hindi => 'पहली बार पंजीकरण करें',
        KioskLocale.marathi => 'पहिल्यांदा नोंदणी करा',
      };
  String get existingPatientOptionTitle => switch (locale) {
        KioskLocale.english => 'Existing Patient',
        KioskLocale.hindi => 'मौजूदा मरीज',
        KioskLocale.marathi => 'हयात रुग्ण',
      };
  String get existingPatientOptionSubtitle => switch (locale) {
        KioskLocale.english => 'Already registered with AAYUSATHI',
        KioskLocale.hindi => 'आयुसाथी के साथ पहले से पंजीकृत',
        KioskLocale.marathi => 'आयुसाथीमध्ये आधीच नोंदणीकृत',
      };
  String get newUserTitle => switch (locale) {
        KioskLocale.english => 'New Registration',
        KioskLocale.hindi => 'नया पंजीकरण',
        KioskLocale.marathi => 'नवीन नोंदणी',
      };
  String get newUserSubtitle => switch (locale) {
        KioskLocale.english => 'Register quickly with your 12-digit Aadhaar number.',
        KioskLocale.hindi => 'अपने 12 अंकों के आधार नंबर से तुरंत पंजीकरण करें।',
        KioskLocale.marathi => 'तुमच्या 12 अंकी आधार क्रमांकाने त्वरित नोंदणी करा.',
      };
  String get existingUserTitle => switch (locale) {
        KioskLocale.english => 'Existing Patient',
        KioskLocale.hindi => 'मौजूदा मरीज',
        KioskLocale.marathi => 'हयात रुग्ण',
      };
  String get existingUserSubtitle => switch (locale) {
        KioskLocale.english => 'Quick check-in using your AAYUSATHI Patient ID.',
        KioskLocale.hindi => 'अपने आयुष्मान पेशेंट आईडी का उपयोग करके चेक-इन करें।',
        KioskLocale.marathi => 'तुमच्या आयुष्यसाथी पेशंट आयडी वापरून चेक-इन करा.',
      };
  String get newPatientRegTitle => switch (locale) {
        KioskLocale.english => 'New Patient Registration',
        KioskLocale.hindi => 'नया मरीज पंजीकरण',
        KioskLocale.marathi => 'नवीन रुग्ण नोंदणी',
      };
  String get identityVerificationNext => switch (locale) {
        KioskLocale.english => 'Identity verification will begin next.',
        KioskLocale.hindi => 'पहचान सत्यापन आगे शुरू होगा।',
        KioskLocale.marathi => 'ओळख पडताळणी पुढे सुरू होईल.',
      };
  String get existingPatientTitle => switch (locale) {
        KioskLocale.english => 'Existing Patient',
        KioskLocale.hindi => 'मौजूदा मरीज',
        KioskLocale.marathi => 'हयात रुग्ण',
      };
  String get enterPatientIdPrompt => switch (locale) {
        KioskLocale.english => 'Enter your AAYUSATHI Patient ID to continue.',
        KioskLocale.hindi => 'जारी रखने के लिए अपनी आयुसाथी मरीज आईडी दर्ज करें।',
        KioskLocale.marathi => 'पुढे जाण्यासाठी तुमचा आयुसाथी रुग्ण आयडी प्रविष्ट करा.',
      };

  // Aadhaar & Registration Screen (Phase 5)
  String get aadhaarVerification => switch (locale) {
        KioskLocale.english => 'Aadhaar Verification',
        KioskLocale.hindi => 'आधार सत्यापन',
        KioskLocale.marathi => 'आधार पडताळणी',
      };
  String get aadhaarNumber => switch (locale) {
        KioskLocale.english => 'Aadhaar Number',
        KioskLocale.hindi => 'आधार नंबर',
        KioskLocale.marathi => 'आधार क्रमांक',
      };
  String get enterAadhaarSubtitle => switch (locale) {
        KioskLocale.english => 'Enter your Aadhaar number to verify your identity.',
        KioskLocale.hindi => 'अपनी पहचान सत्यापित करने के लिए अपना आधार नंबर दर्ज करें।',
        KioskLocale.marathi => 'आपली ओळख पडताळण्यासाठी आपला आधार क्रमांक प्रविष्ट करा.',
      };
  String get enterAadhaarPlaceholder => switch (locale) {
        KioskLocale.english => 'Enter 12-Digit Aadhaar',
        KioskLocale.hindi => '12 अंकों का आधार दर्ज करें',
        KioskLocale.marathi => '12 अंकी आधार प्रविष्ट करा',
      };
  String get aadhaarPlaceholder => 'XXXX XXXX XXXX';
  String get verifyingAadhaar => switch (locale) {
        KioskLocale.english => 'Verifying Aadhaar record...',
        KioskLocale.hindi => 'आधार रिकॉर्ड का सत्यापन किया जा रहा है...',
        KioskLocale.marathi => 'आधार नोंदीची पडताळणी केली जात आहे...',
      };
  String get lookingUpPatientId => switch (locale) {
        KioskLocale.english => 'Looking up Patient ID...',
        KioskLocale.hindi => 'मरीज आईडी खोजी जा रही है...',
        KioskLocale.marathi => 'रुग्ण आयडी शोधत आहे...',
      };
  String get verifyAndProceed => switch (locale) {
        KioskLocale.english => 'VERIFY AADHAAR',
        KioskLocale.hindi => 'आधार सत्यापित करें',
        KioskLocale.marathi => 'आधार पडताळा',
      };
  String get invalidAadhaarError => switch (locale) {
        KioskLocale.english => 'Please enter a valid 12-digit Aadhaar number.',
        KioskLocale.hindi => 'कृपया मान्य 12 अंकों का आधार नंबर दर्ज करें।',
        KioskLocale.marathi => 'कृपया वैध 12 अंकी आधार क्रमांक प्रविष्ट करा.',
      };
  String get aadhaarNotFound => switch (locale) {
        KioskLocale.english => 'Aadhaar record not found. Please check the number and try again.',
        KioskLocale.hindi => 'आधार रिकॉर्ड नहीं मिला। कृपया नंबर जांचें और पुनः प्रयास करें।',
        KioskLocale.marathi => 'आधार नोंद आढळली नाही. कृपया क्रमांक तपासा आणि पुन्हा प्रयत्न करा.',
      };

  // Duplicate Aadhaar Detection
  String get patientAlreadyRegisteredTitle => switch (locale) {
        KioskLocale.english => 'Patient Already Registered',
        KioskLocale.hindi => 'मरीज पहले से पंजीकृत है',
        KioskLocale.marathi => 'रुग्ण आधीच नोंदणीकृत आहे',
      };
  String get aadhaarAlreadyLinkedMessage => switch (locale) {
        KioskLocale.english => 'This Aadhaar number is already linked to an AAYUSATHI Patient ID.',
        KioskLocale.hindi => 'यह आधार नंबर पहले से एक आयुसाथी पेशेंट आईडी से जुड़ा है।',
        KioskLocale.marathi => 'हा आधार क्रमांक आधीच एका आयुसाथी पेशंट आयडीशी जोडलेला आहे.',
      };
  String get useExistingPatientPrompt => switch (locale) {
        KioskLocale.english => 'Please use the Existing Patient option to continue.',
        KioskLocale.hindi => 'कृपया जारी रखने के लिए मौजूदा मरीज विकल्प का उपयोग करें।',
        KioskLocale.marathi => 'कृपया पुढे जाण्यासाठी हयात रुग्ण पर्यायाचा वापर करा.',
      };
  String get goToExistingPatient => switch (locale) {
        KioskLocale.english => 'Go to Existing Patient',
        KioskLocale.hindi => 'मौजूदा मरीज पर जाएं',
        KioskLocale.marathi => 'हयात रुग्णाकडे जा',
      };
  String get backToNewUser => switch (locale) {
        KioskLocale.english => 'Back to New User',
        KioskLocale.hindi => 'नए उपयोगकर्ता पर वापस जाएं',
        KioskLocale.marathi => 'नवीन वापरकर्त्यावर परत जा',
      };
  String get verifiedAadhaarDetails => switch (locale) {
        KioskLocale.english => 'Verified Aadhaar Details',
        KioskLocale.hindi => 'सत्यापित आधार विवरण',
        KioskLocale.marathi => 'पडताळणी केलेले आधार तपशील',
      };

  // Mobile Number Registration (New User)
  String get enterMobileNumberTitle => switch (locale) {
        KioskLocale.english => 'Enter Mobile Number',
        KioskLocale.hindi => 'मोबाइल नंबर दर्ज करें',
        KioskLocale.marathi => 'मोबाइल नंबर टाका',
      };
  String get enterMobileNumberSubtitle => switch (locale) {
        KioskLocale.english => 'Enter the mobile number you want to register with AAYUSATHI.',
        KioskLocale.hindi => 'आयुसाथी के साथ पंजीकृत करने के लिए अपना मोबाइल नंबर दर्ज करें।',
        KioskLocale.marathi => 'आयुसाथीसह नोंदणी करण्यासाठी आपला मोबाइल नंबर टाका.',
      };
  String get invalidMobileNumberError => switch (locale) {
        KioskLocale.english => 'Please enter a valid 10-digit mobile number.',
        KioskLocale.hindi => 'कृपया एक मान्य 10 अंकों का मोबाइल नंबर दर्ज करें।',
        KioskLocale.marathi => 'कृपया वैध 10-अंकी मोबाइल नंबर टाका.',
      };
  String get mobileRegistrationNotice => switch (locale) {
        KioskLocale.english => 'An OTP will be sent to this mobile number for identity verification.',
        KioskLocale.hindi => 'पहचान सत्यापन के लिए इस मोबाइल नंबर पर एक ओटीपी भेजा जाएगा।',
        KioskLocale.marathi => 'ओळख पडताळणीसाठी या मोबाईल क्रमांकावर एक ओटीपी पाठविला जाईल.',
      };


  // Retrieved Patient Details Confirmation (Phase 5)
  String get pleaseConfirmDetails => switch (locale) {
        KioskLocale.english => 'Please Confirm Your Details',
        KioskLocale.hindi => 'कृपया अपने विवरण की पुष्टि करें',
        KioskLocale.marathi => 'कृपया आपल्या तपशीलांची पुष्टी करा',
      };
  String get confirmDetailsSubtitle => switch (locale) {
        KioskLocale.english => 'The following identity details were retrieved from your Aadhaar record.',
        KioskLocale.hindi => 'निम्नलिखित पहचान विवरण आपके आधार रिकॉर्ड से प्राप्त किए गए हैं।',
        KioskLocale.marathi => 'खालील ओळख तपशील आपल्या आधार नोंदीतून प्राप्त केले गेले आहेत.',
      };
  String get readOnlyNotice => switch (locale) {
        KioskLocale.english => 'Verified identity data cannot be edited directly at the kiosk.',
        KioskLocale.hindi => 'सत्यापित पहचान डेटा को कियोस्क पर सीधे संपादित नहीं किया जा सकता है।',
        KioskLocale.marathi => 'पडताळलेला ओळख डेटा थेट कियोस्कवर संपादित केला जाऊ शकत नाही.',
      };
  String get confirmDetails => switch (locale) {
        KioskLocale.english => 'CONFIRM DETAILS',
        KioskLocale.hindi => 'विवरण की पुष्टि करें',
        KioskLocale.marathi => 'तपशीलांची पुष्टी करा',
      };
  String get confirmIdentity => switch (locale) {
        KioskLocale.english => 'CONFIRM IDENTITY',
        KioskLocale.hindi => 'पहचान की पुष्टि करें',
        KioskLocale.marathi => 'ओळखीची पुष्टी करा',
      };
  String get goBack => switch (locale) {
        KioskLocale.english => 'GO BACK',
        KioskLocale.hindi => 'वापस जाएं',
        KioskLocale.marathi => 'मागे जा',
      };

  // Patient ID Generation & Success (Phase 5)
  String get registrationSuccessful => switch (locale) {
        KioskLocale.english => 'Registration Successful',
        KioskLocale.hindi => 'पंजीकरण सफल हुआ',
        KioskLocale.marathi => 'नोंदणी यशस्वी झाली',
      };
  String get registrationSuccessSubtitle => switch (locale) {
        KioskLocale.english => 'Your hospital OPD registration has been created successfully.',
        KioskLocale.hindi => 'आपका अस्पताल ओपीडी पंजीकरण सफलतापूर्वक बन गया है।',
        KioskLocale.marathi => 'आपली रुग्णालय ओपीडी नोंदणी यशस्वीरीत्या तयार झाली आहे.',
      };
  String get yourPatientId => switch (locale) {
        KioskLocale.english => 'Your AAYUSATHI Patient ID',
        KioskLocale.hindi => 'आपकी आयुसाथी मरीज आईडी',
        KioskLocale.marathi => 'आपला आयुसाथी रुग्ण आयडी',
      };
  String get pleaseKeepIdSafe => switch (locale) {
        KioskLocale.english => 'Please keep this ID safe for all future visits and consultations.',
        KioskLocale.hindi => 'कृपया भविष्य के सभी दौरों और परामर्शों के लिए इस आईडी को सुरक्षित रखें।',
        KioskLocale.marathi => 'कृपया पुढील सर्व भेटी आणि तपासणीसाठी हा आयडी सुरक्षित ठेवा.',
      };

  // Existing Patient Workflow (Phase 5)
  String get enterYourPatientId => switch (locale) {
        KioskLocale.english => 'Enter Your AAYUSATHI Patient ID',
        KioskLocale.hindi => 'अपनी आयुसाथी मरीज आईडी दर्ज करें',
        KioskLocale.marathi => 'आपला आयुसाथी रुग्ण आयडी प्रविष्ट करा',
      };
  String get enterPatientIdSubtitle => switch (locale) {
        KioskLocale.english => 'Enter the 6 digits of your ID format: AAYU-XXXXXX',
        KioskLocale.hindi => 'अपनी आईडी के 6 अंक दर्ज करें: AAYU-XXXXXX',
        KioskLocale.marathi => 'आपल्या आयडीचे 6 अंक प्रविष्ट करा: AAYU-XXXXXX',
      };
  String get patientIdNotFound => switch (locale) {
        KioskLocale.english => 'Patient ID not found. Please check your ID and try again.',
        KioskLocale.hindi => 'मरीज आईडी नहीं मिली। कृपया अपनी आईडी जांचें और पुनः प्रयास करें।',
        KioskLocale.marathi => 'रुग्ण आयडी आढळला नाही. कृपया आपला आयडी तपासा आणि पुन्हा प्रयत्न करा.',
      };
  String get invalidPatientId => switch (locale) {
        KioskLocale.english => 'Please enter all 6 digits of your Patient ID.',
        KioskLocale.hindi => 'कृपया अपनी मरीज आईडी के सभी 6 अंक दर्ज करें।',
        KioskLocale.marathi => 'कृपया आपल्या रुग्ण आयडीचे सर्व 6 अंक प्रविष्ट करा.',
      };

  // Keypad Actions
  String get clear => switch (locale) {
        KioskLocale.english => 'CLEAR',
        KioskLocale.hindi => 'साफ़ करें',
        KioskLocale.marathi => 'साफ करा',
      };
  String get delete => switch (locale) {
        KioskLocale.english => 'DEL',
        KioskLocale.hindi => 'हटाएं',
        KioskLocale.marathi => 'हटवा',
      };

  // Phase 5 Completion Milestone
  String get phase5MilestoneTitle => switch (locale) {
        KioskLocale.english => 'Patient Identity Verified',
        KioskLocale.hindi => 'मरीज की पहचान सत्यापित',
        KioskLocale.marathi => 'रुग्णाची ओळख पडताळली',
      };
  String get phase5MilestoneSubtitle => switch (locale) {
        KioskLocale.english => 'Identification completed successfully. Ready to proceed to Vitals Collection (Phase 6).',
        KioskLocale.hindi => 'पहचान सफलतापूर्वक पूरी हुई। वाइटल्स संग्रह (चरण 6) पर आगे बढ़ने के लिए तैयार।',
        KioskLocale.marathi => 'ओळख यशस्वीरीत्या पूर्ण झाली. वाइटल्स तपासणीसाठी (टप्पा 6) पुढे जाण्यासाठी सज्ज.',
      };

  // OTP Verification Screen (Phase 6)
  String get verifyMobileNumber => switch (locale) {
        KioskLocale.english => 'Verify Your Mobile Number',
        KioskLocale.hindi => 'अपना मोबाइल नंबर सत्यापित करें',
        KioskLocale.marathi => 'आपला मोबाईल क्रमांक पडताळा',
      };
  String get enterOtpSubtitle => switch (locale) {
        KioskLocale.english => 'Enter the 6-digit OTP sent to your registered mobile number.',
        KioskLocale.hindi => 'अपने पंजीकृत मोबाइल नंबर पर भेजा गया 6 अंकों का ओटीपी दर्ज करें।',
        KioskLocale.marathi => 'आपल्या नोंदणीकृत मोबाईल क्रमांकावर पाठवलेला 6 अंकी ओटीपी प्रविष्ट करा.',
      };
  String get otpSentToRegistered => switch (locale) {
        KioskLocale.english => 'OTP sent to registered mobile number',
        KioskLocale.hindi => 'पंजीकृत मोबाइल नंबर पर ओटीपी भेजा गया',
        KioskLocale.marathi => 'नोंदणीकृत मोबाईल क्रमांकावर ओटीपी पाठवला',
      };
  String otpSentTo(String phone) => switch (locale) {
        KioskLocale.english => 'Enter the 6-digit OTP sent to $phone',
        KioskLocale.hindi => '$phone पर भेजे गए 6 अंकों का ओटीपी दर्ज करें',
        KioskLocale.marathi => '$phone वर पाठवलेला 6 अंकी ओटीपी प्रविष्ट करा',
      };
  String get verifyOtp => switch (locale) {
        KioskLocale.english => 'VERIFY OTP',
        KioskLocale.hindi => 'ओटीपी सत्यापित करें',
        KioskLocale.marathi => 'ओटीपी पडताळा',
      };
  String get verifyingOtp => switch (locale) {
        KioskLocale.english => 'Verifying OTP...',
        KioskLocale.hindi => 'ओटीपी सत्यापित किया जा रहा है...',
        KioskLocale.marathi => 'ओटीपी पडताळणी सुरू आहे...',
      };
  String get incorrectOtp => switch (locale) {
        KioskLocale.english => 'Incorrect OTP. Please check and try again.',
        KioskLocale.hindi => 'गलत ओटीपी। कृपया जांचें और पुनः प्रयास करें।',
        KioskLocale.marathi => 'चुकीचा ओटीपी. कृपया तपासून पुन्हा प्रयत्न करा.',
      };
  String get invalidOtp => switch (locale) {
        KioskLocale.english => 'Please enter all 6 digits of the OTP.',
        KioskLocale.hindi => 'कृपया ओटीपी के सभी 6 अंक दर्ज करें।',
        KioskLocale.marathi => 'कृपया ओटीपीचे सर्व 6 अंक प्रविष्ट करा.',
      };
  String get tooManyAttempts => switch (locale) {
        KioskLocale.english => 'Too many incorrect attempts. For security, your session must be restarted.',
        KioskLocale.hindi => 'अत्यधिक गलत प्रयास। सुरक्षा कारणों से आपका सत्र पुनः आरंभ किया जाएगा।',
        KioskLocale.marathi => 'खूप जास्त चुकीचे प्रयत्न. सुरक्षेसाठी आपले सत्र पुन्हा सुरू केले जाईल.',
      };
  String get startAgain => switch (locale) {
        KioskLocale.english => 'START AGAIN',
        KioskLocale.hindi => 'पुनः आरंभ करें',
        KioskLocale.marathi => 'पुन्हा सुरू करा',
      };
  String get sendOtp => switch (locale) {
        KioskLocale.english => 'SEND OTP',
        KioskLocale.hindi => 'ओटीपी भेजें',
        KioskLocale.marathi => 'ओटीपी पाठवा',
      };
  String get resendOtp => switch (locale) {
        KioskLocale.english => 'RESEND OTP',
        KioskLocale.hindi => 'ओटीपी पुनः भेजें',
        KioskLocale.marathi => 'ओटीपी पुन्हा पाठवा',
      };
  String resendOtpIn(int seconds) => switch (locale) {
        KioskLocale.english => 'Resend OTP in ${seconds}s',
        KioskLocale.hindi => '$seconds सेकंड में पुनः भेजें',
        KioskLocale.marathi => '$seconds सेकंदात पुन्हा पाठवा',
      };
  String get newOtpSent => switch (locale) {
        KioskLocale.english => 'New OTP sent successfully.',
        KioskLocale.hindi => 'नया ओटीपी सफलतापूर्वक भेजा गया।',
        KioskLocale.marathi => 'नवीन ओटीपी यशस्वीरीत्या पाठवला गेला.',
      };
  String attemptsRemaining(int count) => switch (locale) {
        KioskLocale.english => '$count ${count == 1 ? 'attempt' : 'attempts'} remaining',
        KioskLocale.hindi => '$count प्रयास शेष हैं',
        KioskLocale.marathi => '$count प्रयत्न शिल्लक आहेत',
      };
  String get mobileNumberVerified => switch (locale) {
        KioskLocale.english => 'Mobile Number Verified',
        KioskLocale.hindi => 'मोबाइल नंबर सत्यापित हुआ',
        KioskLocale.marathi => 'मोबाईल क्रमांक पडताळला गेला',
      };
  String get identitySuccessfullyVerified => switch (locale) {
        KioskLocale.english => 'Your identity has been successfully verified.',
        KioskLocale.hindi => 'आपकी पहचान सफलतापूर्वक सत्यापित हो गई है।',
        KioskLocale.marathi => 'आपली ओळख यशस्वीरीत्या पडताळली गेली आहे.',
      };
  String get patientIdLabel => switch (locale) {
        KioskLocale.english => 'Patient ID',
        KioskLocale.hindi => 'मरीज आईडी',
        KioskLocale.marathi => 'रुग्ण आयडी',
      };
  String get phoneNumber => switch (locale) {
        KioskLocale.english => 'Phone Number',
        KioskLocale.hindi => 'फ़ोन नंबर',
        KioskLocale.marathi => 'फोन नंबर',
      };
  String get continueButton => continueText;
  String get phase6MilestoneTitle => switch (locale) {
        KioskLocale.english => 'OTP Verification Complete',
        KioskLocale.hindi => 'ओटीपी सत्यापन पूर्ण हुआ',
        KioskLocale.marathi => 'ओटीपी पडताळणी पूर्ण झाली',
      };
  String get phase6MilestoneSubtitle => switch (locale) {
        KioskLocale.english => 'Patient phone authenticated. Ready to proceed to Vitals Collection (Phase 7).',
        KioskLocale.hindi => 'मरीज का फोन प्रमाणित हुआ। वाइटल्स संग्रह (चरण 7) पर आगे बढ़ने के लिए तैयार।',
        KioskLocale.marathi => 'रुग्णाचा फोन प्रमाणित झाला. वाइटल्स तपासणीसाठी (टप्पा 7) पुढे जाण्यास सज्ज.',
      };

  // Phase 6.5 OTP Hardening
  String get invalidSessionError => switch (locale) {
        KioskLocale.english => 'No active patient session found. Please begin check-in from Standby.',
        KioskLocale.hindi => 'कोई सक्रिय मरीज सत्र नहीं मिला। कृपया स्टैंडबाय से चेक-इन प्रारंभ करें।',
        KioskLocale.marathi => 'कोणतेही सक्रिय रुग्ण सत्र आढळले नाही. कृपया स्टँडबाय वरून चेक-इन सुरू करा.',
      };
  String get otpAlreadyVerified => switch (locale) {
        KioskLocale.english => 'Mobile number already verified.',
        KioskLocale.hindi => 'मोबाइल नंबर पहले से सत्यापित है।',
        KioskLocale.marathi => 'मोबाईल क्रमांक आधीच पडताळला गेला आहे.',
      };
  String get processingRequest => switch (locale) {
        KioskLocale.english => 'Processing request, please wait...',
        KioskLocale.hindi => 'अनुरोध संसाधित किया जा रहा है, कृपया प्रतीक्षा करें...',
        KioskLocale.marathi => 'प्रक्रिया सुरू आहे, कृपया थांबा...',
      };

  // Phase 7 Vitals Collection
  String get vitalsCollectionTitle => switch (locale) {
        KioskLocale.english => 'Patient Vitals Collection',
        KioskLocale.hindi => 'मरीज वाइटल्स संग्रह',
        KioskLocale.marathi => 'रुग्ण वाइटल्स तपासणी',
      };
  String get vitalsCollectionSubtitle => switch (locale) {
        KioskLocale.english => 'Live clinical reading from AAYUSATHI sensor terminal',
        KioskLocale.hindi => 'आयुसाथी सेंसर टर्मिनल से लाइव नैदानिक माप',
        KioskLocale.marathi => 'आयुसाथी सेन्सर टर्मिनलवरून थेट वैद्यकीय तपासणी',
      };
  String get heartRate => switch (locale) {
        KioskLocale.english => 'Heart Rate',
        KioskLocale.hindi => 'हृदय गति (Heart Rate)',
        KioskLocale.marathi => 'हृदयाचे ठोके (Heart Rate)',
      };
  String get bloodOxygen => switch (locale) {
        KioskLocale.english => 'Blood Oxygen (SpO₂)',
        KioskLocale.hindi => 'रक्त ऑक्सीजन (SpO₂)',
        KioskLocale.marathi => 'रक्तातील ऑक्सिजन (SpO₂)',
      };
  String get bodyTemperature => switch (locale) {
        KioskLocale.english => 'Body Temperature',
        KioskLocale.hindi => 'शरीर का तापमान',
        KioskLocale.marathi => 'शरीराचे तापमान',
      };
  String get waitingForSensor => switch (locale) {
        KioskLocale.english => 'Waiting for sensor...',
        KioskLocale.hindi => 'सेंसर की प्रतीक्षा है...',
        KioskLocale.marathi => 'सेन्सरची प्रतीक्षा करत आहे...',
      };
  String get readingInProgress => switch (locale) {
        KioskLocale.english => 'Reading in progress...',
        KioskLocale.hindi => 'माप प्रगति पर है...',
        KioskLocale.marathi => 'तपासणी सुरू आहे...',
      };
  String get sensorComplete => switch (locale) {
        KioskLocale.english => 'Reading complete',
        KioskLocale.hindi => 'माप पूर्ण हुआ',
        KioskLocale.marathi => 'तपासणी पूर्ण झाली',
      };
  String get sensorUnavailable => switch (locale) {
        KioskLocale.english => 'Sensor unavailable',
        KioskLocale.hindi => 'सेंसर अनुपलब्ध है',
        KioskLocale.marathi => 'सेन्सर उपलब्ध नाही',
      };

  // Sensor Instructions & Hardware Trigger
  String get sensorInstructionsTitle => switch (locale) {
        KioskLocale.english => 'Sensor Instructions',
        KioskLocale.hindi => 'सेंसर निर्देश',
        KioskLocale.marathi => 'सेन्सर सूचना',
      };
  String get sensorInstructionsSubtitle => switch (locale) {
        KioskLocale.english => 'Please follow these simple steps to measure your vitals',
        KioskLocale.hindi => 'कृपया अपने वाइटल्स मापने के लिए इन सरल चरणों का पालन करें',
        KioskLocale.marathi => 'कृपया तुमचे वाइटल्स तपासण्यासाठी या सोप्या पायऱ्यांचे अनुसरण करा',
      };
  String get step1Title => switch (locale) {
        KioskLocale.english => 'Step 1 — Blood Oxygen & Heart Rate',
        KioskLocale.hindi => 'चरण 1 — रक्त ऑक्सीजन और हृदय गति',
        KioskLocale.marathi => 'पायरी 1 — रक्तातील ऑक्सिजन आणि हृदयाचे ठोके',
      };
  String get step1Instruction => switch (locale) {
        KioskLocale.english => 'Place your finger gently inside the designated sensor.',
        KioskLocale.hindi => 'अपनी उंगली को धीरे से निर्दिष्ट सेंसर के अंदर रखें।',
        KioskLocale.marathi => 'आपले बोट हळुवारपणे नियुक्त केलेल्या सेन्सरच्या आत ठेवा.',
      };
  String get step1SubInstruction => switch (locale) {
        KioskLocale.english => 'Keep your finger completely still while measurements are taken.',
        KioskLocale.hindi => 'माप लेते समय अपनी उंगली को बिल्कुल स्थिर रखें।',
        KioskLocale.marathi => 'तपासणी सुरू असताना आपले बोट पूर्णपणे स्थिर ठेवा.',
      };
  String get step2Title => switch (locale) {
        KioskLocale.english => 'Step 2 — Body Temperature',
        KioskLocale.hindi => 'चरण 2 — शरीर का तापमान',
        KioskLocale.marathi => 'पायरी 2 — शरीराचे तापमान',
      };
  String get step2Instruction => switch (locale) {
        KioskLocale.english => "Remove the temperature sensor carefully and place it at the designated measurement position near your elbow, following the sensor's instructions.",
        KioskLocale.hindi => 'तापमान सेंसर को सावधानी से निकालें और सेंसर के निर्देशों का पालन करते हुए अपनी कोहनी के पास निर्दिष्ट माप स्थान पर रखें।',
        KioskLocale.marathi => 'तापमान सेन्सर काळजीपूर्वक काढा आणि सेन्सरच्या सूचनांचे पालन करून आपल्या कोपराजवळ नियुक्त केलेल्या मापन स्थितीवर ठेवा.',
      };
  String get step2SubInstruction => switch (locale) {
        KioskLocale.english => 'Hold the sensor in place until the measurement beep or signal.',
        KioskLocale.hindi => 'माप पूरा होने तक सेंसर को उसी स्थान पर धीरे से बनाए रखें।',
        KioskLocale.marathi => 'तपासणी पूर्ण होईपर्यंत सेन्सर त्याच ठिकाणी हळूच धरून ठेवा.',
      };
  String get step3Title => switch (locale) {
        KioskLocale.english => 'Step 3 — Start Measurement',
        KioskLocale.hindi => 'चरण 3 — माप शुरू करें',
        KioskLocale.marathi => 'पायरी 3 — तपासणी सुरू करा',
      };
  String get step3Instruction => switch (locale) {
        KioskLocale.english => 'When you are ready, press TAKE VITALS.',
        KioskLocale.hindi => 'जब आप तैयार हों, तब वाइटल्स लें (TAKE VITALS) बटन दबाएं।',
        KioskLocale.marathi => 'तुम्ही तयार असाल तेव्हा वाइटल्स घ्या (TAKE VITALS) बटण दाबा.',
      };
  String get takeVitals => switch (locale) {
        KioskLocale.english => 'TAKE VITALS',
        KioskLocale.hindi => 'वाइटल्स लें',
        KioskLocale.marathi => 'वाइटल्स घ्या',
      };
  String get retakeVitals => switch (locale) {
        KioskLocale.english => 'RETAKE VITALS',
        KioskLocale.hindi => 'वाइटल्स पुनः लें',
        KioskLocale.marathi => 'वाइटल्स पुन्हा घ्या',
      };
  String get takingMeasurements => switch (locale) {
        KioskLocale.english => 'Taking your measurements…',
        KioskLocale.hindi => 'आपके माप लिए जा रहे हैं…',
        KioskLocale.marathi => 'तुमची तपासणी घेतली जात आहे…',
      };
  String get collectingMeasurements => switch (locale) {
        KioskLocale.english => 'Collecting measurements…',
        KioskLocale.hindi => 'माप एकत्र किए जा रहे हैं…',
        KioskLocale.marathi => 'मापे गोळा केली जात आहेत…',
      };
  String get hardwareTimeoutMessage => switch (locale) {
        KioskLocale.english => 'Hardware readings unavailable. Demo values are being displayed.',
        KioskLocale.hindi => 'हार्डवेयर माप अनुपलब्ध हैं। डेमो मान प्रदर्शित किए जा रहे हैं।',
        KioskLocale.marathi => 'हार्डवेअर तपासणी उपलब्ध नाही. डेमो मूल्ये प्रदर्शित केली जात आहेत.',
      };
  String get simulatedHardwareTimeout => switch (locale) {
        KioskLocale.english => 'SIMULATED — HARDWARE TIMEOUT',
        KioskLocale.hindi => 'सिम्युलेटेड — हार्डवेयर टाइमआउट',
        KioskLocale.marathi => 'सिम्युलेटेड — हार्डवेअर टाइमआउट',
      };
  String get arduinoHardware => switch (locale) {
        KioskLocale.english => 'ARDUINO HARDWARE',
        KioskLocale.hindi => 'आर्डुइनो हार्डवेयर',
        KioskLocale.marathi => 'आर्डुइनो हार्डवेअर',
      };
  String get simulatedNormal => switch (locale) {
        KioskLocale.english => 'SIMULATED NORMAL',
        KioskLocale.hindi => 'सिम्युलेटेड सामान्य',
        KioskLocale.marathi => 'सिम्युलेटेड सामान्य',
      };
  String get simulatedAbnormal => switch (locale) {
        KioskLocale.english => 'SIMULATED ABNORMAL',
        KioskLocale.hindi => 'सिम्युलेटेड असामान्य',
        KioskLocale.marathi => 'सिम्युलेटेड असामान्य',
      };
  String get sourceArduino => switch (locale) {
        KioskLocale.english => 'Source: ARDUINO',
        KioskLocale.hindi => 'स्रोत: आर्डुइनो',
        KioskLocale.marathi => 'स्रोत: आर्डुइनो',
      };
  String get sourceSimulated => switch (locale) {
        KioskLocale.english => 'Source: SIMULATED',
        KioskLocale.hindi => 'स्रोत: सिम्युलेटेड',
        KioskLocale.marathi => 'स्रोत: सिम्युलेटेड',
      };
  String get validateVitals => switch (locale) {
        KioskLocale.english => 'VALIDATE VITALS',
        KioskLocale.hindi => 'वाइटल्स सत्यापित करें',
        KioskLocale.marathi => 'वाइटल्स तपासा',
      };
  String get validatingVitals => switch (locale) {
        KioskLocale.english => 'Validating vitals...',
        KioskLocale.hindi => 'वाइटल्स सत्यापित किए जा रहे हैं...',
        KioskLocale.marathi => 'वाइटल्स पडताळले जात आहेत...',
      };
  String get vitalsNormalTitle => switch (locale) {
        KioskLocale.english => 'Vitals Within Normal Range',
        KioskLocale.hindi => 'वाइटल्स सामान्य सीमा के भीतर हैं',
        KioskLocale.marathi => 'वाइटल्स सामान्य मर्यादेत आहेत',
      };
  String get vitalsNormalSubtitle => switch (locale) {
        KioskLocale.english => 'All vital parameters are stable. You may proceed to OPD Domain Selection.',
        KioskLocale.hindi => 'सभी महत्वपूर्ण पैरामीटर स्थिर हैं। आप ओपीडी डोमेन चयन पर आगे बढ़ सकते हैं।',
        KioskLocale.marathi => 'सर्व महत्त्वाचे पॅरामीटर्स स्थिर आहेत. आपण ओपीडी विभाग निवडीसाठी पुढे जाऊ शकता.',
      };
  String get proceedToDomainSelection => switch (locale) {
        KioskLocale.english => 'PROCEED TO DOMAIN SELECTION',
        KioskLocale.hindi => 'डोमेन चयन पर आगे बढ़ें',
        KioskLocale.marathi => 'विभाग निवडीकडे पुढे जा',
      };
  String get ipdReferralTitle => switch (locale) {
        KioskLocale.english => 'Please Visit IPD Department',
        KioskLocale.hindi => 'कृपया आईपीडी विभाग में संपर्क करें',
        KioskLocale.marathi => 'कृपया आयपीडी विभागात भेट द्या',
      };
  String get ipdReferralMessage => switch (locale) {
        KioskLocale.english => 'Please visit the IPD department.',
        KioskLocale.hindi => 'कृपया आईपीडी विभाग में संपर्क करें।',
        KioskLocale.marathi => 'कृपया आयपीडी विभागात भेट द्या.',
      };
  String get ipdReferralNotice => switch (locale) {
        KioskLocale.english => 'One or more of your vital signs are outside standard outpatient limits. For your safety and immediate clinical evaluation, please consult the hospital IPD desk immediately.',
        KioskLocale.hindi => 'आपके एक या अधिक वाइटल्स सामान्य ओपीडी सीमा से बाहर हैं। आपकी सुरक्षा और तत्काल जांच के लिए, कृपया अस्पताल के आईपीडी डेस्क पर तुरंत संपर्क करें।',
        KioskLocale.marathi => 'आपले एक किंवा अधिक वाइटल्स सामान्य मर्यादेबाहेर आहेत. आपल्या सुरक्षेसाठी आणि त्वरित तपासणीसाठी, कृपया रुग्णालयाच्या आयपीडी कक्षाशी तात्काळ संपर्क साधा.',
      };
  String get finishSession => switch (locale) {
        KioskLocale.english => 'FINISH SESSION',
        KioskLocale.hindi => 'सत्र समाप्त करें',
        KioskLocale.marathi => 'सत्र पूर्ण करा',
      };
  String get domainSelectionTitle => switch (locale) {
        KioskLocale.english => 'Select Medical Department',
        KioskLocale.hindi => 'चिकित्सा विभाग चुनें',
        KioskLocale.marathi => 'वैद्यकीय विभाग निवडा',
      };
  String get domainSelectionSubtitle => switch (locale) {
        KioskLocale.english => 'Choose the department most appropriate for your current health concern.',
        KioskLocale.hindi => 'अपनी वर्तमान स्वास्थ्य समस्या के लिए उपयुक्त विभाग चुनें।',
        KioskLocale.marathi => 'तुमच्या सध्याच्या आरोग्य समस्येसाठी योग्य विभाग निवडा.',
      };

  // Patient Details Screen (Read-Only)
  String get identityVerified => switch (locale) {
        KioskLocale.english => 'IDENTITY VERIFIED',
        KioskLocale.hindi => 'पहचान सत्यापित हुई',
        KioskLocale.marathi => 'ओळख पडताळली गेली',
      };
  String get patientDetailsNote => switch (locale) {
        KioskLocale.english => 'Please review your registered details below before generating your OPD card.',
        KioskLocale.hindi => 'अपना ओपीडी कार्ड जनरेट करने से पहले कृपया अपने विवरण की समीक्षा करें।',
        KioskLocale.marathi => 'तुमचे ओपीडी कार्ड तयार करण्यापूर्वी खालील तपशील तपासा.',
      };
  String get fullName => switch (locale) {
        KioskLocale.english => 'Full Name',
        KioskLocale.hindi => 'पूरा नाम',
        KioskLocale.marathi => 'पूर्ण नाव',
      };
  String get dob => switch (locale) {
        KioskLocale.english => 'Date of Birth / Age',
        KioskLocale.hindi => 'जन्म तिथि / आयु',
        KioskLocale.marathi => 'जन्मतारीख / वय',
      };
  String get gender => switch (locale) {
        KioskLocale.english => 'Gender',
        KioskLocale.hindi => 'लिंग',
        KioskLocale.marathi => 'लिंग',
      };
  String get bloodGroup => switch (locale) {
        KioskLocale.english => 'Blood Group',
        KioskLocale.hindi => 'रक्त समूह',
        KioskLocale.marathi => 'रक्तगट',
      };
  String get mobileNumber => switch (locale) {
        KioskLocale.english => 'Mobile Number',
        KioskLocale.hindi => 'मोबाइल नंबर',
        KioskLocale.marathi => 'मोबाईल नंबर',
      };
  String get address => switch (locale) {
        KioskLocale.english => 'Residential Address',
        KioskLocale.hindi => 'निवास का पता',
        KioskLocale.marathi => 'राहण्याचा पत्ता',
      };
  String get patientId => switch (locale) {
        KioskLocale.english => 'AAYUSATHI Patient ID',
        KioskLocale.hindi => 'आयुष्मान पेशेंट आईडी',
        KioskLocale.marathi => 'आयुष्यसाथी पेशंट आयडी',
      };
  String get confirmAndContinue => switch (locale) {
        KioskLocale.english => 'CONFIRM & CONTINUE TO VITALS',
        KioskLocale.hindi => 'पुष्टि करें और वाइटल्स पर जाएं',
        KioskLocale.marathi => 'निश्चित करा आणि वाइटल्सकडे जा',
      };

  // Vitals Screen
  String get vitalsCollection => switch (locale) {
        KioskLocale.english => 'Vital Signs Collection',
        KioskLocale.hindi => 'महत्वपूर्ण स्वास्थ्य मापदंड',
        KioskLocale.marathi => 'महत्त्वाचे आरोग्य मापदंड',
      };
  String get sensorInstruction => switch (locale) {
        KioskLocale.english => 'Place your finger on the pulse oximeter sensor and keep still.',
        KioskLocale.hindi => 'पल्स ऑक्सीमीटर सेंसर पर अपनी उंगली रखें और स्थिर रहें।',
        KioskLocale.marathi => 'पल्स ऑक्सिमीटर सेन्सरवर आपले बोट ठेवा आणि शांत राहा.',
      };
  String get oxygenLevel => switch (locale) {
        KioskLocale.english => 'Oxygen Level (SpO₂)',
        KioskLocale.hindi => 'ऑक्सीजन स्तर (SpO₂)',
        KioskLocale.marathi => 'ऑक्सिजन पातळी (SpO₂)',
      };
  String get bodyTemp => switch (locale) {
        KioskLocale.english => 'Body Temperature',
        KioskLocale.hindi => 'शरीर का तापमान',
        KioskLocale.marathi => 'शरीराचे तापमान',
      };

  // Vital Validation / IPD Alert
  String get visitIpdAlertTitle => switch (locale) {
        KioskLocale.english => 'CRITICAL MEDICAL ATTENTION REQUIRED',
        KioskLocale.hindi => 'तत्काल चिकित्सा ध्यान आवश्यक है',
        KioskLocale.marathi => 'तातडीच्या वैद्यकीय मदतीची गरज आहे',
      };
  String get visitIpdAlertMessage => switch (locale) {
        KioskLocale.english => 'Please visit the IPD department immediately.',
        KioskLocale.hindi => 'कृपया तुरंत आईपीडी (IPD) विभाग में जाएं।',
        KioskLocale.marathi => 'कृपया त्वरित आयपीडी (IPD) विभागात जा.',
      };
  String get ipdInstruction => switch (locale) {
        KioskLocale.english => 'Your measured vital readings indicate that you require immediate direct medical evaluation. Our staff has been alerted.',
        KioskLocale.hindi => 'आपके वाइटल्स दर्शाते हैं कि आपको तत्काल चिकित्सकीय देखभाल की आवश्यकता है। हमारे स्टाफ को सूचित कर दिया गया है।',
        KioskLocale.marathi => 'तुमचे मोजलेले वाइटल्स दर्शवतात की तुम्हाला तातडीने प्रत्यक्ष तपासणीची गरज आहे. आमच्या कर्मचाऱ्यांना सतर्क करण्यात आले आहे.',
      };
  String get vitalsNormalProceed => switch (locale) {
        KioskLocale.english => 'CONTINUE TO DEPARTMENT SELECTION',
        KioskLocale.hindi => 'विभाग चयन के लिए आगे बढ़ें',
        KioskLocale.marathi => 'विभाग निवडीसाठी पुढे जा',
      };

  // Department Selection Screen
  String get selectDepartmentTitle => switch (locale) {
        KioskLocale.english => 'Select Medical Department',
        KioskLocale.hindi => 'चिकित्सा विभाग चुनें',
        KioskLocale.marathi => 'वैद्यकीय विभाग निवडा',
      };
  String get selectDepartmentSubtitle => switch (locale) {
        KioskLocale.english => 'Choose the department most appropriate for your current health concern.',
        KioskLocale.hindi => 'अपनी वर्तमान स्वास्थ्य समस्या के लिए उपयुक्त विभाग चुनें।',
        KioskLocale.marathi => 'तुमच्या सध्याच्या आरोग्य समस्येसाठी योग्य विभाग निवडा.',
      };

  // 8 OPD Clinical Domains
  String get cardiologyTitle => switch (locale) {
        KioskLocale.english => 'Cardiology',
        KioskLocale.hindi => 'हृदय रोग (Cardiology)',
        KioskLocale.marathi => 'हृदयरोगशास्त्र (Cardiology)',
      };
  String get cardiologyDesc => switch (locale) {
        KioskLocale.english => 'Heart and cardiovascular-related consultation',
        KioskLocale.hindi => 'हृदय और रक्तसंचार से संबंधित परामर्श',
        KioskLocale.marathi => 'हृदय आणि रक्तवाहिन्यांसंबंधी तपासणी व सल्ला',
      };

  String get neurologyTitle => switch (locale) {
        KioskLocale.english => 'Neurology',
        KioskLocale.hindi => 'न्यूरोलॉजी (Neurology)',
        KioskLocale.marathi => 'मेंदू व मज्जासंस्था (Neurology)',
      };
  String get neurologyDesc => switch (locale) {
        KioskLocale.english => 'Brain, nerves and nervous-system related consultation',
        KioskLocale.hindi => 'मस्तिष्क, नसों और तंत्रिका तंत्र से संबंधित परामर्श',
        KioskLocale.marathi => 'मेंदू, मज्जातंतू आणि मज्जासंस्थेसंबंधी तपासणी व सल्ला',
      };

  String get gastroenterologyTitle => switch (locale) {
        KioskLocale.english => 'Gastroenterology',
        KioskLocale.hindi => 'गैस्ट्रोएंटरोलॉजी (Gastroenterology)',
        KioskLocale.marathi => 'पचनसंस्थाशास्त्र (Gastroenterology)',
      };
  String get gastroenterologyDesc => switch (locale) {
        KioskLocale.english => 'Digestive system and gastrointestinal consultation',
        KioskLocale.hindi => 'पाचन तंत्र और पेट से संबंधित परामर्श',
        KioskLocale.marathi => 'पचनसंस्था आणि पोटाच्या तक्रारींसंबंधी तपासणी व सल्ला',
      };

  String get orthopedicsTitle => switch (locale) {
        KioskLocale.english => 'Orthopedics',
        KioskLocale.hindi => 'ऑर्थोपेडिक्स (Orthopedics)',
        KioskLocale.marathi => 'अस्थिरोगशास्त्र (Orthopedics)',
      };
  String get orthopedicsDesc => switch (locale) {
        KioskLocale.english => 'Bones, joints, muscles and movement-related consultation',
        KioskLocale.hindi => 'हड्डियों, जोड़ों, मांसपेशियों और गति से संबंधित परामर्श',
        KioskLocale.marathi => 'हाडे, सांधे, स्नायू आणि हालचालींसंबंधी तपासणी व सल्ला',
      };

  String get pediatricsTitle => switch (locale) {
        KioskLocale.english => 'Pediatrics',
        KioskLocale.hindi => 'बाल रोग (Pediatrics)',
        KioskLocale.marathi => 'बालरोगशास्त्र (Pediatrics)',
      };
  String get pediatricsDesc => switch (locale) {
        KioskLocale.english => 'Medical care for infants, children and adolescents',
        KioskLocale.hindi => 'शिशुओं, बच्चों और किशोरों के लिए चिकित्सा देखभाल',
        KioskLocale.marathi => 'अर्भके, मुले आणि किशोरवयीनांसाठी वैद्यकीय काळजी',
      };

  String get entTitle => switch (locale) {
        KioskLocale.english => 'ENT',
        KioskLocale.hindi => 'ईएनटी (ENT - कान, नाक, गला)',
        KioskLocale.marathi => 'कान, नाक आणि घसा (ENT)',
      };
  String get entDesc => switch (locale) {
        KioskLocale.english => 'Ear, nose and throat related consultation',
        KioskLocale.hindi => 'कान, नाक और गले से संबंधित परामर्श',
        KioskLocale.marathi => 'कान, नाक आणि घशाशी संबंधित तपासणी व सल्ला',
      };

  String get dermatologyTitle => switch (locale) {
        KioskLocale.english => 'Dermatology',
        KioskLocale.hindi => 'त्वचा रोग (Dermatology)',
        KioskLocale.marathi => 'त्वचारोगशास्त्र (Dermatology)',
      };
  String get dermatologyDesc => switch (locale) {
        KioskLocale.english => 'Skin, hair and nail related consultation',
        KioskLocale.hindi => 'त्वचा, बाल और नाखूनों से संबंधित परामर्श',
        KioskLocale.marathi => 'त्वचा, केस आणि नखांसंबंधी तपासणी व सल्ला',
      };

  String get generalMedicineTitle => switch (locale) {
        KioskLocale.english => 'General Medicine',
        KioskLocale.hindi => 'सामान्य चिकित्सा (General Medicine)',
        KioskLocale.marathi => 'सामान्य वैद्यकशास्त्र (General Medicine)',
      };
  String get generalMedicineDesc => switch (locale) {
        KioskLocale.english => 'General health concerns and common medical conditions',
        KioskLocale.hindi => 'सामान्य स्वास्थ्य समस्याएं और आम चिकित्सीय स्थितियां',
        KioskLocale.marathi => 'सामान्य आरोग्य समस्या आणि दैनंदिन आजारांसंबंधी सल्ला',
      };

  String get selectedDepartment => switch (locale) {
        KioskLocale.english => 'Selected Department',
        KioskLocale.hindi => 'चयनित विभाग',
        KioskLocale.marathi => 'निवडलेला विभाग',
      };

  String get previousVisitQuestion => switch (locale) {
        KioskLocale.english => 'You have previously visited this department. Would you like to visit the same doctor?',
        KioskLocale.hindi => 'आप पहले इस विभाग में परामर्श ले चुके हैं। क्या आप उसी डॉक्टर से मिलना चाहते हैं?',
        KioskLocale.marathi => 'तुम्ही यापूर्वी या विभागाला भेट दिली आहे. तुम्हाला त्याच डॉक्टरांना भेटायचे आहे का?',
      };

  String get appointmentRequestedTitle => switch (locale) {
        KioskLocale.english => 'APPOINTMENT REQUESTED',
        KioskLocale.hindi => 'अपॉइंटमेंट का अनुरोध किया गया',
        KioskLocale.marathi => 'अपॉइंटमेंटची विनंती केली',
      };

  String get pleaseWaitForTurn => switch (locale) {
        KioskLocale.english => 'Please wait for your turn.',
        KioskLocale.hindi => 'कृपया अपनी बारी की प्रतीक्षा करें।',
        KioskLocale.marathi => 'कृपया आपल्या पाळीची प्रतीक्षा करा.',
      };

  String get requestRegisteredSuccess => switch (locale) {
        KioskLocale.english => 'Your request has been successfully registered.',
        KioskLocale.hindi => 'आपका अनुरोध सफलतापूर्वक पंजीकृत हो गया है।',
        KioskLocale.marathi => 'तुमची विनंती यशस्वीरित्या नोंदवली गेली आहे.',
      };

  String get allDoctorsBusyNotice => switch (locale) {
        KioskLocale.english => 'OPD consultation request pending. Please proceed to the department waiting area.',
        KioskLocale.hindi => 'ओपीडी परामर्श अनुरोध प्रतीक्षा में है। कृपया विभाग प्रतीक्षा क्षेत्र में जाएं।',
        KioskLocale.marathi => 'ओपीडी सल्लामसलत विनंती प्रलंबित आहे. कृपया विभाग प्रतीक्षा कक्षात जा.',
      };

  // Doctor Preference Screen
  String get doctorPreferenceTitle => switch (locale) {
        KioskLocale.english => 'Doctor Preference',
        KioskLocale.hindi => 'डॉक्टर की प्राथमिकता',
        KioskLocale.marathi => 'डॉक्टरांचे प्राधान्य',
      };
  String get doctorPreferencePrompt => switch (locale) {
        KioskLocale.english => 'Do you want to consult the previous doctor you visited or a new doctor?',
        KioskLocale.hindi => 'क्या आप पिछले डॉक्टर से परामर्श करना चाहते हैं या किसी नए डॉक्टर से?',
        KioskLocale.marathi => 'तुम्हाला पूर्वी भेट दिलेल्या डॉक्टरांचा सल्ला घ्यायचा आहे की नवीन डॉक्टरांचा?',
      };
  String get previousDoctor => switch (locale) {
        KioskLocale.english => 'PREVIOUS DOCTOR',
        KioskLocale.hindi => 'पिछला डॉक्टर',
        KioskLocale.marathi => 'मागील डॉक्टर',
      };
  String get newDoctor => switch (locale) {
        KioskLocale.english => 'NEW DOCTOR',
        KioskLocale.hindi => 'नया डॉक्टर',
        KioskLocale.marathi => 'नवीन डॉक्टर',
      };
  String get doctorUnavailableTitle => switch (locale) {
        KioskLocale.english => 'Doctor Not Available',
        KioskLocale.hindi => 'डॉक्टर उपलब्ध नहीं हैं',
        KioskLocale.marathi => 'डॉक्टर उपलब्ध नाहीत',
      };
  String get doctorUnavailableMessage => switch (locale) {
        KioskLocale.english => 'Doctor not available. Do you want to visit another doctor?',
        KioskLocale.hindi => 'डॉक्टर उपलब्ध नहीं हैं। क्या आप किसी अन्य डॉक्टर से मिलना चाहते हैं?',
        KioskLocale.marathi => 'डॉक्टर उपलब्ध नाहीत. तुम्हाला दुसऱ्या डॉक्टरांना भेटायचे आहे का?',
      };
  String get yes => switch (locale) {
        KioskLocale.english => 'YES',
        KioskLocale.hindi => 'हाँ',
        KioskLocale.marathi => 'होय',
      };
  String get no => switch (locale) {
        KioskLocale.english => 'NO',
        KioskLocale.hindi => 'नहीं',
        KioskLocale.marathi => 'नाही',
      };

  // Queue Screen
  String get queueTicketTitle => switch (locale) {
        KioskLocale.english => 'Appointment Confirmed',
        KioskLocale.hindi => 'अपॉइंटमेंट की पुष्टि हुई',
        KioskLocale.marathi => 'अपॉइंटमेंट निश्चित झाली',
      };
  String get yourQueueNumber => switch (locale) {
        KioskLocale.english => 'YOUR QUEUE NUMBER',
        KioskLocale.hindi => 'आपका कतार नंबर',
        KioskLocale.marathi => 'तुमचा रांग क्रमांक',
      };
  String get pleaseTakeSeat => switch (locale) {
        KioskLocale.english => 'Please take a seat in the waiting area.',
        KioskLocale.hindi => 'कृपया प्रतीक्षा क्षेत्र में अपना स्थान ग्रहण करें।',
        KioskLocale.marathi => 'कृपया प्रतीक्षा कक्षात आपले स्थान ग्रहण करा.',
      };
  String get notifyOnPhone => switch (locale) {
        KioskLocale.english => 'You will be notified on your phone when your appointment is ready.',
        KioskLocale.hindi => 'अपॉइंटमेंट तैयार होने पर आपके फोन पर सूचित किया जाएगा।',
        KioskLocale.marathi => 'अपॉइंटमेंट तयार झाल्यावर तुमच्या फोनवर सूचित केले जाईल.',
      };
  String autoReturningIn(int seconds) => switch (locale) {
        KioskLocale.english => 'Returning to standby in $seconds seconds...',
        KioskLocale.hindi => '$seconds सेकंड में स्टैंडबाय पर वापस जा रहे हैं...',
        KioskLocale.marathi => '$seconds सेकंदात स्टँडबायवर परत जात आहे...',
      };

  // Thank You Screen (Phase 8 Final Correction)
  String get thankYouTitle => switch (locale) {
        KioskLocale.english => 'Thank You',
        KioskLocale.hindi => 'धन्यवाद',
        KioskLocale.marathi => 'धन्यवाद',
      };
  String get thankYouVisitAgain => switch (locale) {
        KioskLocale.english => 'Thank you, visit again.',
        KioskLocale.hindi => 'धन्यवाद, फिर पधारें।',
        KioskLocale.marathi => 'धन्यवाद, पुन्हा भेट द्या.',
      };
  String get thankYouReturningToStandby => switch (locale) {
        KioskLocale.english => 'Returning to Standby for the next patient...',
        KioskLocale.hindi => 'अगले मरीज के लिए स्टैंडबाय पर वापस जा रहे हैं...',
        KioskLocale.marathi => 'पुढील रुग्णासाठी स्टँडबायवर परत जात आहे...',
      };

  // General Actions
  String get back => switch (locale) {
        KioskLocale.english => 'BACK',
        KioskLocale.hindi => 'वापस',
        KioskLocale.marathi => 'मागे',
      };
  String get cancel => switch (locale) {
        KioskLocale.english => 'CANCEL',
        KioskLocale.hindi => 'रद्द करें',
        KioskLocale.marathi => 'रद्द करा',
      };
  String get continueText => switch (locale) {
        KioskLocale.english => 'CONTINUE',
        KioskLocale.hindi => 'आगे बढ़ें',
        KioskLocale.marathi => 'पुढे जा',
      };
}
