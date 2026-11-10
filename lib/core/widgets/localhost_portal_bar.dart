import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// Floating Localhost Portal Switcher for Web.
///
/// Enables seamless instant switching between the 4 discrete AAYUSATHI portal
/// interfaces on localhost:
/// - Kiosk Portal:    `/#/kiosk`
/// - Doctor Portal:   `/#/doctor`
/// - Admin Portal:    `/#/admin`
/// - Patient Portal:  `/#/patient`
/// - Hub Gateway:     `/#/hub` (or `/#/`)
class LocalhostPortalBar extends StatefulWidget {
  final Widget child;

  const LocalhostPortalBar({
    super.key,
    required this.child,
  });

  @override
  State<LocalhostPortalBar> createState() => _LocalhostPortalBarState();
}

class _LocalhostPortalBarState extends State<LocalhostPortalBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    String currentRoute = '';
    try {
      currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    } catch (_) {}

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned(
          bottom: 18,
          right: 18,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xE60A1E3F), // Semi-transparent brand navy
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.brandTeal.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: _isExpanded
                  ? _buildExpandedDock(context, currentRoute)
                  : _buildCollapsedPill(currentRoute),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCollapsedPill(String currentRoute) {
    String currentLabel = 'Localhost Hub';
    IconData currentIcon = Icons.hub_rounded;
    Color accentColor = AppColors.brandTeal;

    if (currentRoute.contains('kiosk') || currentRoute == '/' || currentRoute == '/standby') {
      currentLabel = 'Kiosk: /#/kiosk';
      currentIcon = Icons.touch_app_rounded;
      accentColor = AppColors.brandTeal;
    } else if (currentRoute.contains('doctor')) {
      currentLabel = 'Doctor: /#/doctor';
      currentIcon = Icons.medical_services_rounded;
      accentColor = const Color(0xFF6366F1);
    } else if (currentRoute.contains('admin')) {
      currentLabel = 'Admin: /#/admin';
      currentIcon = Icons.admin_panel_settings_rounded;
      accentColor = const Color(0xFF8B5CF6);
    } else if (currentRoute.contains('patient')) {
      currentLabel = 'Patient: /#/patient';
      currentIcon = Icons.person_rounded;
      accentColor = const Color(0xFF10B981);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _isExpanded = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(currentIcon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 8),
            Text(
              currentLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDock(BuildContext context, String currentRoute) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Collapse',
          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
          onPressed: () => setState(() => _isExpanded = false),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        const SizedBox(width: 4),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 8),
        _buildPortalButton(
          context: context,
          icon: Icons.hub_rounded,
          label: 'Hub',
          url: '/#/hub',
          route: AppRoutes.hub,
          color: Colors.white70,
          isActive: currentRoute == AppRoutes.hub || currentRoute == '/',
        ),
        const SizedBox(width: 6),
        _buildPortalButton(
          context: context,
          icon: Icons.touch_app_rounded,
          label: 'Kiosk',
          url: '/#/kiosk',
          route: AppRoutes.kiosk,
          color: AppColors.brandTeal,
          isActive: currentRoute == AppRoutes.kiosk || currentRoute == AppRoutes.standby,
        ),
        const SizedBox(width: 6),
        _buildPortalButton(
          context: context,
          icon: Icons.medical_services_rounded,
          label: 'Doctor',
          url: '/#/doctor',
          route: AppRoutes.doctorHome,
          color: const Color(0xFF6366F1),
          isActive: currentRoute.contains('/doctor'),
        ),
        const SizedBox(width: 6),
        _buildPortalButton(
          context: context,
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
          url: '/#/admin',
          route: AppRoutes.adminHome,
          color: const Color(0xFF8B5CF6),
          isActive: currentRoute.contains('/admin'),
        ),
        const SizedBox(width: 6),
        _buildPortalButton(
          context: context,
          icon: Icons.person_rounded,
          label: 'Patient',
          url: '/#/patient',
          route: AppRoutes.patient,
          color: const Color(0xFF10B981),
          isActive: currentRoute.contains('/patient'),
        ),
      ],
    );
  }

  Widget _buildPortalButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String url,
    required String route,
    required Color color,
    required bool isActive,
  }) {
    return Tooltip(
      message: 'Go to $label Portal ($url)',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _isExpanded = false);
          Navigator.of(context).pushNamed(route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : Colors.white12,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isActive ? Colors.white : color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Tooltip(
                message: 'Copy $url',
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: 'http://localhost:8080$url'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied http://localhost:8080$url to clipboard!'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.copy_rounded, size: 12, color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
