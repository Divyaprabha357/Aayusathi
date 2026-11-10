/// Privacy-safe summary model of an active waiting appointment for the Admin Dashboard.
///
/// PRIVACY & SECURITY MANDATE:
/// Displays ONLY non-identifiable queue data:
/// - Queue Number
/// - Age & Gender
/// - Clinical Domain
/// - Request Type
/// - Waiting Duration
/// - Status
///
/// Strictly OMITS:
/// - Aadhaar numbers
/// - Phone numbers
/// - Patient names
/// - Residential addresses
/// - Firebase Auth UIDs
/// - Tokens / OTPs
class AdminWaitingAppointmentSummary {
  final String requestId;
  final String queueNumber;
  final int? age;
  final String? gender;
  final String domain;
  final String requestType;
  final String waitingDurationFormatted;
  final String status;
  final DateTime createdAt;

  const AdminWaitingAppointmentSummary({
    required this.requestId,
    required this.queueNumber,
    this.age,
    this.gender,
    required this.domain,
    required this.requestType,
    required this.waitingDurationFormatted,
    this.status = 'Waiting',
    required this.createdAt,
  });

  /// Formatted age and gender string (e.g. 'Age 34 • Male' or 'Age -- • Female').
  String get demographicsFormatted {
    final ageStr = age != null ? 'Age $age' : 'Age --';
    final genderStr = gender != null && gender!.isNotEmpty ? gender! : '--';
    return '$ageStr • $genderStr';
  }

  /// Returns a map of non-sensitive display properties for debugging/auditing without PII exposure.
  Map<String, dynamic> toSafeDisplayMap() {
    return {
      'requestId': requestId,
      'queueNumber': queueNumber,
      'age': age,
      'gender': gender,
      'domain': domain,
      'requestType': requestType,
      'waitingDurationFormatted': waitingDurationFormatted,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'AdminWaitingAppointmentSummary(queue: $queueNumber, domain: $domain, waiting: $waitingDurationFormatted)';
  }
}
