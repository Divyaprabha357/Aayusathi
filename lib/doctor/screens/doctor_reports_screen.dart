import 'package:flutter/material.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/doctor_navigation_item.dart';
import '../models/investigation_request.dart';
import '../models/report_document.dart';
import '../services/doctor_session_service.dart';
import '../services/pdf_output_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_report_viewer_dialog.dart';
import '../widgets/doctor_sidebar.dart';
import '../widgets/doctor_state_views.dart';

/// Full standalone screen for Doctor Diagnostic Reports & Investigations Desk (Phase D15).
class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  final KioskLocale _locale = KioskLocale.english;
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedTab = 0; // 0: Requested, 1: Uploaded (Pending), 2: Reviewed, 3: Visit Reports
  String _searchQuery = '';
  late final TextEditingController _searchController;

  List<InvestigationRequest> _allInvestigations = [];
  List<ReportDocument> _allReportDocuments = [];

  final List<DoctorNavigationItem> _navItems = const [
    DoctorNavigationItem(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      routeName: AppRoutes.doctorDashboard,
    ),
    DoctorNavigationItem(
      id: 'patient_requests',
      label: 'Patient Requests',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      routeName: AppRoutes.doctorPatientRequest,
    ),
    DoctorNavigationItem(
      id: 'patient_workspace',
      label: 'Patient Workspace',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
      routeName: AppRoutes.doctorPatientWorkspace,
    ),
    DoctorNavigationItem(
      id: 'consultation',
      label: 'Consultation',
      icon: Icons.video_camera_front_outlined,
      selectedIcon: Icons.video_camera_front_rounded,
      routeName: AppRoutes.doctorConsultation,
    ),
    DoctorNavigationItem(
      id: 'cases',
      label: 'Cases & Visits',
      icon: Icons.folder_open_rounded,
      selectedIcon: Icons.folder_rounded,
      routeName: AppRoutes.doctorCase,
    ),
    DoctorNavigationItem(
      id: 'reports',
      label: 'Reports & Diagnostics',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      routeName: AppRoutes.doctorReports,
    ),
  ];

  @override
  void initState() {
    super.initState();
    DoctorSidebarController.instance.addListener(_onSidebarChanged);
    _searchController = TextEditingController();
    _loadReportsData();
  }

  @override
  void dispose() {
    DoctorSidebarController.instance.removeListener(_onSidebarChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSidebarChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReportsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invRepo = BackendProvider.instance.investigationRepository;
      final repRepo = BackendProvider.instance.reportRepository;

      // In mock/development mode, seed default records for PAT-001 / CASE-001 / VIS-CASE-001-1
      final invs = await invRepo.getInvestigationRequests(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );
      final docs = await repRepo.getReportsForVisit(
        patientId: 'PAT-001',
        caseId: 'CASE-001',
        visitId: 'VIS-CASE-001-1',
      );

      if (mounted) {
        setState(() {
          _allInvestigations = invs;
          _allReportDocuments = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onNavigationSelected(DoctorNavigationItem item) {
    if (item.routeName != AppRoutes.doctorReports) {
      Navigator.of(context).pushReplacementNamed(item.routeName);
    }
  }

  Future<void> _markDocumentReviewed(ReportDocument doc) async {
    final doctorId = DoctorSessionService.instance.activeDoctorId ?? 'DOC-101';
    try {
      await BackendProvider.instance.reportRepository.updateReportStatus(
        patientId: doc.patientId,
        caseId: doc.caseId,
        visitId: doc.visitId,
        reportId: doc.reportId,
        status: ReportReviewStatus.reviewed,
        doctorId: doctorId,
      );

      await BackendProvider.instance.investigationRepository.markReviewed(
        patientId: doc.patientId,
        caseId: doc.caseId,
        visitId: doc.visitId,
        investigationId: doc.investigationId,
        doctorId: doctorId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report marked as reviewed successfully.'),
            backgroundColor: DoctorColors.brandTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await _loadReportsData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report status: $e'),
            backgroundColor: DoctorColors.brandOrange,
          ),
        );
      }
    }
  }

  Future<void> _openPdf(String fileName) async {
    final pdfService = PdfOutputService.instance;
    await pdfService.openPdf(fileName);
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(_locale);

    final requestedList = _allInvestigations
        .where((inv) => inv.status == InvestigationStatus.pendingUpload)
        .where((inv) => _matchesSearch(inv.name, inv.patientId ?? ''))
        .toList();

    final uploadedList = _allReportDocuments
        .where((doc) => doc.reviewStatus == ReportReviewStatus.uploaded)
        .where((doc) => _matchesSearch(doc.fileName, doc.patientId))
        .toList();

    final reviewedList = _allReportDocuments
        .where((doc) => doc.reviewStatus == ReportReviewStatus.reviewed)
        .where((doc) => _matchesSearch(doc.fileName, doc.patientId))
        .toList();

    return DoctorDesktopScaffold(
      header: DoctorHeader(
        title: strings.reportsAndDiagnosticsTitle,
        subtitle: strings.reportsAndDiagnosticsSubtitle,
        onBack: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard),
        onLogout: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorStandby),
      ),
      sidebar: DoctorSidebar(
        items: _navItems,
        activeRoute: AppRoutes.doctorReports,
        isCollapsed: DoctorSidebarController.instance.isCollapsed,
        onToggleCollapse: DoctorSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: _isLoading
          ? const Center(child: DoctorLoadingView())
          : _errorMessage != null
              ? DoctorErrorView(
                  title: strings.errorTitle,
                  message: _errorMessage!,
                  onRetry: _loadReportsData,
                )
              : Container(
                  padding: const EdgeInsets.all(DoctorTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Tabs & Search
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTab(
                                    index: 0,
                                    label: '${strings.tabRequested} (${requestedList.length})',
                                    icon: Icons.pending_actions_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTab(
                                    index: 1,
                                    label:
                                        '${strings.tabUploaded} (${uploadedList.length})',
                                    icon: Icons.upload_file_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTab(
                                    index: 2,
                                    label: '${strings.tabReviewed} (${reviewedList.length})',
                                    icon: Icons.task_alt_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTab(
                                    index: 3,
                                    label: strings.tabVisitReports,
                                    icon: Icons.picture_as_pdf_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Search Bar
                          SizedBox(
                            width: 280,
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              style: DoctorTheme.bodyRegular.copyWith(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: strings.searchReportsHint,
                                hintStyle: DoctorTheme.bodyMuted.copyWith(fontSize: 12),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: DoctorColors.textMuted,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 16),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: DoctorColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius8),
                                  borderSide:
                                      const BorderSide(color: DoctorColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(DoctorTheme.radius8),
                                  borderSide: const BorderSide(
                                    color: DoctorColors.brandTeal,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DoctorTheme.space20),

                      // Tab Content
                      Expanded(
                        child: _buildActiveTabContent(
                          strings: strings,
                          requested: requestedList,
                          uploaded: uploadedList,
                          reviewed: reviewedList,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  bool _matchesSearch(String name, String patientId) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return name.toLowerCase().contains(q) || patientId.toLowerCase().contains(q);
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(DoctorTheme.radius8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DoctorColors.brandTeal.withValues(alpha: 0.12)
              : DoctorColors.surface,
          borderRadius: BorderRadius.circular(DoctorTheme.radius8),
          border: Border.all(
            color: isSelected ? DoctorColors.brandTeal : DoctorColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? DoctorColors.brandTeal : DoctorColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: DoctorTheme.caption.copyWith(
                color: isSelected ? DoctorColors.brandTeal : DoctorColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent({
    required DoctorStrings strings,
    required List<InvestigationRequest> requested,
    required List<ReportDocument> uploaded,
    required List<ReportDocument> reviewed,
  }) {
    switch (_selectedTab) {
      case 0: // Requested
        if (requested.isEmpty) {
          return DoctorEmptyView(
            icon: Icons.pending_actions_rounded,
            title: strings.emptyTitle,
            subtitle: strings.noReportsInTab,
          );
        }
        return ListView.separated(
          itemCount: requested.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final inv = requested[index];
            return _buildInvestigationCard(inv, strings);
          },
        );

      case 1: // Uploaded (Pending Review)
        if (uploaded.isEmpty) {
          return DoctorEmptyView(
            icon: Icons.upload_file_rounded,
            title: strings.emptyTitle,
            subtitle: strings.noReportsInTab,
          );
        }
        return ListView.separated(
          itemCount: uploaded.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = uploaded[index];
            return _buildReportDocumentCard(doc, strings, isPending: true);
          },
        );

      case 2: // Reviewed
        if (reviewed.isEmpty) {
          return DoctorEmptyView(
            icon: Icons.task_alt_rounded,
            title: strings.emptyTitle,
            subtitle: strings.noReportsInTab,
          );
        }
        return ListView.separated(
          itemCount: reviewed.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = reviewed[index];
            return _buildReportDocumentCard(doc, strings, isPending: false);
          },
        );

      case 3: // Visit Reports (PDFs)
      default:
        return _buildVisitReportsTab(strings);
    }
  }

  Widget _buildInvestigationCard(
    InvestigationRequest inv,
    DoctorStrings strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DoctorColors.brandOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: const Icon(
              Icons.biotech_rounded,
              color: DoctorColors.brandOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      inv.category.name.toUpperCase(),
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DoctorColors.brandOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                      ),
                      child: Text(
                        strings.pendingUploadStatus,
                        style: DoctorTheme.caption.copyWith(
                          color: DoctorColors.brandOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  inv.name,
                  style: DoctorTheme.bodyBold.copyWith(
                    color: DoctorColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings.patientIdLabel}: ${inv.patientId ?? "PAT-001"} • ${strings.cases}: ${inv.caseId ?? "CASE-001"}',
                  style: DoctorTheme.caption.copyWith(color: DoctorColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${inv.requestedAt.day}/${inv.requestedAt.month}/${inv.requestedAt.year}',
            style: DoctorTheme.caption.copyWith(color: DoctorColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDocumentCard(
    ReportDocument doc,
    DoctorStrings strings, {
    required bool isPending,
  }) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: isPending
              ? DoctorColors.brandTeal.withValues(alpha: 0.4)
              : DoctorColors.border,
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPending
                  ? DoctorColors.brandTeal.withValues(alpha: 0.1)
                  : DoctorColors.statusAvailable.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: Icon(
              isPending ? Icons.upload_file_rounded : Icons.task_alt_rounded,
              color: isPending
                  ? DoctorColors.brandTeal
                  : DoctorColors.statusAvailable,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      doc.fileName,
                      style: DoctorTheme.bodyBold.copyWith(
                        color: DoctorColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPending
                            ? DoctorColors.brandTeal.withValues(alpha: 0.12)
                            : DoctorColors.statusAvailable.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                      ),
                      child: Text(
                        isPending ? strings.uploadedStatus : strings.reviewedStatus,
                        style: DoctorTheme.caption.copyWith(
                          color: isPending
                              ? DoctorColors.brandTeal
                              : DoctorColors.statusAvailable,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings.patientIdLabel}: ${doc.patientId} • ${(doc.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                  style: DoctorTheme.caption.copyWith(color: DoctorColors.textMuted),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DoctorSecondaryButton(
                label: strings.viewReportButton,
                icon: Icons.visibility_outlined,
                onPressed: () {
                  DoctorReportViewerDialog.show(
                    context,
                    reportDoc: doc,
                    locale: _locale,
                    currentPatientId: doc.patientId,
                    currentCaseId: doc.caseId,
                    currentVisitId: doc.visitId,
                  );
                },
                height: 36,
              ),
              if (isPending) ...[
                const SizedBox(width: 8),
                DoctorPrimaryButton(
                  label: strings.markAsReviewedButton,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _markDocumentReviewed(doc),
                  height: 36,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitReportsTab(DoctorStrings strings) {
    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 20, color: DoctorColors.brandNavy),
              const SizedBox(width: 8),
              Text(
                strings.officialVisitPdf,
                style: DoctorTheme.headline2.copyWith(
                  color: DoctorColors.brandNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DoctorTheme.space16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
              side: const BorderSide(color: DoctorColors.border),
            ),
            tileColor: DoctorColors.background,
            leading: const Icon(Icons.picture_as_pdf_outlined,
                color: DoctorColors.brandOrange),
            title: const Text(
              'AAYUSATHI_VISIT_REPORT_Aarav_Sharma_VIS-CASE-001-1.pdf',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            subtitle: Text('${strings.patientIdLabel}: PAT-001 • Cardiology'),
            trailing: DoctorPrimaryButton(
              label: strings.openPdfButton,
              icon: Icons.open_in_new_rounded,
              onPressed: () => _openPdf(
                'AAYUSATHI_VISIT_REPORT_Aarav_Sharma_VIS-CASE-001-1.pdf',
              ),
              height: 36,
            ),
          ),
        ],
      ),
    );
  }
}
