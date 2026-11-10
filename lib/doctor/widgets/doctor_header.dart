import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/date_utils.dart';
import '../models/doctor_profile.dart';
import '../models/doctor_ui_status.dart';
import '../services/doctor_presence_service.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import 'doctor_profile_area.dart';
import 'doctor_status_indicator.dart';

/// Reusable Doctor Desktop Header.
/// Concept:
/// LEFT: AAYUSATHI logo & branding
/// CENTER: Current page title
/// RIGHT: Online/Offline status & Doctor profile area
class DoctorHeader extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final DoctorOnlineStatus onlineStatus;
  final DoctorWorkStatus workStatus;
  final DoctorAvailabilityStatus? availabilityStatus;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;
  final VoidCallback? onToggleAvailability;
  final String? doctorName;
  final String? doctorQualification;
  final String? doctorDepartment;

  const DoctorHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onlineStatus = DoctorOnlineStatus.online,
    this.workStatus = DoctorWorkStatus.available,
    this.availabilityStatus,
    this.onLogout,
    this.onProfileTap,
    this.onToggleAvailability,
    this.doctorName,
    this.doctorQualification,
    this.doctorDepartment,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  State<DoctorHeader> createState() => _DoctorHeaderState();
}

class _DoctorHeaderState extends State<DoctorHeader> {
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final presence = DoctorPresenceService.instance;
    final currentStatus = widget.availabilityStatus ?? presence.status;
    final session = DoctorSessionService.instance;

    final effectiveName = widget.doctorName ??
        session.activeDoctorName ??
        session.activeProfile?.name ??
        'Dr. Rajesh Sharma';

    final effectiveQualification = widget.doctorQualification ??
        session.activeProfile?.qualification ??
        'MBBS, MD (Cardiology)';

    final effectiveDepartment = widget.doctorDepartment ??
        session.activeDepartment ??
        session.activeProfile?.department ??
        'Cardiology';

    return Container(
      height: widget.preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        border: const Border(
          bottom: BorderSide(color: DoctorColors.border, width: 1),
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1100;
          final isVeryCompact = constraints.maxWidth < 920;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: AAYUSATHI Logo & Clinical Branding
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onBack != null) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Go back',
                      color: DoctorColors.brandNavy,
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: DoctorTheme.space8),
                  ],
                  Image.asset(
                    AppAssets.logo,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: DoctorColors.brandTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AAYUSATHI',
                          style: DoctorTheme.headline2.copyWith(
                            color: DoctorColors.brandNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isVeryCompact) ...[
                    const SizedBox(width: DoctorTheme.space12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DoctorTheme.space8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DoctorColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                        border: Border.all(
                          color: DoctorColors.brandTeal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'DOCTOR PORTAL',
                        style: DoctorTheme.badgeText.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: DoctorColors.brandTeal,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // CENTER: Current Page Title
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DoctorTheme.space12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: DoctorTheme.headline2.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isVeryCompact ? 15 : 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null && !isVeryCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: DoctorTheme.caption.copyWith(
                            color: DoctorColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // RIGHT: Live Clock, Status Indicator & Doctor Profile Area
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Presence Availability / Online Badge (hidden on narrow screens to prevent overflow)
                  if (!isVeryCompact) ...[
                    widget.availabilityStatus != null
                        ? DoctorStatusBadge.fromAvailabilityStatus(
                            currentStatus,
                            onTap: () async {
                              if (presence.isAvailable) {
                                await presence.goOffline();
                              } else {
                                await presence.setAvailable();
                              }
                            },
                          )
                        : DoctorStatusBadge.fromOnlineStatus(widget.onlineStatus),
                    const SizedBox(width: DoctorTheme.space12),
                  ],

                  if (!isCompact) ...[
                    // Live Digital Clock (isolated stateful widget to prevent header rebuilds)
                    const _DoctorLiveClock(),
                  ],
                  const SizedBox(width: DoctorTheme.space12),

                  // Doctor Profile Menu Area
                  DoctorProfileArea(
                    title: effectiveName,
                    qualification: effectiveQualification,
                    department: effectiveDepartment,
                    availabilityStatus: currentStatus,
                    workStatus: widget.workStatus,
                    onLogoutTap: widget.onLogout,
                    onProfileTap: widget.onProfileTap ??
                        () => Navigator.of(context).pushNamed(AppRoutes.doctorProfile),
                    onToggleAvailability: widget.onToggleAvailability ??
                        () async {
                          if (presence.isAvailable) {
                            await presence.goOffline();
                          } else {
                            await presence.setAvailable();
                          }
                        },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Isolated digital clock widget that ticks every 1 second without triggering
/// full-screen or header widget tree rebuilds.
class _DoctorLiveClock extends StatefulWidget {
  const _DoctorLiveClock();

  @override
  State<_DoctorLiveClock> createState() => _DoctorLiveClockState();
}

class _DoctorLiveClockState extends State<_DoctorLiveClock> {
  late DateTime _currentTime;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorTheme.space12,
        vertical: DoctorTheme.space6,
      ),
      decoration: BoxDecoration(
        color: DoctorColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(DoctorTheme.radius8),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: DoctorColors.brandTeal,
          ),
          const SizedBox(width: 6),
          Text(
            AppDateUtils.formatTime(_currentTime),
            style: DoctorTheme.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: DoctorColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }
}
