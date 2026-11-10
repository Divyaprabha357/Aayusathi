import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/doctor_profile.dart';
import '../services/doctor_presence_service.dart';
import '../services/doctor_profile_service.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_card.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_status_indicator.dart';

/// Doctor Profile Screen (Phase D4).
///
/// Desktop-first clinical view presenting authorized physician credentials,
/// clinical domain, masked phone, account standing, and active availability.
///
/// STRICT GOVERNANCE MANDATE:
/// Administrative identity fields are strictly READ-ONLY on the clinical workstation.
/// Profile creation and modifications are governed exclusively by Hospital Administration.
class DoctorProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DoctorProfileScreen({super.key, this.onBack});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late Future<DoctorProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    DoctorPresenceService.instance.addListener(_onPresenceChanged);
  }

  void _onPresenceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    DoctorPresenceService.instance.removeListener(_onPresenceChanged);
    super.dispose();
  }

  Future<DoctorProfile> _loadProfile() async {
    final sessionProfile = DoctorSessionService.instance.activeProfile;
    if (sessionProfile != null) {
      return sessionProfile;
    }
    return DoctorProfileService.instance.getDoctorProfile();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.of(context);
    final presence = DoctorPresenceService.instance;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _handleBack();
              return null;
            },
          ),
        },
        child: DoctorDesktopScaffold(
          header: DoctorHeader(
            title: strings.doctorProfileTitle,
            subtitle: strings.hospitalWorkstation,
            onBack: _handleBack,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: DoctorColors.background,
            child: FutureBuilder<DoctorProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: DoctorColors.brandTeal),
                  );
                }

                final profile = snapshot.data ?? MockDoctorProfileService.demoDoctor;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DoctorTheme.space32,
                    vertical: DoctorTheme.space24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Physician Hero Card
                          DoctorCard(
                            padding: const EdgeInsets.all(DoctorTheme.space24),
                            child: Row(
                              children: [
                                // Large Physician Avatar
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: DoctorColors.brandTeal.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: DoctorColors.brandTeal.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    size: 40,
                                    color: DoctorColors.brandTeal,
                                  ),
                                ),
                                const SizedBox(width: DoctorTheme.space24),

                                // Physician Basic Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: DoctorTheme.headline1.copyWith(
                                          fontSize: 22,
                                          color: DoctorColors.brandNavy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: DoctorTheme.space4),
                                      Text(
                                        profile.qualification,
                                        style: DoctorTheme.bodyBold.copyWith(
                                          color: DoctorColors.brandTeal,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        profile.department,
                                        style: DoctorTheme.caption.copyWith(
                                          fontSize: 12,
                                          color: DoctorColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Live Availability Status Badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    DoctorStatusBadge.fromAvailabilityStatus(
                                      presence.status,
                                    ),
                                    const SizedBox(height: DoctorTheme.space8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: DoctorTheme.space8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: profile.isActive
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEE2E2),
                                        borderRadius:
                                            BorderRadius.circular(DoctorTheme.radius6),
                                        border: Border.all(
                                          color: profile.isActive
                                              ? const Color(0xFFA7F3D0)
                                              : const Color(0xFFFCA5A5),
                                        ),
                                      ),
                                      child: Text(
                                        profile.isActive
                                            ? strings.activeStatus
                                            : strings.inactiveStatus,
                                        style: DoctorTheme.badgeText.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: profile.isActive
                                              ? const Color(0xFF065F46)
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DoctorTheme.space20),

                          // 2. Clinical Credentials & Identity Details
                          DoctorCard(
                            padding: const EdgeInsets.all(DoctorTheme.space24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Physician Credentials & Identifiers',
                                  style: DoctorTheme.headline2.copyWith(
                                    color: DoctorColors.brandNavy,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: DoctorTheme.space16),
                                const Divider(height: 1, color: DoctorColors.borderSubtle),
                                const SizedBox(height: DoctorTheme.space16),

                                // Grid of Read-Only Fields
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 600;
                                    return Wrap(
                                      spacing: DoctorTheme.space24,
                                      runSpacing: DoctorTheme.space20,
                                      children: [
                                        _buildDetailItem(
                                          label: strings.doctorUniqueCodeLabel,
                                          value: profile.doctorUniqueCode,
                                          icon: Icons.badge_outlined,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                        ),
                                        _buildDetailItem(
                                          label: strings.departmentLabel,
                                          value: profile.department,
                                          icon: Icons.local_hospital_outlined,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                        ),
                                        _buildDetailItem(
                                          label: strings.qualificationLabel,
                                          value: profile.qualification,
                                          icon: Icons.school_outlined,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                        ),
                                        _buildDetailItem(
                                          label: strings.registeredPhoneLabel,
                                          value: profile.registeredPhone.startsWith('+91******')
                                              ? profile.registeredPhone
                                              : (profile.registeredPhone.startsWith('+91')
                                                  ? '+91${profile.maskedPhone}'
                                                  : profile.maskedPhone),
                                          icon: Icons.phone_outlined,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                        ),
                                        _buildDetailItem(
                                          label: strings.accountStatusLabel,
                                          value: profile.isActive ? strings.activeStatus : strings.inactiveStatus,
                                          icon: Icons.verified_user_outlined,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                          valueColor: profile.isActive ? DoctorColors.statusAvailable : DoctorColors.brandOrange,
                                        ),
                                        _buildDetailItem(
                                          label: 'SECURITY ROLE',
                                          value: 'DOCTOR',
                                          icon: Icons.security_rounded,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                          valueColor: DoctorColors.brandTeal,
                                        ),
                                        _buildDetailItem(
                                          label: strings.availabilityLabel,
                                          value: presence.status.label,
                                          icon: presence.status.icon,
                                          width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 24) / 2,
                                          valueColor: presence.status.color,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DoctorTheme.space20),

                          // 3. Workstation Availability Console
                          _buildAvailabilityConsole(presence, strings),
                          const SizedBox(height: DoctorTheme.space20),

                          // 4. Clinical Workstation Specifications Card
                          _buildWorkstationSpecsCard(strings),
                          const SizedBox(height: DoctorTheme.space20),

                          // 5. Administrative Governance Notice Card
                          Container(
                            padding: const EdgeInsets.all(DoctorTheme.space16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: DoctorColors.brandTeal,
                                  size: 24,
                                ),
                                const SizedBox(width: DoctorTheme.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Profile Managed by Hospital Administration',
                                        style: DoctorTheme.bodyBold.copyWith(
                                          color: DoctorColors.brandNavy,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        strings.profileManagedByAdminNotice,
                                        style: DoctorTheme.caption.copyWith(
                                          color: DoctorColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: DoctorTheme.space24),

                          // 6. Back Navigation Action
                          Align(
                            alignment: Alignment.centerLeft,
                            child: DoctorSecondaryButton(
                              label: 'Back to Dashboard',
                              icon: Icons.arrow_back_rounded,
                              width: 200,
                              onPressed: _handleBack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
    required double width,
    Color? valueColor,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DoctorTheme.space8),
            decoration: BoxDecoration(
              color: DoctorColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              border: Border.all(color: DoctorColors.borderSubtle),
            ),
            child: Icon(icon, size: 18, color: DoctorColors.brandTeal),
          ),
          const SizedBox(width: DoctorTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DoctorTheme.caption.copyWith(
                    color: DoctorColors.textSecondary,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: DoctorTheme.bodyBold.copyWith(
                    color: valueColor ?? DoctorColors.brandNavy,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityConsole(DoctorPresenceService presence, DoctorStrings strings) {
    final isAvailable = presence.isAvailable;
    final isInConsultation = presence.isInConsultation;
    final isOffline = presence.isOffline;

    String statusDescription;
    IconData statusIcon;
    Color statusTone;

    if (isInConsultation) {
      statusDescription = strings.currentlyInConsultation;
      statusIcon = Icons.video_call_rounded;
      statusTone = DoctorColors.statusInConsultation;
    } else if (isAvailable) {
      statusDescription = strings.readyForPatients;
      statusIcon = Icons.check_circle_outline_rounded;
      statusTone = DoctorColors.statusAvailable;
    } else if (isOffline) {
      statusDescription = 'Workstation is offline. Not accepting OPD requests.';
      statusIcon = Icons.power_settings_new_rounded;
      statusTone = DoctorColors.statusOffline;
    } else {
      statusDescription = 'Workstation is online. Ready to accept patient requests.';
      statusIcon = Icons.wifi_rounded;
      statusTone = DoctorColors.statusOnline;
    }

    return DoctorCard(
      title: strings.workstationAvailability,
      subtitle: 'Terminal presence and active OPD queue acceptance console',
      trailing: DoctorStatusBadge.fromAvailabilityStatus(presence.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DoctorTheme.space16),
            decoration: BoxDecoration(
              color: statusTone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
              border: Border.all(color: statusTone.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusTone, size: 28),
                const SizedBox(width: DoctorTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presence.status.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusTone,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDescription,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),
          // Toggle row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorTheme.space16,
              vertical: DoctorTheme.space12,
            ),
            decoration: BoxDecoration(
              color: DoctorColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(DoctorTheme.radius12),
              border: Border.all(color: DoctorColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OPD Patient Acceptance Toggle',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: DoctorColors.brandNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isInConsultation
                            ? 'Locked while consultation is in active progress'
                            : (isAvailable ? 'Currently accepting requests' : 'Workstation marked offline'),
                        style: DoctorTheme.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DoctorTheme.space8),
                Switch(
                  value: isAvailable || isInConsultation,
                  activeThumbColor: DoctorColors.brandTeal,
                  activeTrackColor: DoctorColors.backgroundSecondary,
                  onChanged: isInConsultation
                      ? null
                      : (val) async {
                          if (val) {
                            await presence.setAvailable();
                          } else {
                            await presence.goOffline();
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: DoctorTheme.space16),
          // Go Offline / Go Available button
          SizedBox(
            width: double.infinity,
            child: DoctorOutlineButton(
              label: isAvailable ? strings.goOfflineButton : strings.goOnlineButton,
              icon: isAvailable ? Icons.power_settings_new_rounded : Icons.check_circle_outline_rounded,
              color: isAvailable ? DoctorColors.statusBusy : DoctorColors.brandTeal,
              onPressed: isInConsultation
                  ? null
                  : () async {
                      if (isAvailable) {
                        await presence.goOffline();
                      } else {
                        await presence.setAvailable();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkstationSpecsCard(DoctorStrings strings) {
    return DoctorCard(
      title: 'Clinical Workstation Specifications',
      subtitle: 'Hospital network terminal assignments and governance node',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return Row(
                  children: [
                    _buildSpecItem('HOSPITAL TERMINAL', 'AIIMS-OPD-WS-04'),
                    _buildSpecItem('CLINICAL DEPARTMENT', 'Cardiology / Block B - Room 104'),
                    _buildSpecItem('NETWORK CONNECTION', 'Secure Intranet (AES-256)'),
                    _buildSpecItem('GOVERNANCE', 'Hospital IT Administration'),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildSpecItem('HOSPITAL TERMINAL', 'AIIMS-OPD-WS-04'),
                        _buildSpecItem('CLINICAL DEPARTMENT', 'Cardiology / Block B - Room 104'),
                      ],
                    ),
                    const SizedBox(height: DoctorTheme.space12),
                    Row(
                      children: [
                        _buildSpecItem('NETWORK CONNECTION', 'Secure Intranet (AES-256)'),
                        _buildSpecItem('GOVERNANCE', 'Hospital IT Administration'),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: DoctorColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DoctorColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }
}
