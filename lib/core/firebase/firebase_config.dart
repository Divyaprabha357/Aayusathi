/// Firebase project configuration constants and Firestore collection schema
/// for the AAYUSATHI ecosystem.
class FirebaseConfig {
  FirebaseConfig._();

  // Firebase Project Metadata
  static const String projectId = 'aayusathi-a1199';
  static const String projectNumber = '919886761374';
  static const String region = 'asia-south1';
  static const String storageBucket = 'aayusathi-a1199.firebasestorage.app';
  static const String firestoreDatabaseId = '(default)';

  // Top-Level Cloud Firestore Collections
  static const String patientsCollection = 'patients';
  static const String doctorsCollection = 'doctors';
  static const String appointmentsCollection = 'appointments';
  static const String vitalsCollection = 'vitals';
  static const String visitsCollection = 'visits';
  static const String casesCollection = 'cases';
  static const String prescriptionsCollection = 'prescriptions';
  static const String reportsCollection = 'reports';
  static const String notificationsCollection = 'notifications';
  static const String escalationsCollection = 'escalations';
  static const String auditLogsCollection = 'auditLogs';
  static const String demoAadhaarCollection = 'demo_aadhaar';

  /// List of all recognized primary Firestore collections
  static const List<String> allCollections = [
    patientsCollection,
    doctorsCollection,
    appointmentsCollection,
    vitalsCollection,
    visitsCollection,
    casesCollection,
    prescriptionsCollection,
    reportsCollection,
    notificationsCollection,
    escalationsCollection,
    auditLogsCollection,
  ];
}
