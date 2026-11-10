import 'package:flutter/material.dart';
import '../models/admin_domain_availability.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// Tabular display for Doctor Availability by specialty domain (Phase A12 Final Polish).
///
/// Columns:
/// 1. SPECIALTY DOMAIN (8 OPD specialties with presence dot indicator)
/// 2. ONLINE DOCTORS (Active & online clinicians)
/// 3. AVAILABLE (Active & ready to accept patients)
/// 4. IN CONSULTATION (Active & currently in an active consultation session)
class AdminAvailabilityTable extends StatelessWidget {
  final List<AdminDomainAvailability> items;
  final ValueChanged<AdminDomainAvailability>? onDomainTap;
  final bool isLoading;

  const AdminAvailabilityTable({
    super.key,
    required this.items,
    this.onDomainTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminTheme.radius16),
        border: Border.all(color: AdminColors.borderSubtle),
        boxShadow: AdminTheme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.space20,
              vertical: AdminTheme.space14,
            ),
            decoration: const BoxDecoration(
              color: AdminColors.surfaceSubtle,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AdminTheme.radius16),
                topRight: Radius.circular(AdminTheme.radius16),
              ),
              border: Border(
                bottom: BorderSide(color: AdminColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'SPECIALTY DOMAIN',
                    style: AdminTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ONLINE DOCTORS',
                    style: AdminTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AdminColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'AVAILABLE',
                    style: AdminTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AdminColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'IN CONSULTATION',
                    style: AdminTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AdminColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Domain Rows
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AdminTheme.space32),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AdminColors.brandTeal),
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AdminTheme.space32),
              child: Center(
                child: Text(
                  'No doctor availability data found.',
                  style: AdminTheme.bodyRegular.copyWith(
                    color: AdminColors.textMuted,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: AdminColors.borderSubtle,
              ),
              itemBuilder: (context, index) {
                final domain = items[index];
                return _DomainRow(
                  item: domain,
                  onTap: onDomainTap != null ? () => onDomainTap!(domain) : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DomainRow extends StatefulWidget {
  final AdminDomainAvailability item;
  final VoidCallback? onTap;

  const _DomainRow({
    required this.item,
    this.onTap,
  });

  @override
  State<_DomainRow> createState() => _DomainRowState();
}

class _DomainRowState extends State<_DomainRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isOnline = item.onlineDoctors > 0;
    final isAvailable = item.available > 0;
    final isConsulting = item.inConsultation > 0;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: Material(
        color: _isHovered ? AdminColors.surfaceHover : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.space20,
              vertical: AdminTheme.space14,
            ),
            child: Row(
              children: [
                // 1. Specialty Domain Name + Status Pulse Dot
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline
                              ? AdminColors.statusAvailable
                              : AdminColors.textMuted.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space10),
                      Flexible(
                        child: Text(
                          item.domainName,
                          style: AdminTheme.bodyBold.copyWith(
                            fontSize: 13,
                            color: isOnline
                                ? AdminColors.brandNavy
                                : AdminColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Online Doctors Count
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AdminTheme.space10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AdminColors.brandTeal.withValues(alpha: 0.10)
                            : AdminColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(AdminTheme.radius6),
                        border: Border.all(
                          color: isOnline
                              ? AdminColors.brandTeal.withValues(alpha: 0.28)
                              : AdminColors.border,
                        ),
                      ),
                      child: Text(
                        '${item.onlineDoctors}',
                        style: AdminTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isOnline
                              ? AdminColors.brandTeal
                              : AdminColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Available Count (Green / Teal Pill when > 0, subtle neutral when 0)
                Expanded(
                  flex: 2,
                  child: Center(
                    child: isAvailable
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AdminTheme.space10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.statusAvailable.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AdminTheme.radius6),
                              border: Border.all(
                                color: AdminColors.statusAvailable.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${item.available}',
                              style: AdminTheme.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AdminColors.statusAvailable,
                              ),
                            ),
                          )
                        : Text(
                            '0',
                            style: AdminTheme.bodyRegular.copyWith(
                              color: AdminColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),

                // 4. In Consultation Count (Warm Orange Pill when > 0, subtle neutral when 0)
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: isConsulting
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AdminTheme.space10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.brandOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AdminTheme.radius6),
                              border: Border.all(
                                color: AdminColors.brandOrange.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${item.inConsultation}',
                              style: AdminTheme.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AdminColors.brandOrange,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              '0',
                              style: AdminTheme.bodyRegular.copyWith(
                                color: AdminColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
