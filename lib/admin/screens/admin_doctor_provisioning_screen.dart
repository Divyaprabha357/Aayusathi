import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes/app_routes.dart';
import '../../models/opd_domain.dart';
import '../controllers/admin_doctor_controller.dart';
import '../controllers/admin_sidebar_controller.dart';
import '../localization/admin_localizations.dart';
import '../models/admin_domain_availability.dart';
import '../models/admin_navigation_item.dart';
import '../services/admin_auth_service.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_card.dart';
import '../widgets/admin_desktop_scaffold.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';

/// Administrative Doctor Provisioning Screen (Phase A4 / A5).
///
/// Route: `/admin/doctors/add`
/// Displays the physician account provisioning form and temporary credential issuance.
class AdminDoctorProvisioningScreen extends StatefulWidget {
  const AdminDoctorProvisioningScreen({super.key});

  @override
  State<AdminDoctorProvisioningScreen> createState() => _AdminDoctorProvisioningScreenState();
}

class _AdminDoctorProvisioningScreenState extends State<AdminDoctorProvisioningScreen> {
  final AdminDoctorController _controller = AdminDoctorController.instance;

  late final TextEditingController _nameTextController;
  late final TextEditingController _phoneTextController;
  late final TextEditingController _qualificationTextController;
  late final TextEditingController _emailTextController;

