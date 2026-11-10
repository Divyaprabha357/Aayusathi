import 'package:flutter/foundation.dart';

/// Lightweight presentation model for Doctor Availability domain rows.
@immutable
class AdminAvailabilityItem {
  final String domainId;
  final String domainName;
  final int availableDoctors;
  final int totalDoctors;
  final bool isOnline;

  const AdminAvailabilityItem({
    required this.domainId,
    required this.domainName,
    required this.availableDoctors,
    required this.totalDoctors,
    this.isOnline = true,
  });

  /// Default baseline domains for hospital outpatient specialties
  static List<AdminAvailabilityItem> get defaultDomains => const [
        AdminAvailabilityItem(
          domainId: 'cardiology',
          domainName: 'Cardiology',
          availableDoctors: 3,
          totalDoctors: 4,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'neurology',
          domainName: 'Neurology',
          availableDoctors: 2,
          totalDoctors: 3,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'gastroenterology',
          domainName: 'Gastroenterology',
          availableDoctors: 2,
          totalDoctors: 2,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'orthopedics',
          domainName: 'Orthopedics',
          availableDoctors: 2,
          totalDoctors: 3,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'pediatrics',
          domainName: 'Pediatrics',
          availableDoctors: 3,
          totalDoctors: 4,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'ent',
          domainName: 'ENT',
          availableDoctors: 2,
          totalDoctors: 2,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'dermatology',
          domainName: 'Dermatology',
          availableDoctors: 2,
          totalDoctors: 3,
          isOnline: true,
        ),
        AdminAvailabilityItem(
          domainId: 'general_medicine',
          domainName: 'General Medicine',
          availableDoctors: 2,
          totalDoctors: 3,
          isOnline: true,
        ),
      ];
}
