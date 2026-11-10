import 'package:flutter/material.dart';
import '../theme/doctor_colors.dart';
import 'doctor_header.dart';
import 'doctor_sidebar.dart';

/// Master responsive page shell for the AAYUSATHI Doctor Desktop Interface.
/// Provides unified layout structure across screens with optional header, sidebar, and body area.
class DoctorDesktopScaffold extends StatelessWidget {
  final Widget body;
  final DoctorHeader? header;
  final DoctorSidebar? sidebar;
  final Widget? bottomBar;
  final Color? backgroundColor;
  final bool isScrollable;
  final EdgeInsetsGeometry contentPadding;

  const DoctorDesktopScaffold({
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
      backgroundColor: backgroundColor ?? DoctorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Optional Doctor Desktop Header
            ?header,

            // Middle Layout: Sidebar + Main Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?sidebar,
                  Expanded(
                    child: Container(
                      color: backgroundColor ?? DoctorColors.background,
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
