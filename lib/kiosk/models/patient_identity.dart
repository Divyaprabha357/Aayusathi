/// Represents a verified patient identity at the AAYUSATHI Kiosk.
/// Can originate from an Aadhaar record or an existing AAYUSATHI Patient ID lookup.
class PatientIdentity {
  final String aadhaarNumber;
  final String patientId;
  final String fullName;
  final String dob;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String bloodGroup;
  final bool isNewRegistration;

  const PatientIdentity({
    required this.aadhaarNumber,
    required this.patientId,
    required this.fullName,
    required this.dob,
    required this.age,
    required this.gender,
    this.phone = '',
    required this.address,
    required this.bloodGroup,
    this.isNewRegistration = false,
  });

  /// Formatted 12-digit Aadhaar number with space grouping: "XXXX XXXX XXXX"
  String get formattedAadhaar {
    final clean = aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
    if (clean.length != 12) return aadhaarNumber;
    return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8, 12)}';
  }

  /// Masked Aadhaar number showing only last 4 digits: "XXXX XXXX 3333"
  String get maskedAadhaar {
    final clean = aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
    if (clean.length != 12) return aadhaarNumber;
    return 'XXXX XXXX ${clean.substring(8, 12)}';
  }

  /// Masked phone number showing only last 4 digits for privacy: "+91 ••••• •3210"
  String get maskedPhone {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.length >= 10) {
      final suffix = clean.substring(clean.length - 4);
      return '+91 ••••• •$suffix';
    }
    return phone;
  }

  /// Display string combining DOB and Age
  String get dobWithAge => '$dob ($age Yrs)';

  PatientIdentity copyWith({
    String? aadhaarNumber,
    String? patientId,
    String? fullName,
    String? dob,
    int? age,
    String? gender,
    String? phone,
    String? address,
    String? bloodGroup,
    bool? isNewRegistration,
  }) {
    return PatientIdentity(
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      patientId: patientId ?? this.patientId,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      isNewRegistration: isNewRegistration ?? this.isNewRegistration,
    );
  }
}
