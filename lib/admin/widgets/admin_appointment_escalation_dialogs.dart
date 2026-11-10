import 'package:flutter/material.dart';
import '../../models/appointment_request.dart';
import '../../services/appointment_escalation_policy.dart';
import '../controllers/admin_appointment_escalation_controller.dart';
import '../localization/admin_localizations.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import 'admin_buttons.dart';

/// Modal dialog providing privacy-safe inspection of an escalated appointment's
/// SLA duration, request parameters, and clinical domain (Phase A7).
class AdminAppointmentEscalationDialog extends StatelessWidget {
  final AppointmentRequest appointment;

  const AdminAppointmentEscalationDialog({
    super.key,
    required this.appointment,
  });

  static Future<void> show(BuildContext context, AppointmentRequest appointment) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminAppointmentEscalationDialog(appointment: appointment),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${_formatTime(time)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final waitDuration = AppointmentEscalationPolicy.calculateWaitDuration(appointment.createdAt);
    final durationFormatted = AppointmentEscalationPolicy.formatWaitDuration(waitDuration);

    final isEscalated = appointment.isEscalated ||
        AppointmentEscalationPolicy.shouldEscalate(appointment);

    String maskPatientId(String id) {
      if (id.length <= 4) return id;
      final last4 = id.substring(id.length - 4);
      return 'PAT-IND-****$last4';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(AdminTheme.space24),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.borderSubtle),
          boxShadow: AdminTheme.shadowCard,
        ),
        child: SingleChildScrollView(
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
                      color: isEscalated
                          ? AdminColors.statusCritical.withValues(alpha: 0.12)
                          : AdminColors.brandTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AdminTheme.radius12),
                    ),
                    child: Icon(
                      isEscalated
                          ? Icons.notification_important_rounded
                          : Icons.info_outline_rounded,
                      color: isEscalated
                          ? AdminColors.statusCritical
                          : AdminColors.brandTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AdminTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.detailsModalTitle,
                          style: AdminTheme.headline2.copyWith(
                            color: AdminColors.brandNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AdminTheme.space4),
                        Text(
                          strings.detailsModalSubtitle,
                          style: AdminTheme.caption.copyWith(
                            color: AdminColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AdminColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: strings.close,
                  ),
                ],
              ),

              const SizedBox(height: AdminTheme.space16),
              const Divider(height: 1, color: AdminColors.borderSubtle),
              const SizedBox(height: AdminTheme.space16),

              // SLA Status Pill Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AdminTheme.space14),
                decoration: BoxDecoration(
                  color: isEscalated
                      ? AdminColors.statusCritical.withValues(alpha: 0.06)
                      : AdminColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AdminTheme.radius12),
                  border: Border.all(
                    color: isEscalated
                        ? AdminColors.statusCritical.withValues(alpha: 0.25)
                        : AdminColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEscalated
                          ? Icons.timer_outlined
                          : Icons.hourglass_bottom_rounded,
                      color: isEscalated
                          ? AdminColors.statusCritical
                          : AdminColors.brandTeal,
                      size: 22,
                    ),
                    const SizedBox(width: AdminTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEscalated
                                ? 'SLA BREACH: ESCALATED (>20 min)'
                                : 'QUEUE RESPONSE WITHIN SLA (<20 min)',
                            style: AdminTheme.badgeText.copyWith(
                              color: isEscalated
                                  ? AdminColors.statusCritical
                                  : AdminColors.brandTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Elapsed Wait Duration: $durationFormatted',
                            style: AdminTheme.bodyRegular.copyWith(
                              color: AdminColors.brandNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isEscalated
                            ? AdminColors.statusCritical.withValues(alpha: 0.12)
                            : AdminColors.brandTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AdminTheme.radius8),
                      ),
                      child: Text(
                        isEscalated ? 'ESCALATED' : 'WAITING',
                        style: AdminTheme.badgeText.copyWith(
                          color: isEscalated
                              ? AdminColors.statusCritical
                              : AdminColors.brandTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AdminTheme.space16),

              // Information Rows
              _buildDetailRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Queue Ticket Number',
                value: appointment.queueNumber,
                isHighlight: true,
              ),
              _buildDetailRow(
                icon: Icons.tag_rounded,
                label: 'Appointment Request ID',
                value: appointment.requestId,
              ),
              _buildDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Patient ID (Masked)',
                value: maskPatientId(appointment.patientId),
              ),
              _buildDetailRow(
                icon: Icons.local_hospital_outlined,
                label: 'Specialty Department',
                value: appointment.domainId.toUpperCase(),
              ),
              _buildDetailRow(
                icon: Icons.person_search_outlined,
                label: 'Routing Mode',
                value: appointment.preferredDoctorMode == PreferredDoctorMode.sameDoctor
                    ? 'Previous Doctor (${appointment.previousDoctorId ?? "Not specified"})'
                    : 'Any Available Specialist',
              ),
              _buildDetailRow(
                icon: Icons.access_time_rounded,
                label: 'Created At (Server Time)',
                value: _formatDateTime(appointment.createdAt),
              ),
              if (appointment.escalatedAt != null)
                _buildDetailRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'Escalated At',
                  value: _formatDateTime(appointment.escalatedAt!),
                ),

              const SizedBox(height: AdminTheme.space14),

              // Privacy Assurance Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  border: Border.all(color: AdminColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AdminColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Strict Privacy Mode: Patient Aadhaar, phone number, and sensitive credentials remain protected.',
                        style: AdminTheme.caption.copyWith(
                          fontSize: 11,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AdminTheme.space16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminSecondaryButton(
                    label: strings.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AdminTheme.space6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminColors.textSecondary),
          const SizedBox(width: AdminTheme.space8),
          Text(
            label,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AdminTheme.bodyRegular.copyWith(
                color: isHighlight ? AdminColors.brandTeal : AdminColors.brandNavy,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal dialog allowing the administrator to select and atomically assign an eligible
/// available physician to an escalated appointment (Phase A7).
class AdminAssignDoctorDialog extends StatefulWidget {
  final AppointmentRequest appointment;

  const AdminAssignDoctorDialog({
    super.key,
    required this.appointment,
  });

  static Future<bool?> show(BuildContext context, AppointmentRequest appointment) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminAssignDoctorDialog(appointment: appointment),
    );
  }

  @override
  State<AdminAssignDoctorDialog> createState() => _AdminAssignDoctorDialogState();
}

class _AdminAssignDoctorDialogState extends State<AdminAssignDoctorDialog> {
  final AdminAppointmentEscalationController _controller =
      AdminAppointmentEscalationController.instance;

  String? _selectedDoctorId;
  String? _errorMessage;
  bool _isCommitting = false;

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);
    final eligibleDoctors =
        _controller.getEligibleDoctorsForAppointment(widget.appointment);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(AdminTheme.space24),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminTheme.radius16),
          border: Border.all(color: AdminColors.borderSubtle),
          boxShadow: AdminTheme.shadowCard,
        ),
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
                    color: AdminColors.brandNavy.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AdminTheme.radius12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AdminColors.brandNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AdminTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.assignDoctorModalTitle,
                        style: AdminTheme.headline2.copyWith(
                          color: AdminColors.brandNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AdminTheme.space4),
                      Text(
                        strings.assignDoctorModalSubtitle,
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AdminColors.textSecondary),
                  onPressed: _isCommitting ? null : () => Navigator.of(context).pop(false),
                  tooltip: strings.close,
                ),
              ],
            ),

            const SizedBox(height: AdminTheme.space16),
            const Divider(height: 1, color: AdminColors.borderSubtle),
            const SizedBox(height: AdminTheme.space16),

            // Target Appointment Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AdminTheme.space14),
              decoration: BoxDecoration(
                color: AdminColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AdminTheme.radius12),
                border: Border.all(color: AdminColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUEUE TICKET',
                        style: AdminTheme.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.appointment.queueNumber,
                        style: AdminTheme.bodyRegular.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.brandNavy,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEPARTMENT',
                        style: AdminTheme.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.appointment.domainId.toUpperCase(),
                        style: AdminTheme.bodyRegular.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.brandTeal,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAITING DURATION',
                        style: AdminTheme.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppointmentEscalationPolicy.formatWaitDuration(
                          AppointmentEscalationPolicy.calculateWaitDuration(widget.appointment.createdAt),
                        ),
                        style: AdminTheme.bodyRegular.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.statusCritical,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AdminTheme.space16),

            // Error banner if assignment failed or conflict occurred
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AdminColors.statusCritical.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  border: Border.all(
                    color: AdminColors.statusCritical.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AdminColors.statusCritical,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.statusCritical,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AdminTheme.space12),
            ],

            // Eligible Doctors Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${strings.eligibleDoctorsFound} (${eligibleDoctors.length})',
                  style: AdminTheme.headline2.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.brandNavy,
                  ),
                ),
                Text(
                  'Available Clinicians Only',
                  style: AdminTheme.caption.copyWith(
                    fontSize: 11,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.space10),

            // Eligible Doctors List or Empty State
            if (eligibleDoctors.isEmpty)
              _buildNoEligibleDoctorsState(strings)
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  border: Border.all(color: AdminColors.borderSubtle),
                  borderRadius: BorderRadius.circular(AdminTheme.radius12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: eligibleDoctors.length,
                  separatorBuilder: (ctx, i) =>
                      const Divider(height: 1, color: AdminColors.borderSubtle),
                  itemBuilder: (ctx, i) {
                    final doc = eligibleDoctors[i];
                    final isSelected = _selectedDoctorId == doc.doctorId;

                    return InkWell(
                      onTap: _isCommitting
                          ? null
                          : () {
                              setState(() {
                                _selectedDoctorId = doc.doctorId;
                                _errorMessage = null;
                              });
                            },
                      borderRadius: BorderRadius.circular(AdminTheme.radius12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AdminTheme.space16,
                          vertical: AdminTheme.space12,
                        ),
                        color: isSelected
                            ? AdminColors.brandTeal.withValues(alpha: 0.08)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AdminColors.brandTeal
                                      : AdminColors.borderSubtle,
                                  width: isSelected ? 6 : 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: AdminTheme.space8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.name,
                                    style: AdminTheme.bodyRegular.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AdminColors.brandNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${doc.qualification} • ${doc.department.toUpperCase()} • ID: ${doc.doctorUniqueCode.isNotEmpty ? doc.doctorUniqueCode : doc.doctorId}',
                                    style: AdminTheme.caption.copyWith(
                                      color: AdminColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AdminColors.statusAvailable.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AdminTheme.radius8),
                              ),
                              child: Text(
                                'AVAILABLE',
                                style: AdminTheme.badgeText.copyWith(
                                  color: AdminColors.statusAvailable,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: AdminTheme.space24),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminSecondaryButton(
                  label: strings.cancelButton,
                  onPressed: _isCommitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: AdminTheme.space12),
                AdminPrimaryButton(
                  label: _isCommitting
                      ? strings.assigningButton
                      : strings.confirmAssignmentButton,
                  icon: _isCommitting ? null : Icons.check_circle_outline_rounded,
                  onPressed: (_selectedDoctorId == null || _isCommitting)
                      ? null
                      : _handleAssignmentCommit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoEligibleDoctorsState(dynamic strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminTheme.space24),
      decoration: BoxDecoration(
        color: AdminColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AdminTheme.radius12),
        border: Border.all(color: AdminColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 36,
            color: AdminColors.textMuted,
          ),
          const SizedBox(height: AdminTheme.space12),
          Text(
            strings.noEligibleDoctorsTitle,
            style: AdminTheme.headline2.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AdminColors.brandNavy,
            ),
          ),
          const SizedBox(height: AdminTheme.space4),
          Text(
            strings.noEligibleDoctorsMessage,
            textAlign: TextAlign.center,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAssignmentCommit() async {
    if (_selectedDoctorId == null) return;

    setState(() {
      _isCommitting = true;
      _errorMessage = null;
    });

    final result = await _controller.assignDoctor(
      requestId: widget.appointment.requestId,
      doctorId: _selectedDoctorId!,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Doctor assigned successfully.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AdminColors.brandTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isCommitting = false;
        _errorMessage = result.message ?? 'Assignment could not be completed.';
      });
    }
  }
}
