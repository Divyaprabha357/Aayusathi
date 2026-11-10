import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_assets.dart';
import '../localization/patient_localizations.dart';
import '../models/patient_app_state.dart';
import '../services/patient_notification_service.dart';
import '../theme/patient_colors.dart';

/// Top App Bar for the Patient App with official AAYUSATHI branding.
///
/// Displays:
/// - Left: Official approved AAYUSATHI logo asset with tagline
/// - Center/Left: Screen title (if specified when navigated to sub-screen)
/// - Right: Notification bell icon with unread badge and Profile icon button
class PatientTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showNotificationButton;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onBackTap;

  const PatientTopBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.showNotificationButton = true,
    this.onProfileTap,
    this.onNotificationTap,
    this.onBackTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final strings = PatientLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: PatientColors.surface,
          border: Border(
            bottom: BorderSide(color: PatientColors.border, width: 1.5),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: preferredSize.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  if (showBackButton) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 26, color: PatientColors.navy),
                    tooltip: strings.back,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: EdgeInsets.zero,
                    onPressed: onBackTap ?? () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 6),
                ],

                // Official Logo or Title
                Expanded(
                  child: title != null && showBackButton
                      ? Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: PatientColors.navy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 38, maxWidth: 180),
                            child: Image.asset(
                              AppAssets.logo,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                              errorBuilder: (context, error, stackTrace) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'AAYU',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: PatientColors.navy,
                                      ),
                                    ),
                                    const Text(
                                      'SATHI',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: PatientColors.teal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),

                // Notification Bell Button
                if (showNotificationButton) ...[
                  ListenableBuilder(
                    listenable: PatientNotificationService.instance,
                    builder: (context, _) {
                      final pid = PatientAppState.instance.authenticatedPatientId ?? 'CURRENT_PATIENT';
                      final unreadCount = PatientNotificationService.instance.getUnreadCount(pid);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onNotificationTap ??
                              () {
                                Navigator.of(context).pushNamed('/patient/notifications');
                              },
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: PatientColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: PatientColors.border, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: PatientColors.navy,
                                  size: 22,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: PatientColors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Profile Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onProfileTap ??
                        () {
                          Navigator.of(context).pushNamed('/patient/profile');
                        },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PatientColors.tealLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: PatientColors.border, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: PatientColors.teal,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
