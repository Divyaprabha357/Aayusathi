import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import 'admin_header.dart';
import 'admin_sidebar.dart';

/// Master responsive page shell for the AAYUSATHI Administrative Desktop Interface.
/// Provides unified layout structure across screens with persistent header, sidebar, and body area.
class AdminDesktopScaffold extends StatelessWidget {
  final Widget body;
  final AdminHeader? header;
  final AdminSidebar? sidebar;
  final Widget? bottomBar;
  final Color? backgroundColor;
  final bool isScrollable;
  final EdgeInsetsGeometry contentPadding;

  const AdminDesktopScaffold({
    super.key,
    required this.body,
    this.header,
    this.sidebar,
    this.bottomBar,
    this.backgroundColor,
    this.isScrollable = false,
    this.contentPadding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    Widget contentArea = Padding(
      padding: contentPadding,
      child: body,
    );

    if (isScrollable) {
      contentArea = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: contentArea,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AdminColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Optional Admin Desktop Header
            ?header,

            // Middle Layout: Persistent Sidebar + Main Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?sidebar,
                  Expanded(
                    child: Container(
                      color: backgroundColor ?? AdminColors.background,
                      child: contentArea,
                    ),
                  ),
                ],
              ),
            ),

            // Optional Bottom Status Bar
            ?bottomBar,
          ],
        ),
      ),
    );
  }
}
