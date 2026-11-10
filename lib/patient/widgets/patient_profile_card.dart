import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/patient_localizations.dart';
import '../theme/patient_colors.dart';

/// Read-only Profile Card for the Patient App (strictly zero Aadhaar exposure).
class PatientProfileCard extends StatelessWidget {
  final String fullName;
  final String patientId;
  final String age;
  final String gender;
  final String bloodGroup;
  final String registeredMobile;

  const PatientProfileCard({
    super.key,
    required this.fullName,
    required this.patientId,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.registeredMobile,
  });

  void _copyPatientId(BuildContext context, String copiedMessage) {
    if (patientId.isNotEmpty && patientId != 'N/A') {
      Clipboard.setData(ClipboardData(text: patientId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(copiedMessage),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PatientColors.tealDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    final attributes = <Widget>[
      _buildAttributeRow(Icons.cake_outlined, strings.profileAge, age.isNotEmpty ? age : '—'),
      const Divider(color: PatientColors.borderSubtle, height: 16),
      _buildAttributeRow(Icons.wc_outlined, strings.profileGender, gender.isNotEmpty ? gender : '—'),
      const Divider(color: PatientColors.borderSubtle, height: 16),
      _buildAttributeRow(Icons.bloodtype_outlined, strings.profileBloodGroup, bloodGroup.isNotEmpty ? bloodGroup : '—'),
      const Divider(color: PatientColors.borderSubtle, height: 16),
      _buildAttributeRow(Icons.phone_android_rounded, strings.profileMobile, registeredMobile.isNotEmpty ? registeredMobile : '—'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PatientColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: PatientColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Avatar & Identity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: PatientColors.tealLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: PatientColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AAYUSATHI Patient',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PatientColors.tealDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: PatientColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _copyPatientId(context, strings.copiedToClipboard),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PatientColors.border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                patientId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: PatientColors.tealDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: PatientColors.tealDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile Attributes Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...attributes,
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: PatientColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.profileReadOnlyNotice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: PatientColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: PatientColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: PatientColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: PatientColors.navy,
          ),
        ),
      ],
    );
  }
}
