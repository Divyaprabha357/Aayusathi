import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';

/// Online presence status for the clinical workstation.
enum DoctorOnlineStatus {
  online,
  offline;

  String get label {
    switch (this) {
      case DoctorOnlineStatus.online:
        return 'System Online';
      case DoctorOnlineStatus.offline:
        return 'System Offline';
    }
  }

  Color get color {
    switch (this) {
      case DoctorOnlineStatus.online:
        return DoctorColors.statusOnline;
      case DoctorOnlineStatus.offline:
        return DoctorColors.statusOffline;
    }
  }

  IconData get icon {
    switch (this) {
      case DoctorOnlineStatus.online:
        return Icons.wifi_rounded;
      case DoctorOnlineStatus.offline:
        return Icons.wifi_off_rounded;
    }
  }
}

/// Clinical availability status of the doctor workstation.
enum DoctorWorkStatus {
  available,
  inConsultation,
  busy,
  onBreak;

  String get label {
    switch (this) {
      case DoctorWorkStatus.available:
        return 'Available';
      case DoctorWorkStatus.inConsultation:
        return 'In Consultation';
      case DoctorWorkStatus.busy:
        return 'Busy';
      case DoctorWorkStatus.onBreak:
        return 'On Break';
    }
  }

  Color get color {
    switch (this) {
      case DoctorWorkStatus.available:
        return DoctorColors.statusAvailable;
      case DoctorWorkStatus.inConsultation:
        return DoctorColors.statusInConsultation;
      case DoctorWorkStatus.busy:
        return DoctorColors.statusBusy;
      case DoctorWorkStatus.onBreak:
        return DoctorColors.statusOffline;
    }
  }

  IconData get icon {
    switch (this) {
      case DoctorWorkStatus.available:
        return Icons.check_circle_outline_rounded;
      case DoctorWorkStatus.inConsultation:
        return Icons.record_voice_over_rounded;
      case DoctorWorkStatus.busy:
        return Icons.do_not_disturb_on_rounded;
      case DoctorWorkStatus.onBreak:
        return Icons.coffee_rounded;
    }
  }
}
