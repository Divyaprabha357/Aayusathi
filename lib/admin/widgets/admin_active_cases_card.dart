import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';
import 'admin_card.dart';

/// Compact summary card displaying aggregate active clinical cases by medical domain.
class AdminActiveCasesCard extends StatelessWidget {
  final int totalActiveCases;
  final Map<String, int> casesByDomain;
  final bool isLoading;

  const AdminActiveCasesCard({
    super.key,
    required this.totalActiveCases,
    required this.casesByDomain,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      title: 'ACTIVE CLINICAL CASES',
      subtitle: 'Open episodes of care and domain distribution',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminTheme.space10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AdminColors.brandNavy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
        ),
        child: Text(
          '$totalActiveCases Active',
          style: AdminTheme.badgeText.copyWith(
            color: AdminColors.brandNavy,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AdminTheme.space24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AdminColors.brandTeal),
                  ),
                ),
              ),
            )
          else if (casesByDomain.isEmpty && totalActiveCases == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AdminTheme.space24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AdminColors.statusNormal,
                    size: 32,
                  ),
                  const SizedBox(height: AdminTheme.space8),
                  Text(
                    'No active clinical cases',
                    style: AdminTheme.bodyBold.copyWith(
                      color: AdminColors.brandNavy,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AdminTheme.space4),
                  Text(
                    'All patient treatment episodes are currently completed or closed.',
                    style: AdminTheme.caption.copyWith(
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Distribution by Clinical Specialty',
              style: AdminTheme.caption.copyWith(
                color: AdminColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AdminTheme.space12),
            Wrap(
              spacing: AdminTheme.space10,
              runSpacing: AdminTheme.space10,
              children: casesByDomain.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminTheme.space12,
                    vertical: AdminTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AdminColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AdminTheme.radius10),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: AdminTheme.caption.copyWith(
                          color: AdminColors.brandNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.brandTeal,
                          borderRadius:
                              BorderRadius.circular(AdminTheme.radiusFull),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: AdminTheme.badgeText.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
