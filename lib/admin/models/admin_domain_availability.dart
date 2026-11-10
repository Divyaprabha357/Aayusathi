/// Model representing real-time clinician presence and capacity for an OPD specialty domain.
class AdminDomainAvailability {
  final String domainId;
  final String domainName;
  final int totalDoctors;
  final int onlineDoctors;
  final int available;
  final int inConsultation;

  const AdminDomainAvailability({
    required this.domainId,
    required this.domainName,
    required this.totalDoctors,
    required this.onlineDoctors,
    required this.available,
    required this.inConsultation,
  });

  /// Factory creating an empty/zero-initialized domain availability item.
  factory AdminDomainAvailability.empty(String domainId, String domainName) {
    return AdminDomainAvailability(
      domainId: domainId,
      domainName: domainName,
      totalDoctors: 0,
      onlineDoctors: 0,
      available: 0,
      inConsultation: 0,
    );
  }

  /// 8 standard OPD clinical domains in AAYUSATHI.
  static const List<Map<String, String>> standardDomains = [
    {'id': 'cardiology', 'name': 'Cardiology'},
    {'id': 'neurology', 'name': 'Neurology'},
    {'id': 'gastroenterology', 'name': 'Gastroenterology'},
    {'id': 'orthopedics', 'name': 'Orthopedics'},
    {'id': 'pediatrics', 'name': 'Pediatrics'},
    {'id': 'ent', 'name': 'ENT'},
    {'id': 'dermatology', 'name': 'Dermatology'},
    {'id': 'general_medicine', 'name': 'General Medicine'},
  ];

  /// Generates default zero-initialized availability items for all 8 standard domains.
  static List<AdminDomainAvailability> defaultEmptyList() {
    return standardDomains
        .map((d) => AdminDomainAvailability.empty(d['id']!, d['name']!))
        .toList();
  }

  /// Alias for defaultEmptyList
  static List<AdminDomainAvailability> get defaultEightDomains => defaultEmptyList();

  AdminDomainAvailability copyWith({
    String? domainId,
    String? domainName,
    int? totalDoctors,
    int? onlineDoctors,
    int? available,
    int? inConsultation,
  }) {
    return AdminDomainAvailability(
      domainId: domainId ?? this.domainId,
      domainName: domainName ?? this.domainName,
      totalDoctors: totalDoctors ?? this.totalDoctors,
      onlineDoctors: onlineDoctors ?? this.onlineDoctors,
      available: available ?? this.available,
      inConsultation: inConsultation ?? this.inConsultation,
    );
  }

  @override
  String toString() {
    return 'AdminDomainAvailability($domainName: online=$onlineDoctors, avail=$available, consult=$inConsultation, total=$totalDoctors)';
  }
}
