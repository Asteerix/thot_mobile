import 'package:flutter/material.dart';
import '../../../core/themes/web_theme.dart';
import 'responsive_layout.dart';

/// A responsive two-column layout widget that adapts to different screen sizes.
///
/// On desktop/tablet: displays content side-by-side with a fixed-width left column
/// and an expanding right column.
///
/// On mobile: stacks content vertically with the left column on top.
///
/// Commonly used for:
/// - Settings screens (menu + content)
/// - Profile editing (navigation + form)
/// - Notifications (filters + list)
///
/// Example:
/// ```dart
/// WebTwoColumnLayout(
///   leftColumn: SettingsMenu(),
///   rightColumn: SettingsContent(),
///   leftColumnWidth: 280,
/// )
/// ```
class WebTwoColumnLayout extends StatelessWidget {
  /// Default width for the left column on desktop/tablet
  static const double defaultLeftColumnWidth = 280.0;

  /// Widget displayed in the left column (typically navigation or filters)
  final Widget leftColumn;

  /// Widget displayed in the right column (typically main content)
  final Widget rightColumn;

  /// Width of the left column on desktop/tablet layouts
  final double leftColumnWidth;

  /// Spacing between the two columns
  final double spacing;

  /// Custom padding around the layout
  /// Defaults to [WebTheme.md] on mobile and [WebTheme.xl] on desktop
  final EdgeInsetsGeometry? padding;

  const WebTwoColumnLayout({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
    this.leftColumnWidth = defaultLeftColumnWidth,
    this.spacing = WebTheme.columnSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, deviceType) {
        // Mobile: vertical stack layout
        if (deviceType == DeviceType.mobile) {
          return SingleChildScrollView(
            padding: padding ?? const EdgeInsets.all(WebTheme.md),
            child: Column(
              children: [
                leftColumn,
                SizedBox(height: spacing),
                rightColumn,
              ],
            ),
          );
        }

        // Desktop/Tablet: side-by-side layout
        return Padding(
          padding: padding ?? const EdgeInsets.all(WebTheme.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed-width left column
              SizedBox(
                width: leftColumnWidth,
                child: leftColumn,
              ),
              SizedBox(width: spacing),
              // Expanding right column
              Expanded(child: rightColumn),
            ],
          ),
        );
      },
    );
  }
}
