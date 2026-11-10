/// Centralized layout and spacing system for the AAYUSATHI Patient App.
///
/// Enforces consistent vertical rhythm, screen margins, component gaps,
/// and responsive containment across Android, tablet, and desktop viewports.
class PatientSpacing {
  PatientSpacing._();

  /// Standard horizontal screen margin (20dp mobile, up to 24dp desktop).
  static const double pageHorizontal = 20.0;

  /// Standard vertical gap between PatientTopBar and the page title/content.
  static const double pageTop = 24.0;

  /// Gap between section headers and subsequent content / cards.
  static const double sectionGap = 16.0;

  /// Standard gap between sibling cards or list items.
  static const double cardGap = 16.0;

  /// Larger section gap between distinct functional blocks.
  static const double largeGap = 24.0;

  /// Small gap between closely coupled elements (e.g. icon and label).
  static const double smallGap = 8.0;

  /// Micro gap for subtle offsets (e.g. status badge padding).
  static const double microGap = 4.0;

  /// Safe margin at the bottom of scrollable content above the bottom nav bar.
  static const double bottomSafeSpace = 16.0;

  /// Standard card border radius.
  static const double cardRadius = 18.0;

  /// Input field height (accessible touch target).
  static const double inputHeight = 56.0;

  /// Button minimum height (accessible touch target).
  static const double buttonHeight = 52.0;

  /// Maximum content constraint for desktop and tablet displays.
  static const double maxContentWidth = 800.0;

  /// Maximum card width for authentication forms (Login, OTP).
  static const double maxAuthCardWidth = 480.0;
}
