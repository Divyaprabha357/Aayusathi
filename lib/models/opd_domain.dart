import 'package:flutter/material.dart';
import '../core/localization/kiosk_strings.dart';

/// Immutable model representing an OPD Clinical Domain / Department in AAYUSATHI.
class OpdDomain {
  final String id;
  final IconData icon;

  const OpdDomain({
    required this.id,
    required this.icon,
  });

  /// Localized clinical department title.
  String title(KioskStrings strings) {
    switch (id) {
      case 'cardiology':
        return strings.cardiologyTitle;
      case 'neurology':
        return strings.neurologyTitle;
      case 'gastroenterology':
        return strings.gastroenterologyTitle;
      case 'orthopedics':
        return strings.orthopedicsTitle;
      case 'pediatrics':
        return strings.pediatricsTitle;
      case 'ent':
        return strings.entTitle;
      case 'dermatology':
        return strings.dermatologyTitle;
      case 'general_medicine':
      default:
        return strings.generalMedicineTitle;
    }
  }

  /// Localized patient-friendly description (without diagnostic claims).
  String description(KioskStrings strings) {
    switch (id) {
      case 'cardiology':
        return strings.cardiologyDesc;
      case 'neurology':
        return strings.neurologyDesc;
      case 'gastroenterology':
        return strings.gastroenterologyDesc;
      case 'orthopedics':
        return strings.orthopedicsDesc;
      case 'pediatrics':
        return strings.pediatricsDesc;
      case 'ent':
        return strings.entDesc;
      case 'dermatology':
        return strings.dermatologyDesc;
      case 'general_medicine':
      default:
        return strings.generalMedicineDesc;
    }
  }

  /// Pre-configured list of all 8 standard OPD clinical domains.
  static const List<OpdDomain> all = [
    OpdDomain(
      id: 'cardiology',
      icon: Icons.favorite_rounded,
    ),
    OpdDomain(
      id: 'neurology',
      icon: Icons.psychology_rounded,
    ),
    OpdDomain(
      id: 'gastroenterology',
      icon: Icons.medication_liquid_rounded,
    ),
    OpdDomain(
      id: 'orthopedics',
      icon: Icons.accessibility_new_rounded,
    ),
    OpdDomain(
      id: 'pediatrics',
      icon: Icons.child_care_rounded,
    ),
    OpdDomain(
      id: 'ent',
      icon: Icons.hearing_rounded,
    ),
    OpdDomain(
      id: 'dermatology',
      icon: Icons.healing_rounded,
    ),
    OpdDomain(
      id: 'general_medicine',
      icon: Icons.local_hospital_rounded,
    ),
  ];

  /// Find domain by its identifier.
  static OpdDomain? findById(String id) {
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpdDomain && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
