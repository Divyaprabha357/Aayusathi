import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import '../../core/backend/backend_exception.dart';
import '../../core/backend/backend_mode.dart';
import '../../core/localization/kiosk_locale.dart';
import '../../core/routes/app_routes.dart';
import '../localization/doctor_localizations.dart';
import '../localization/doctor_strings.dart';
import '../models/clinical_case.dart';
import '../models/doctor_navigation_item.dart';
import '../models/higher_authority_assignment.dart';
import '../services/doctor_session_service.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';
import '../widgets/doctor_buttons.dart';
import '../widgets/doctor_desktop_scaffold.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_sidebar.dart';
import '../widgets/doctor_state_views.dart';

/// Full standalone screen for Doctor Cases & Clinical Visits repository (Phase D15).
class DoctorCaseScreen extends StatefulWidget {
  const DoctorCaseScreen({super.key});

  @override
  State<DoctorCaseScreen> createState() => _DoctorCaseScreenState();
}

class _DoctorCaseScreenState extends State<DoctorCaseScreen> {
  final KioskLocale _locale = KioskLocale.english;
  bool _isLoading = true;
  String? _errorMessage;

  List<ClinicalCase> _allCases = [];
  String _searchQuery = '';
  int _selectedFilterTab = 0; // 0: All, 1: Open, 2: Closed
  late final TextEditingController _searchController;

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
    _loadCases();
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

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isFirebaseMode = BackendProvider.instance.isFirebaseMode;
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? (isFirebaseMode ? null : 'DOC-101');

