import 'package:flutter/material.dart';
import '../models/doctor_navigation_item.dart';
import '../theme/doctor_colors.dart';
import '../theme/doctor_theme.dart';

/// Global controller managing persistent sidebar collapse state across all
/// Doctor Portal screens to guarantee zero layout shift on navigation.
class DoctorSidebarController extends ChangeNotifier {
  static final DoctorSidebarController instance = DoctorSidebarController._();
  DoctorSidebarController._();

  bool _isCollapsed = false;
  bool get isCollapsed => _isCollapsed;

  void toggle() {
    _isCollapsed = !_isCollapsed;
    notifyListeners();
  }

  void setCollapsed(bool value) {
    if (_isCollapsed != value) {
      _isCollapsed = value;
      notifyListeners();
    }
  }

  void reset() {
    _isCollapsed = false;
    notifyListeners();
  }
}

/// Collapsible desktop navigation sidebar for the Doctor Interface.
class DoctorSidebar extends StatelessWidget {
  final List<DoctorNavigationItem> items;
  final String activeRoute;
  final ValueChanged<DoctorNavigationItem> onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const DoctorSidebar({
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
        color: DoctorColors.surface,
        border: const Border(
          right: BorderSide(color: DoctorColors.border, width: 1),
        ),
        boxShadow: DoctorTheme.shadowSubtle,
      ),
      child: Column(
        children: [
          // Sidebar Toggle Button & Section Label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorTheme.space16,
              vertical: DoctorTheme.space16,
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  Expanded(
                    child: Text(
                      'CLINICAL WORKSPACE',
                      style: DoctorTheme.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 10,
                        color: DoctorColors.textSecondary,
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
                    color: DoctorColors.textSecondary,
                  ),
                  tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                  onPressed: onToggleCollapse,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DoctorColors.borderSubtle),

          // Nav Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: DoctorTheme.space12,
                horizontal: DoctorTheme.space8,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: DoctorTheme.space4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.routeName == activeRoute;

                return _DoctorSidebarTile(
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
            const Divider(height: 1, color: DoctorColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(DoctorTheme.space16),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 16,
                    color: DoctorColors.brandTeal,
                  ),
                  const SizedBox(width: DoctorTheme.space8),
                  Expanded(
                    child: Text(
                      'Hospital Protected Session',
                      style: DoctorTheme.caption.copyWith(
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

class _DoctorSidebarTile extends StatefulWidget {
  final DoctorNavigationItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _DoctorSidebarTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_DoctorSidebarTile> createState() => _DoctorSidebarTileState();
}

class _DoctorSidebarTileState extends State<_DoctorSidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? DoctorColors.backgroundSecondary
        : (_isHovered ? DoctorColors.surfaceHover : Colors.transparent);
    final iconColor = widget.isSelected
        ? DoctorColors.brandTeal
        : DoctorColors.textSecondary;
    final textColor = widget.isSelected
        ? DoctorColors.brandNavy
        : DoctorColors.textPrimary;

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
                borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                border: Border.all(
                  color: widget.isSelected
                      ? DoctorColors.brandTeal.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(DoctorTheme.radius12),
                  onTap: widget.onTap,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: showFull ? DoctorTheme.space16 : DoctorTheme.space8,
                      vertical: DoctorTheme.space12,
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
                          const SizedBox(width: DoctorTheme.space12),
                          Expanded(
                            child: Text(
                              widget.item.label,
                              style: DoctorTheme.bodyBold.copyWith(
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
                                horizontal: DoctorTheme.space6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DoctorColors.brandOrange,
                                borderRadius: BorderRadius.circular(DoctorTheme.radiusFull),
                              ),
                              child: Text(
                                '${widget.item.badgeCount}',
                                style: DoctorTheme.badgeText.copyWith(
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
