/// Conceptual dashboard sections for Admin Portal.
enum AdminSection {
  dashboard,
  doctors,
  availability,
  appointmentEscalations,
  caseEscalations;

  String get label {
    switch (this) {
      case AdminSection.dashboard:
        return 'Dashboard';
      case AdminSection.doctors:
        return 'Doctors';
      case AdminSection.availability:
        return 'Availability';
      case AdminSection.appointmentEscalations:
        return 'Appointment Escalations';
      case AdminSection.caseEscalations:
        return 'Case Escalations';
    }
  }
}
