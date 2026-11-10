import 'package:flutter/material.dart';
import '../models/admin_navigation_item.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_theme.dart';

/// Persistent desktop navigation sidebar for the AAYUSATHI Administrative Interface.
/// Designed for zero layout shift and rock-solid stationarity across all navigation switches.
class AdminSidebar extends StatelessWidget {
  final List<AdminNavigationItem> items;
  final String activeRoute;
  final ValueChanged<AdminNavigationItem> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.items,
    required this.activeRoute,
    required this.onItemSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 76.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: const Border(
          right: BorderSide(color: AdminColors.border, width: 1),
        ),
        boxShadow: AdminTheme.shadowSubtle,
      ),
      child: Column(
        children: [
          // Sidebar Toggle Button & Section Label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminTheme.space16,
              vertical: AdminTheme.space16,
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  Expanded(
                    child: Text(
                      'ADMIN CONSOLE',
                      style: AdminTheme.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                        color: AdminColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    isCollapsed
                        ? Icons.keyboard_double_arrow_right_rounded
                        : Icons.keyboard_double_arrow_left_rounded,
                    size: 20,
                    color: AdminColors.textSecondary,
                  ),
                  tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                  onPressed: onToggleCollapse,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.borderSubtle),

          // Nav Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AdminTheme.space12,
                horizontal: AdminTheme.space8,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AdminTheme.space4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.routeName == activeRoute;

                return _AdminSidebarTile(
                  item: item,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  onTap: () => onItemSelected(item),
                );
              },
            ),
          ),

          // Footer Notice
          if (!isCollapsed) ...[
            const Divider(height: 1, color: AdminColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(AdminTheme.space16),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 16,
                    color: AdminColors.brandTeal,
                  ),
                  const SizedBox(width: AdminTheme.space8),
                  Expanded(
                    child: Text(
                      'Hospital Governance Session',
                      style: AdminTheme.caption.copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminSidebarTile extends StatefulWidget {
  final AdminNavigationItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _AdminSidebarTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_AdminSidebarTile> createState() => _AdminSidebarTileState();
}

class _AdminSidebarTileState extends State<_AdminSidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AdminColors.backgroundSecondary
        : (_isHovered ? AdminColors.surfaceHover : Colors.transparent);
    final iconColor = widget.isSelected
        ? AdminColors.brandTeal
        : AdminColors.textSecondary;
    final textColor = widget.isSelected
        ? AdminColors.brandNavy
        : AdminColors.textPrimary;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showFull = !widget.isCollapsed && constraints.maxWidth > 120;

          return Tooltip(
            message: !showFull ? widget.item.label : '',
            waitDuration: const Duration(milliseconds: 300),
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AdminTheme.radius12),
                border: Border.all(
                  color: widget.isSelected
                      ? AdminColors.brandTeal.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AdminTheme.radius12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AdminTheme.radius12),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: showFull ? AdminTheme.space16 : AdminTheme.space8,
                      vertical: AdminTheme.space12,
                    ),
                    child: Row(
                      mainAxisAlignment: showFull
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isSelected ? widget.item.selectedIcon : widget.item.icon,
                          size: 20,
                          color: iconColor,
                        ),
                        if (showFull) ...[
                          const SizedBox(width: AdminTheme.space12),
                          Expanded(
                            child: Text(
                              widget.item.label,
                              style: AdminTheme.bodyBold.copyWith(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.item.badgeCount != null && widget.item.badgeCount! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AdminTheme.space6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AdminColors.brandOrange,
                                borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
                              ),
                              child: Text(
                                '${widget.item.badgeCount}',
                                style: AdminTheme.badgeText.copyWith(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