  final List<AdminNavigationItem> _navItems = const [
    AdminNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      routeName: AppRoutes.adminDashboard,
    ),
    AdminNavigationItem(
      id: 'doctors',
      label: 'Doctors',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      routeName: AppRoutes.adminDoctors,
    ),
    AdminNavigationItem(
      id: 'availability',
      label: 'Availability',
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available_rounded,
      routeName: AppRoutes.adminAvailability,
    ),
    AdminNavigationItem(
      id: 'appointment_escalations',
      label: 'Appointment Escalations',
      icon: Icons.notification_important_outlined,
      selectedIcon: Icons.notification_important_rounded,
      routeName: AppRoutes.adminAppointmentEscalations,
    ),
    AdminNavigationItem(
      id: 'case_escalations',
      label: 'Case Escalations',
      icon: Icons.warning_amber_rounded,
      selectedIcon: Icons.warning_rounded,
      routeName: AppRoutes.adminCaseEscalations,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!AdminAuthService.instance.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminLogin);
        }
      });
      return;
    }

    _nameTextController = TextEditingController(text: _controller.name);
    _phoneTextController = TextEditingController(text: _controller.mobile);
    _qualificationTextController = TextEditingController(text: _controller.qualification);
    _emailTextController = TextEditingController(text: _controller.email);

    AdminSidebarController.instance.addListener(_onStateChanged);
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AdminSidebarController.instance.removeListener(_onStateChanged);
    _controller.removeListener(_onStateChanged);
    _nameTextController.dispose();
    _phoneTextController.dispose();
    _qualificationTextController.dispose();
    _emailTextController.dispose();
    _controller.clearPassword();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onNavigationSelected(AdminNavigationItem item) {
    _controller.clearPassword();
    Navigator.of(context).pushReplacementNamed(item.routeName);
  }

  Future<void> _handleLogout() async {
    _controller.clearPassword();
    await AdminAuthService.instance.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.adminStandby,
        (route) => false,
      );
    }
  }

  void _handleBackToDoctors() {
    _controller.clearPassword();
    Navigator.of(context).pushReplacementNamed(AppRoutes.adminDoctors);
  }

  Future<void> _handleProvisionDoctor() async {
    final success = await _controller.submitProvisioning();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor account provisioned successfully.'),
          backgroundColor: AdminColors.statusAvailable,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleCopy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard.'),
        backgroundColor: AdminColors.brandNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAddAnotherDoctor() {
    _controller.resetForm();
    _nameTextController.clear();
    _phoneTextController.clear();
    _qualificationTextController.clear();
    _emailTextController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AdminLocalizations.of(context);

    return AdminDesktopScaffold(
      header: AdminHeader(
        title: strings.addNewDoctorTitle,
        subtitle: strings.addNewDoctorSubtitle,
        adminName: AdminAuthService.instance.currentSession?.username ?? 'admin01',
        onLogout: _handleLogout,
      ),
      sidebar: AdminSidebar(
        items: _navItems,
        activeRoute: AppRoutes.adminDoctors,
        isCollapsed: AdminSidebarController.instance.isCollapsed,
        onToggleCollapse: AdminSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _handleBackToDoctors,
                  borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: AdminColors.brandTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Manage Doctors',
                          style: AdminTheme.buttonText.copyWith(
                            color: AdminColors.brandTeal,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AdminColors.brandNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AdminTheme.radius8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 14,
                        color: AdminColors.brandNavy,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ADMIN-PROVISIONED ONLY',
                        style: AdminTheme.badgeText.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.brandNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminTheme.space20),

            // Form Content or Success Screen
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _controller.isSuccess
                    ? _buildSuccessView(strings)
                    : _buildFormView(strings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // DOCTOR PROVISIONING FORM VIEW
  // =========================================================================
  Widget _buildFormView(dynamic strings) {
    return AdminCard(
      title: strings.doctorInformationSection,
      subtitle: 'Enter certified physician credentials for account generation.',
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AdminColors.brandTeal.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_add_alt_1_rounded,
          color: AdminColors.brandTeal,
          size: 20,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_controller.generalError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AdminTheme.space12),
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
                    color: AdminColors.statusCritical,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _controller.generalError!,
                      style: AdminTheme.caption.copyWith(
                        color: AdminColors.statusCritical,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AdminTheme.space16),
          ],

          // 1. Full Name Field
          _buildFieldHeader(strings.fullNameLabel, isRequired: true),
          const SizedBox(height: AdminTheme.space8),
          TextField(
            controller: _nameTextController,
            enabled: !_controller.isProvisioning,
            onChanged: _controller.setName,
            style: AdminTheme.bodyRegular.copyWith(color: AdminColors.textPrimary),
            decoration: _inputDecoration(
              hintText: strings.fullNamePlaceholder,
              icon: Icons.person_outline_rounded,
              errorText: _controller.nameError,
            ),
          ),
          const SizedBox(height: AdminTheme.space20),

          // 2. Registered Mobile Number Field
          _buildFieldHeader(strings.registeredPhoneLabel, isRequired: true),
          const SizedBox(height: AdminTheme.space8),
          TextField(
            controller: _phoneTextController,
            enabled: !_controller.isProvisioning,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: _controller.setMobile,
            style: AdminTheme.bodyRegular.copyWith(color: AdminColors.textPrimary),
            decoration: _inputDecoration(
              hintText: strings.registeredPhonePlaceholder,
              icon: Icons.phone_outlined,
              prefixText: '+91 ',
              counterText: '',
              errorText: _controller.mobileError,
            ),
          ),
          const SizedBox(height: AdminTheme.space20),

          // 3. Qualification / Degree Field
          _buildFieldHeader(strings.qualificationLabel, isRequired: true),
          const SizedBox(height: AdminTheme.space8),
          TextField(
            controller: _qualificationTextController,
            enabled: !_controller.isProvisioning,
            onChanged: _controller.setQualification,
            style: AdminTheme.bodyRegular.copyWith(color: AdminColors.textPrimary),
            decoration: _inputDecoration(
              hintText: strings.qualificationPlaceholder,
              icon: Icons.school_outlined,
              errorText: _controller.qualificationError,
            ),
          ),
          const SizedBox(height: AdminTheme.space20),

          // 4. Department / Domain Dropdown Selector
          _buildFieldHeader(strings.departmentLabel, isRequired: true),
          const SizedBox(height: AdminTheme.space8),
          _buildDepartmentDropdown(strings),
          if (_controller.departmentError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _controller.departmentError!,
                style: AdminTheme.caption.copyWith(
                  color: AdminColors.statusCritical,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: AdminTheme.space20),

          // 5. Optional Email Field
          _buildFieldHeader(strings.optionalEmailLabel, isRequired: false),
          const SizedBox(height: AdminTheme.space8),
          TextField(
            controller: _emailTextController,
            enabled: !_controller.isProvisioning,
            keyboardType: TextInputType.emailAddress,
            onChanged: _controller.setEmail,
            style: AdminTheme.bodyRegular.copyWith(color: AdminColors.textPrimary),
            decoration: _inputDecoration(
              hintText: strings.optionalEmailPlaceholder,
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: AdminTheme.space24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: AdminPrimaryButton(
              label: _controller.isProvisioning
                  ? strings.creatingDoctorButton
                  : strings.createDoctorButton,
              icon: _controller.isProvisioning ? null : Icons.check_circle_outline_rounded,
              isLoading: _controller.isProvisioning,
              onPressed: _controller.isProvisioning ? null : _handleProvisionDoctor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHeader(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: AdminTheme.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AdminColors.brandNavy,
            letterSpacing: 0.5,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AdminColors.statusCritical,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      prefixStyle: AdminTheme.bodyRegular.copyWith(
        color: AdminColors.brandNavy,
        fontWeight: FontWeight.w600,
      ),
      counterText: counterText,
      errorText: errorText,
      errorStyle: AdminTheme.caption.copyWith(color: AdminColors.statusCritical),
      prefixIcon: Icon(icon, size: 20, color: AdminColors.brandTeal),
      filled: true,
      fillColor: AdminColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminTheme.radius10),
        borderSide: const BorderSide(color: AdminColors.statusCritical),
      ),
    );
  }

  Widget _buildDepartmentDropdown(dynamic strings) {
    final domains = AdminDomainAvailability.standardDomains;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius10),
        border: Border.all(
          color: _controller.departmentError != null
              ? AdminColors.statusCritical
              : AdminColors.borderSubtle,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _controller.department.isNotEmpty ? _controller.department : null,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 20,
                color: AdminColors.brandTeal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.selectDepartmentHint,
                  style: AdminTheme.bodyRegular.copyWith(
                    color: AdminColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: AdminTheme.bodyRegular.copyWith(
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _controller.isProvisioning
              ? null
              : (val) {
                  if (val != null) {
                    _controller.setDepartment(val);
                  }
                },
        ),
      ),
    );
  }

  // =========================================================================
  // PROVISIONING SUCCESS VIEW
  // =========================================================================
  Widget _buildSuccessView(dynamic strings) {
    final doctor = _controller.provisionedDoctor;
    final password = _controller.temporaryPassword ?? '';
    final domainName = AdminDomainAvailability.standardDomains.firstWhere(
      (d) => d['id'] == doctor?.department,
      orElse: () => {'name': doctor?.department ?? ''},
    )['name'];

    return Container(
      padding: const EdgeInsets.all(AdminTheme.space32),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.statusAvailable.withValues(alpha: 0.4)),
        boxShadow: AdminTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AdminColors.statusAvailable.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AdminColors.statusAvailable,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: AdminTheme.space16),
          Text(
            strings.doctorCreatedTitle,
            style: AdminTheme.headline1.copyWith(
              color: AdminColors.brandNavy,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AdminTheme.space6),
          Text(
            strings.doctorCreatedSubtitle,
            style: AdminTheme.caption.copyWith(
              color: AdminColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AdminTheme.space24),

          Container(
            padding: const EdgeInsets.all(AdminTheme.space20),
            decoration: BoxDecoration(
              color: AdminColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AdminTheme.radius12),
              border: Border.all(color: AdminColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Doctor Name', doctor?.name ?? '—', isBold: true),
                const Divider(height: 20, color: AdminColors.borderSubtle),
                _buildSummaryRow('Doctor ID', doctor?.doctorUniqueCode ?? '—', isHighlight: true),
                const Divider(height: 20, color: AdminColors.borderSubtle),
                _buildSummaryRow('Department', domainName ?? '—'),
                const Divider(height: 20, color: AdminColors.borderSubtle),
                _buildSummaryRow('Qualification', doctor?.qualification ?? '—'),
                const Divider(height: 20, color: AdminColors.borderSubtle),
                _buildSummaryRow('Registered Mobile', doctor?.maskedPhone ?? '******'),
                const Divider(height: 20, color: AdminColors.borderSubtle),
                _buildSummaryRow(
                  strings.generatedPasswordLabel,
                  password,
                  isPassword: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminTheme.space20),

          Container(
            padding: const EdgeInsets.all(AdminTheme.space14),
            decoration: BoxDecoration(
              color: AdminColors.brandOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AdminTheme.radius10),
              border: Border.all(
                color: AdminColors.brandOrange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  color: AdminColors.brandOrange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.savePasswordWarning,
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
          const SizedBox(height: AdminTheme.space24),

          Row(
            children: [
              Expanded(
                child: AdminSecondaryButton(
                  label: strings.copyDoctorIdButton,
                  icon: Icons.copy_rounded,
                  onPressed: () => _handleCopy(doctor?.doctorUniqueCode ?? '', 'Doctor ID'),
                ),
              ),
              const SizedBox(width: AdminTheme.space16),
              Expanded(
                child: AdminSecondaryButton(
                  label: strings.copyPasswordButton,
                  icon: Icons.key_rounded,
                  onPressed: () => _handleCopy(password, 'Temporary Password'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminTheme.space16),

          Row(
            children: [
              Expanded(
                child: AdminSecondaryButton(
                  label: strings.addAnotherDoctorButton,
                  icon: Icons.person_add_rounded,
                  onPressed: _handleAddAnotherDoctor,
                ),
              ),
              const SizedBox(width: AdminTheme.space16),
              Expanded(
                child: AdminPrimaryButton(
                  label: strings.doneButton,
                  icon: Icons.check_rounded,
                  onPressed: _handleBackToDoctors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
    bool isPassword = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AdminTheme.caption.copyWith(
            color: AdminColors.textSecondary,
            fontSize: 13,
          ),
        ),
        if (isHighlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.brandTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AdminTheme.radius6),
              border: Border.all(color: AdminColors.brandTeal.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: AdminTheme.headline2.copyWith(
                color: AdminColors.brandTeal,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          )
        else if (isPassword)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.brandOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AdminTheme.radius6),
              border: Border.all(color: AdminColors.brandOrange.withValues(alpha: 0.4)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AdminColors.brandOrange,
                letterSpacing: 1.0,
              ),
            ),
          )
        else
          Text(
            value,
            style: AdminTheme.bodyRegular.copyWith(
              color: AdminColors.textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
