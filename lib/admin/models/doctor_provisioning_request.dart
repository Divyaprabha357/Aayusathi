/// Data transfer object holding validated physician details for provisioning.
class DoctorProvisioningRequest {
  final String name;
  final String registeredPhone;
  final String qualification;
  final String department;
  final String? email;

  const DoctorProvisioningRequest({
    required this.name,
    required this.registeredPhone,
    required this.qualification,
    required this.department,
    this.email,
  });

  /// Normalizes Indian registered phone number with standard `+91` country code.
  String get standardizedPhone {
    final clean = registeredPhone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
    if (clean.startsWith('+91')) {
      return clean;
    }
    if (clean.startsWith('91') && clean.length == 12) {
      return '+$clean';
    }
    return '+91$clean';
  }

  /// Canonical department ID (e.g. 'cardiology', 'general_medicine').
  String get canonicalDepartment {
    final lower = department.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '_');
    if (lower.contains('cardio')) return 'cardiology';
    if (lower.contains('neuro')) return 'neurology';
    if (lower.contains('gastro')) return 'gastroenterology';
    if (lower.contains('ortho')) return 'orthopedics';
    if (lower.contains('pediatric') || lower.contains('paediatric')) return 'pediatrics';
    if (lower.contains('ent')) return 'ent';
    if (lower.contains('derma')) return 'dermatology';
    if (lower.contains('general') || lower.contains('medicine')) return 'general_medicine';
    return lower;
  }
}