    if (isFirebaseMode) {
      final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Doctor authorization failed: Firebase user is not signed in. Please log in again.';
            _isLoading = false;
          });
        }
        return;
      }

      if (doctorId == null || doctorId.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Doctor session not established. Please log in.';
            _isLoading = false;
          });
        }
        return;
      }

      // Verify doctor profile against Firestore
      try {
        final docSnapshot = await fb_store.FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .get();

        if (!docSnapshot.exists || docSnapshot.data() == null) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Doctor profile not found for doctor ID: $doctorId';
              _isLoading = false;
            });
          }
          return;
        }

        final docData = docSnapshot.data()!;
        final isActive = docData['isActive'] as bool? ?? false;
        if (!isActive) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Doctor account is currently inactive. Please contact administration.';
              _isLoading = false;
            });
          }
          return;
        }

        final authUid = docData['authUid'] as String? ?? '';
        if (authUid.isNotEmpty && authUid != currentUser.uid) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Doctor profile authentication mismatch: UID does not match registered profile.';
              _isLoading = false;
            });
          }
          return;
        }
      } catch (err) {
        debugPrint('[DoctorCaseScreen] Diagnostic check on doctor profile: $err');
      }
    }

    if (doctorId == null || doctorId.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No active Doctor ID found in session.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final cases = await BackendProvider.instance.caseRepository.getCasesForDoctor(doctorId);
      if (mounted) {
        setState(() {
          _allCases = cases;
          _isLoading = false;
        });
      }
    } on BackendException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
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
    if (item.routeName != AppRoutes.doctorCase) {
      Navigator.of(context).pushReplacementNamed(item.routeName);
    }
  }

  List<ClinicalCase> _getFilteredCases() {
    return _allCases.where((c) {
      // Tab filter
      if (_selectedFilterTab == 1 && !c.isOpen) return false;
      if (_selectedFilterTab == 2 && !c.isClosed) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesCaseId = c.caseId.toLowerCase().contains(q);
        final matchesPatientId = c.patientId.toLowerCase().contains(q);
        final matchesDomain = c.domain.toLowerCase().contains(q);
        final matchesTitle = c.title.toLowerCase().contains(q);
        return matchesCaseId || matchesPatientId || matchesDomain || matchesTitle;
      }

      return true;
    }).toList();
  }

  void _openCaseInWorkspace(ClinicalCase c) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.doctorPatientWorkspace,
      arguments: {
        'caseId': c.caseId,
        'patientId': c.patientId,
        'domain': c.domain,
        'isReadOnly': c.isClosed,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = DoctorLocalizations.forLocale(_locale);
    final filteredCases = _getFilteredCases();

    final openCount = _allCases.where((c) => c.isOpen).length;
    final closedCount = _allCases.where((c) => c.isClosed).length;

    return DoctorDesktopScaffold(
      header: DoctorHeader(
        title: strings.casesAndVisitsTitle,
        subtitle: strings.casesAndVisitsSubtitle,
        onBack: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard),
        onLogout: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.doctorStandby),
      ),
      sidebar: DoctorSidebar(
        items: _navItems,
        activeRoute: AppRoutes.doctorCase,
        isCollapsed: DoctorSidebarController.instance.isCollapsed,
        onToggleCollapse: DoctorSidebarController.instance.toggle,
        onItemSelected: _onNavigationSelected,
      ),
      body: _isLoading
          ? const Center(child: DoctorLoadingView())
          : _errorMessage != null
              ? DoctorErrorView(
                  title: strings.unableToLoadClinicalRecords,
                  message: _errorMessage!,
                  onRetry: _loadCases,
                )
              : Container(
                  padding: const EdgeInsets.all(DoctorTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Tabs & Search
                      Row(
                        children: [
                          // Tab Filter Buttons
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterTab(
                                    index: 0,
                                    label: '${strings.tabAllCases} (${_allCases.length})',
                                    icon: Icons.folder_open_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterTab(
                                    index: 1,
                                    label: '${strings.tabOpenCases} ($openCount)',
                                    icon: Icons.lock_open_rounded,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterTab(
                                    index: 2,
                                    label: '${strings.tabClosedCases} ($closedCount)',
                                    icon: Icons.lock_outline_rounded,
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
                                hintText: strings.searchCasesHint,
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

                      // Cases List View
                      Expanded(
                        child: filteredCases.isEmpty
                            ? DoctorEmptyView(
                                icon: Icons.folder_open_rounded,
                                title: _allCases.isEmpty ? 'No Clinical Cases' : strings.emptyTitle,
                                subtitle: _allCases.isEmpty
                                    ? 'No clinical cases found where you participated in patient care.'
                                    : strings.noCasesInFilter,
                              )
                            : ListView.separated(
                                itemCount: filteredCases.length,
                                separatorBuilder: (ctx, i) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final c = filteredCases[index];
                                  return _buildCaseCard(c, strings);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilterTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedFilterTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilterTab = index),
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

  Future<void> _handleAcceptAssignment(ClinicalCase c) async {
    final session = DoctorSessionService.instance;
    final doctorId = session.activeDoctorId ?? 'DOC-101';
    try {
      await BackendProvider.instance.caseRepository.acceptHigherAuthorityAssignment(
        patientId: c.patientId,
        caseId: c.caseId,
        doctorId: doctorId,
      );
      if (mounted) {
        await _loadCases();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case ${c.caseId} accepted successfully under higher-authority governance.'),
            backgroundColor: DoctorColors.brandTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept case assignment: $e'),
            backgroundColor: DoctorColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildCaseCard(ClinicalCase c, DoctorStrings strings) {
    final session = DoctorSessionService.instance;
    final currentDoctorId = session.activeDoctorId ?? 'DOC-101';
    final isAssignedToMe = c.higherAuthorityDoctorId == currentDoctorId;
    final isPendingAcceptance = isAssignedToMe &&
        c.higherAuthorityAssignmentStatus == HigherAuthorityAssignmentStatus.assigned;

    final created = c.createdAt;
    final updated = c.updatedAt;
    final formattedCreated =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}/${created.year}';
    final formattedUpdated =
        '${updated.day.toString().padLeft(2, '0')}/${updated.month.toString().padLeft(2, '0')}/${updated.year}';

    return Container(
      padding: const EdgeInsets.all(DoctorTheme.space16),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(DoctorTheme.radius12),
        border: Border.all(
          color: isPendingAcceptance
              ? DoctorColors.brandTeal
              : DoctorColors.border,
          width: isPendingAcceptance ? 1.5 : 1.0,
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.isOpen
                  ? DoctorColors.brandTeal.withValues(alpha: 0.1)
                  : DoctorColors.brandNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DoctorTheme.radius8),
            ),
            child: Icon(
              c.isOpen ? Icons.folder_open_rounded : Icons.lock_outline_rounded,
              color: c.isOpen ? DoctorColors.brandTeal : DoctorColors.brandNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: DoctorTheme.space16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      c.domain,
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.isOpen
                            ? DoctorColors.statusAvailable.withValues(alpha: 0.12)
                            : DoctorColors.statusOffline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                      ),
                      child: Text(
                        c.isOpen ? strings.openCase : strings.closedCase,
                        style: DoctorTheme.caption.copyWith(
                          color: c.isOpen
                              ? DoctorColors.statusAvailable
                              : DoctorColors.statusOffline,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    if (isAssignedToMe) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPendingAcceptance
                              ? DoctorColors.brandOrange.withValues(alpha: 0.12)
                              : DoctorColors.brandTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                          border: Border.all(
                            color: isPendingAcceptance
                                ? DoctorColors.brandOrange.withValues(alpha: 0.4)
                                : DoctorColors.brandTeal.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          isPendingAcceptance
                              ? 'HIGHER AUTHORITY: PENDING ACCEPTANCE'
                              : 'HIGHER AUTHORITY: ACCEPTED',
                          style: DoctorTheme.caption.copyWith(
                            color: isPendingAcceptance
                                ? DoctorColors.brandOrange
                                : DoctorColors.brandTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.title,
                  style: DoctorTheme.headline2.copyWith(
                    color: DoctorColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${strings.patientIdLabel}: ${c.patientId}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${strings.cases}: ${c.caseId}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textMuted,
                      ),
                    ),
                    Text(
                      '${c.visitCount} ${strings.visits.toLowerCase()}',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.brandTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (c.isClosed &&
                    c.closureNote != null &&
                    c.closureNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DoctorColors.background,
                      borderRadius: BorderRadius.circular(DoctorTheme.radius6),
                      border: Border.all(color: DoctorColors.border),
                    ),
                    child: Text(
                      '${strings.closureNoteCardLabel}: "${c.closureNote}"',
                      style: DoctorTheme.caption.copyWith(
                        color: DoctorColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: DoctorTheme.space16),

          // Right: Dates & Action Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${strings.createdLabel}: $formattedCreated',
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${strings.lastUpdatedLabel}: $formattedUpdated',
                style: DoctorTheme.caption.copyWith(
                  color: DoctorColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPendingAcceptance) ...[
                    DoctorPrimaryButton(
                      key: ValueKey('accept_case_${c.caseId}'),
                      label: 'ACCEPT CASE',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () => _handleAcceptAssignment(c),
                      height: 38,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (c.isOpen)
                    DoctorPrimaryButton(
                      label: strings.openCaseButton,
                      icon: Icons.folder_open_rounded,
                      onPressed: () => _openCaseInWorkspace(c),
                      height: 38,
                    )
                  else
                    DoctorSecondaryButton(
                      label: strings.viewHistoryButton,
                      icon: Icons.history_rounded,
                      onPressed: () => _openCaseInWorkspace(c),
                      height: 38,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
