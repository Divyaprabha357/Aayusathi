import 'package:flutter/material.dart';
import '../../doctor/models/doctor_profile.dart';
import '../../models/opd_domain.dart';
import '../controllers/admin_manage_doctors_controller.dart';
import '../models/admin_domain_availability.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';

// ===========================================================================
// 1. DEACTIVATE DOCTOR DIALOG (With Active Consultation Guard)
// ===========================================================================
class AdminDeactivateDoctorDialog extends StatefulWidget {
  final DoctorProfile doctor;
  final AdminManageDoctorsController controller;

  const AdminDeactivateDoctorDialog({
    super.key,
    required this.doctor,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DoctorProfile doctor,
    required AdminManageDoctorsController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminDeactivateDoctorDialog(
        doctor: doctor,
        controller: controller,
      ),
    );
  }

  @override
  State<AdminDeactivateDoctorDialog> createState() => _AdminDeactivateDoctorDialogState();
}

class _AdminDeactivateDoctorDialogState extends State<AdminDeactivateDoctorDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  bool get _isInConsultation =>
      widget.doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation;

  Future<void> _handleConfirm() async {
    if (_isInConsultation) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.controller.setDoctorActiveStatus(
      doctor: widget.doctor,
      newActiveStatus: false,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = widget.controller.actionError ?? 'Failed to deactivate doctor.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (_isInConsultation ? AdminColors.brandOrange : AdminColors.statusCritical)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isInConsultation ? Icons.record_voice_over_rounded : Icons.person_off_rounded,
                      color: _isInConsultation ? AdminColors.brandOrange : AdminColors.statusCritical,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isInConsultation
                              ? 'CANNOT DEACTIVATE DOCTOR'
                              : 'DEACTIVATE DOCTOR ACCOUNT',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.doctor.name,
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),

              // Active Consultation Safeguard Alert
              if (_isInConsultation) ...[
                Container(
                  padding: const EdgeInsets.all(AdminTheme.space14),
                  decoration: BoxDecoration(
                    color: AdminColors.brandOrange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AdminTheme.radius10),
                    border: Border.all(color: AdminColors.brandOrange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AdminColors.brandOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This physician is currently IN CONSULTATION with a patient. Clinical deactivation is blocked until the active consultation is concluded.',
                          style: AdminTheme.bodyRegular.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminTheme.space20),
              ] else ...[
                // Standard Confirmation Text
                Text(
                  'Are you sure you want to deactivate ${widget.doctor.name} (${widget.doctor.doctorUniqueCode})?',
                  style: AdminTheme.bodyRegular.copyWith(
                    color: AdminColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.space12),
                Container(
                  padding: const EdgeInsets.all(AdminTheme.space12),
                  decoration: BoxDecoration(
                    color: AdminColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                    border: Border.all(color: AdminColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletItem('The physician will immediately lose login access to the Doctor Workstation.'),
                      const SizedBox(height: 6),
                      _buildBulletItem('No new patient queue assignments will route to this account.'),
                      const SizedBox(height: 6),
                      _buildBulletItem('All historical consultations and past clinical records remain permanently preserved.'),
                    ],
                  ),
                ),
                const SizedBox(height: AdminTheme.space20),
              ],

              // Error display
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.statusCritical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.space12),
              ],

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: _isInConsultation ? 'CLOSE' : 'CANCEL',
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                  ),
                  if (!_isInConsultation) ...[
                    const SizedBox(width: AdminTheme.space12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.statusCritical,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AdminTheme.radius8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isProcessing ? null : _handleConfirm,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'CONFIRM DEACTIVATION',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AdminColors.brandNavy, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 2. ACTIVATE DOCTOR DIALOG
// ===========================================================================
class AdminActivateDoctorDialog extends StatefulWidget {
  final DoctorProfile doctor;
  final AdminManageDoctorsController controller;

  const AdminActivateDoctorDialog({
    super.key,
    required this.doctor,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DoctorProfile doctor,
    required AdminManageDoctorsController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminActivateDoctorDialog(
        doctor: doctor,
        controller: controller,
      ),
    );
  }

  @override
  State<AdminActivateDoctorDialog> createState() => _AdminActivateDoctorDialogState();
}

class _AdminActivateDoctorDialogState extends State<AdminActivateDoctorDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = await widget.controller.setDoctorActiveStatus(
      doctor: widget.doctor,
      newActiveStatus: true,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = widget.controller.actionError ?? 'Failed to activate doctor.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.statusAvailable.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: AdminColors.statusAvailable,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVATE DOCTOR ACCOUNT',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.doctor.name,
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),
              Text(
                'Reactivate ${widget.doctor.name} (${widget.doctor.doctorUniqueCode}) for clinical duty?',
                style: AdminTheme.bodyRegular.copyWith(
                  color: AdminColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AdminTheme.space10),
              Text(
                'The physician will be able to log in to the Doctor Workstation and receive patient consultations in ${widget.doctor.department}.',
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AdminTheme.space20),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: AdminTheme.caption.copyWith(
                    color: AdminColors.statusCritical,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AdminTheme.space12),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: 'CANCEL',
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AdminTheme.space12),
                  AdminPrimaryButton(
                    label: 'CONFIRM ACTIVATION',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isProcessing,
                    onPressed: _isProcessing ? null : _handleConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 3. EDIT DOCTOR DIALOG (With Department Warning & Consultation Safeguard)
// ===========================================================================
class AdminEditDoctorDialog extends StatefulWidget {
  final DoctorProfile doctor;
  final AdminManageDoctorsController controller;

  const AdminEditDoctorDialog({
    super.key,
    required this.doctor,
    required this.controller,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DoctorProfile doctor,
    required AdminManageDoctorsController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AdminEditDoctorDialog(
        doctor: doctor,
        controller: controller,
      ),
    );
  }

  @override
  State<AdminEditDoctorDialog> createState() => _AdminEditDoctorDialogState();
}

class _AdminEditDoctorDialogState extends State<AdminEditDoctorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _qualificationController;
  late final TextEditingController _emailController;
  late String _selectedDepartment;

  String? _nameError;
  String? _phoneError;
  String? _qualificationError;
  String? _generalError;
  bool _isSaving = false;

  bool get _isInConsultation =>
      widget.doctor.availabilityStatus == DoctorAvailabilityStatus.inConsultation;

  bool get _isDepartmentChanged =>
      _selectedDepartment.toLowerCase() != widget.doctor.department.toLowerCase();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.doctor.name);
    _phoneController = TextEditingController(text: widget.doctor.registeredPhone);
    _qualificationController = TextEditingController(text: widget.doctor.qualification);
    _emailController = TextEditingController(text: widget.doctor.email);
    _selectedDepartment = widget.doctor.department;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _qualificationError = null;
      _generalError = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameError = 'Doctor name is required.';
      isValid = false;
    } else if (name.length < 3) {
      _nameError = 'Doctor name must be at least 3 characters.';
      isValid = false;
    }

    final phone = _phoneController.text.replaceAll(RegExp(r'[\s\-\(\)\+]+'), '');
    final last10 = phone.length >= 10 ? phone.substring(phone.length - 10) : phone;
    if (phone.isEmpty) {
      _phoneError = 'Mobile number is required.';
      isValid = false;
    } else if (last10.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(last10)) {
      _phoneError = 'Enter a valid 10-digit mobile number.';
      isValid = false;
    }

    final qual = _qualificationController.text.trim();
    if (qual.isEmpty) {
      _qualificationError = 'Qualification is required.';
      isValid = false;
    }

    if (_isDepartmentChanged && _isInConsultation) {
      _generalError = 'Cannot change department while doctor is IN CONSULTATION.';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() {
      _isSaving = true;
      _generalError = null;
    });

    final success = await widget.controller.updateDoctorProfile(
      doctor: widget.doctor,
      name: _nameController.text.trim(),
      qualification: _qualificationController.text.trim(),
      department: _selectedDepartment,
      registeredPhone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _generalError = widget.controller.actionError ?? 'Failed to update doctor profile.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final domains = AdminDomainAvailability.standardDomains;

    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        side: const BorderSide(color: AdminColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminTheme.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AdminColors.brandTeal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AdminTheme.radius10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AdminColors.brandTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EDIT DOCTOR PROFILE',
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Doctor ID: ${widget.doctor.doctorUniqueCode}',
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.brandTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AdminColors.textMuted),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AdminTheme.space20),

              // Department Change Safeguard / Warning Banner
              if (_isDepartmentChanged) ...[
                Container(
                  padding: const EdgeInsets.all(AdminTheme.space12),
                  decoration: BoxDecoration(
                    color: (_isInConsultation ? AdminColors.statusCritical : AdminColors.brandOrange)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                    border: Border.all(
                      color: (_isInConsultation ? AdminColors.statusCritical : AdminColors.brandOrange)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _isInConsultation ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                        color: _isInConsultation ? AdminColors.statusCritical : AdminColors.brandOrange,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isInConsultation
                              ? 'Doctor is currently IN CONSULTATION. Department transfer is blocked during active care.'
                              : 'Changing the Doctor\'s department affects future appointment routing. Historical clinical records remain unchanged.',
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AdminTheme.space16),
              ],

              // General Error Banner
              if (_generalError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AdminTheme.space12),
                  decoration: BoxDecoration(
                    color: AdminColors.statusCritical.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                    border: Border.all(color: AdminColors.statusCritical.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _generalError!,
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.statusCritical,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AdminTheme.space16),
              ],

              // 1. Full Name Field
              _buildLabel('FULL NAME', isRequired: true),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                decoration: _inputDecoration(
                  hintText: 'Dr. Full Name',
                  icon: Icons.person_outline_rounded,
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: AdminTheme.space16),

              // 2. Specialty Department Dropdown
              _buildLabel('DEPARTMENT / DOMAIN', isRequired: true),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(AdminTheme.radius10),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AdminColors.brandTeal),
                    items: domains.map((domain) {
                      final id = domain['id']!;
                      final name = domain['name']!;
                      final opd = OpdDomain.findById(id);

                      return DropdownMenuItem<String>(
                        value: id,
                        child: Row(
                          children: [
                            Icon(
                              opd?.icon ?? Icons.medical_services_outlined,
                              size: 18,
                              color: AdminColors.brandNavy,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: AdminTheme.bodyRegular.copyWith(
                                  color: AdminColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (_isSaving || _isInConsultation)
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedDepartment = val);
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(height: AdminTheme.space16),

              // 3. Qualification Field
              _buildLabel('QUALIFICATION / DEGREE', isRequired: true),
              const SizedBox(height: 6),
              TextField(
                controller: _qualificationController,
                enabled: !_isSaving,
                decoration: _inputDecoration(
                  hintText: 'MBBS, MD',
                  icon: Icons.school_outlined,
                  errorText: _qualificationError,
                ),
              ),
              const SizedBox(height: AdminTheme.space16),

              // 4. Registered Phone Field
              _buildLabel('REGISTERED PHONE', isRequired: true),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                enabled: !_isSaving,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDecoration(
                  hintText: '9876543210',
                  icon: Icons.phone_outlined,
                  prefixText: '+91 ',
                  counterText: '',
                  errorText: _phoneError,
                ),
              ),
              const SizedBox(height: AdminTheme.space16),

              // 5. Email (Optional)
              _buildLabel('OFFICIAL EMAIL (OPTIONAL)', isRequired: false),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hintText: 'doctor@hospital.aayusathi.in',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: AdminTheme.space24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: 'CANCEL',
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: AdminTheme.space12),
                  AdminPrimaryButton(
                    label: _isSaving ? 'SAVING...' : 'SAVE CHANGES',
                    icon: _isSaving ? null : Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AdminTheme.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: AdminColors.brandNavy,
            letterSpacing: 0.5,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AdminColors.statusCritical, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    String? prefixText,
    String? counterText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AdminTheme.bodyRegular.copyWith(color: AdminColors.textMuted),
      prefixText: prefixText,
      prefixStyle: AdminTheme.bodyRegular.copyWith(color: AdminColors.brandNavy, fontWeight: FontWeight.w600),
      counterText: counterText,
      errorText: errorText,
      errorStyle: AdminTheme.caption.copyWith(color: AdminColors.statusCritical),
      prefixIcon: Icon(icon, size: 20, color: AdminColors.brandTeal),
      filled: true,
      fillColor: AdminColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius10),
        borderSide: const BorderSide(color: AdminColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius10),
        borderSide: const BorderSide(color: AdminColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius10),
        borderSide: const BorderSide(color: AdminColors.brandTeal, width: 1.5),
      ),
    );
  }
}
