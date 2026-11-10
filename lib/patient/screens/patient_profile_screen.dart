import 'package:flutter/material.dart';
import '../controllers/patient_profile_controller.dart';
import '../localization/patient_localizations.dart';
import '../localization/patient_strings.dart';
import '../models/patient_app_state.dart';
import '../services/patient_notification_service.dart';
import '../services/patient_session_service.dart';
import '../theme/patient_colors.dart';
import '../theme/patient_spacing.dart';
import '../widgets/patient_loading_state.dart';
import '../widgets/patient_profile_card.dart';
import '../widgets/patient_top_bar.dart';

/// Senior-accessible Patient Profile Screen shell (`/patient/profile`).
class PatientProfileScreen extends StatefulWidget {
  final PatientProfileController? controller;
  final PatientNotificationService? notificationService;

  const PatientProfileScreen({
    super.key,
    this.controller,
    this.notificationService,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late final PatientProfileController _controller;
  late final PatientNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PatientProfileController();
    _notificationService =
        widget.notificationService ?? PatientNotificationService.instance;
    _controller.loadProfile();
  }

  Future<void> _showLogoutDialog() async {
    final strings = PatientLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.logout),
        content: Text(strings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PatientColors.statusCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final pid = PatientAppState.instance.authenticatedPatientId ?? '';
      await _notificationService.clearPatientSession(pid);
      PatientSessionService.instance.logout();
      PatientAppState.instance.resetSession();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/patient/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return Scaffold(
      backgroundColor: PatientColors.background,
      appBar: PatientTopBar(
        title: strings.profileScreenTitle,
        showBackButton: true,
        showNotificationButton: true,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const PatientLoadingState();
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: PatientSpacing.pageHorizontal,
                  vertical: PatientSpacing.pageTop,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Patient Profile Card
                    PatientProfileCard(
                      fullName: _controller.fullName,
                      patientId: _controller.patientId,
                      age: _controller.age,
                      gender: _controller.gender,
                      bloodGroup: _controller.bloodGroup,
                      registeredMobile: _controller.registeredMobile,
                    ),
                    const SizedBox(height: 16),

                    // 2. Notification Settings Card
                    _buildNotificationSettingsCard(context, strings),
                    const SizedBox(height: 16),

                    // 3. Logout Button
                    OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded,
                          color: PatientColors.statusCritical),
                      label: Text(
                        strings.logout,
                        style: const TextStyle(
                          color: PatientColors.statusCritical,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: PatientColors.statusCritical, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationSettingsCard(
      BuildContext context, PatientStrings strings) {
    return FutureBuilder<bool>(
      future: _notificationService.areRemindersEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PatientColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PatientColors.border, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: PatientColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      size: 22, color: PatientColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.notificationSettings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: PatientColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      strings.notifications,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PatientColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? PatientColors.tealLight
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEnabled ? strings.enabled : strings.disabled,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isEnabled
                            ? PatientColors.tealDark
                            : PatientColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (!isEnabled) {
                        await _notificationService
                            .requestNotificationPermission();
                      } else {
                        await _notificationService
                            .openNotificationSettings();
                      }
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: PatientColors.tealDark,
                      elevation: 0,
                      side: const BorderSide(
                          color: PatientColors.teal, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      strings.notificationSettings,
                      style: const TextStyle(
                        color: PatientColors.tealDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed('/patient/notifications');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PatientColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      strings.viewNotificationCenter,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
