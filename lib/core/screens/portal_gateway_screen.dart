import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// State-of-the-Art Multi-Portal Gateway Screen for Localhost.
///
/// Serves as the central launchpad and directory for all 4 discrete AAYUSATHI
/// interfaces on localhost:
/// 1. Kiosk Portal:    `http://localhost:8080/#/kiosk`   (or Port 8081)
/// 2. Doctor Portal:   `http://localhost:8080/#/doctor`  (or Port 8082)
/// 3. Admin Portal:    `http://localhost:8080/#/admin`   (or Port 8083)
/// 4. Patient Portal:  `http://localhost:8080/#/patient` (or Port 8084)
class PortalGatewayScreen extends StatefulWidget {
  const PortalGatewayScreen({super.key});

  @override
  State<PortalGatewayScreen> createState() => _PortalGatewayScreenState();
}

class _PortalGatewayScreenState extends State<PortalGatewayScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071722),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF0F3244),
              Color(0xFF0A1F2D),
              Color(0xFF05121B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),
                    _buildServerStatusBar(context),
                    const SizedBox(height: 32),
                    _buildPortalGrid(context),
                    const SizedBox(height: 36),
                    _buildMultiPortGuide(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 32,
                color: AppColors.brandTeal,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AAYU',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'SATHI',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandTeal,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Unified Digital Healthcare Ecosystem',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: const Text(
            'Localhost Multi-Interface Command Center • Select Any Portal to Open Directly',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServerStatusBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2433).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF10B981), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Localhost Dev Server Online',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Port 8080',
                  style: TextStyle(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildUrlChip(context, 'Kiosk: /#/kiosk', 'http://localhost:8080/#/kiosk'),
              _buildUrlChip(context, 'Doctor: /#/doctor', 'http://localhost:8080/#/doctor'),
              _buildUrlChip(context, 'Admin: /#/admin', 'http://localhost:8080/#/admin'),
              _buildUrlChip(context, 'Patient: /#/patient', 'http://localhost:8080/#/patient'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrlChip(BuildContext context, String label, String fullUrl) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Clipboard.setData(ClipboardData(text: fullUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $fullUrl to clipboard!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.copy_rounded, size: 12, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cardWidth = isWide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildPortalCard(
                context: context,
                title: 'Patient Kiosk Terminal',
                subtitle: 'Self-Service Touchscreen Intake Station',
                icon: Icons.touch_app_rounded,
                accentColor: AppColors.brandTeal,
                badgeText: 'Touchscreen Interface',
                localhostUrl: 'http://localhost:8080/#/kiosk',
                routePath: AppRoutes.kiosk,
                description:
                    'Complete patient kiosk terminal: Language selection, Aadhaar biometric verification, hardware vitals capture, OPD domain selection, doctor preference, and token queue slip generation.',
                quickLinks: [
                  _QuickLink('Standby / Welcome', AppRoutes.kiosk),
                  _QuickLink('Vitals Measurement', AppRoutes.vitals),
                  _QuickLink('New Aadhaar Input', AppRoutes.newUser),
                  _QuickLink('Existing Patient', AppRoutes.existingPatient),
                  _QuickLink('Department Selection', AppRoutes.domainSelection),
                ],
                portRecommendation: 'Port 8081',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildPortalCard(
                context: context,
                title: 'Doctor Clinical Workspace',
                subtitle: 'Physician OPD Consultation Dashboard',
                icon: Icons.medical_services_rounded,
                accentColor: const Color(0xFF6366F1),
                badgeText: 'Clinician Interface',
                localhostUrl: 'http://localhost:8080/#/doctor',
                routePath: AppRoutes.doctorHome,
                description:
                    'Clinical OPD portal: Real-time patient queue, live vital telemetry timeline, AI Whisper speech-to-text dictation, digital prescription (Rx) builder, and automated PDF visit summary generation.',
                credentialsHint: 'Login: DOC-101 | Password: any | OTP: 123456',
                quickLinks: [
                  _QuickLink('Doctor Login', AppRoutes.doctorLogin),
                  _QuickLink('OPD Dashboard', AppRoutes.doctorDashboard),
                  _QuickLink('Patient Workspace', AppRoutes.doctorPatientWorkspace),
                  _QuickLink('Reports & Prescriptions', AppRoutes.doctorReports),
                ],
                portRecommendation: 'Port 8082',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildPortalCard(
                context: context,
                title: 'Hospital Admin Portal',
                subtitle: 'Administrative Command & Roster Operations',
                icon: Icons.admin_panel_settings_rounded,
                accentColor: const Color(0xFF8B5CF6),
                badgeText: 'Administration Interface',
                localhostUrl: 'http://localhost:8080/#/admin',
                routePath: AppRoutes.adminHome,
                description:
                    'Hospital operations suite: Live patient flow analytics, department availability matrix, doctor roster & provisioning, appointment escalations, and high-priority case interventions.',
                credentialsHint: 'Username: admin01 | Password: aayusathi1226',
                quickLinks: [
                  _QuickLink('Admin Login', AppRoutes.adminLogin),
                  _QuickLink('Admin Dashboard', AppRoutes.adminDashboard),
                  _QuickLink('Doctor Directory', AppRoutes.adminDoctors),
                  _QuickLink('Availability Matrix', AppRoutes.adminAvailability),
                  _QuickLink('Case Escalations', AppRoutes.adminCaseEscalations),
                ],
                portRecommendation: 'Port 8083',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildPortalCard(
                context: context,
                title: 'Patient Health Portal',
                subtitle: 'Personal Health Records & Diagnostic Timeline',
                icon: Icons.person_rounded,
                accentColor: const Color(0xFF10B981),
                badgeText: 'Patient Portal',
                localhostUrl: 'http://localhost:8080/#/patient',
                routePath: AppRoutes.patient,
                description:
                    'Patient health companion: Secure mobile OTP authentication, comprehensive visit history, downloadable diagnostic reports, medication reminders calendar, and family medical profile.',
                credentialsHint: 'Patient ID: AAYU-102938 | OTP: 123456',
                quickLinks: [
                  _QuickLink('Patient Login', AppRoutes.patientLogin),
                  _QuickLink('Health Dashboard', AppRoutes.patientDashboard),
                  _QuickLink('Clinical Cases', AppRoutes.patientCases),
                  _QuickLink('Diagnostic Reports', AppRoutes.patientReports),
                  _QuickLink('Follow-up Calendar', AppRoutes.patientCalendar),
                ],
                portRecommendation: 'Port 8084',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required String localhostUrl,
    required String routePath,
    required String description,
    required List<_QuickLink> quickLinks,
    required String portRecommendation,
    String? credentialsHint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C2433).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Direct URL Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: Colors.white60),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localhostUrl,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Copy URL',
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: localhostUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $localhostUrl to clipboard!'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (credentialsHint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_rounded, size: 14, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Text(
                    credentialsHint,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Quick Interfaces Sub-links
          const Text(
            'KEY INTERFACES:',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickLinks.map((link) {
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pushNamed(link.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 12, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        link.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Primary Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(routePath),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.launch_rounded, size: 18),
              label: Text(
                'Open $title ($localhostUrl)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiPortGuide(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF081C28).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.terminal_rounded, size: 22, color: AppColors.brandOrange),
              SizedBox(width: 10),
              Text(
                'Multi-Port Independent Localhost Hosting',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'To run each portal on its own independent port simultaneously in separate browser windows/terminals:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          _buildPortRow('Port 8081', 'Kiosk', 'flutter run -d web-server --web-port=8081 --dart-define=INITIAL_ROUTE=/kiosk'),
          _buildPortRow('Port 8082', 'Doctor', 'flutter run -d web-server --web-port=8082 --dart-define=INITIAL_ROUTE=/doctor'),
          _buildPortRow('Port 8083', 'Admin', 'flutter run -d web-server --web-port=8083 --dart-define=INITIAL_ROUTE=/admin'),
          _buildPortRow('Port 8084', 'Patient', 'flutter run -d web-server --web-port=8084 --dart-define=INITIAL_ROUTE=/patient'),
        ],
      ),
    );
  }

  Widget _buildPortRow(String port, String portal, String command) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              port,
              style: const TextStyle(
                color: AppColors.brandOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              portal,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                command,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLink {
  final String label;
  final String route;
  const _QuickLink(this.label, this.route);
}
