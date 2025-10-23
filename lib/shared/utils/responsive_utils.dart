import 'package:flutter/material.dart';

/// Utility class for responsive design adaptations in the Thot mobile app.
///
/// This class provides static methods to help adapt UI elements based on screen size,
/// complementing the [Responsive] widget from responsive.dart which handles layout switching.
///
/// **Design Breakpoints:**
/// - Mobile: < 768px
/// - Tablet: 768px - 1023px
/// - Desktop: >= 1024px
///
/// **Note:** For consistency, breakpoint checks reuse the [Responsive] widget's static methods
/// from responsive.dart to avoid duplication and ensure synchronized behavior across the app.
class ResponsiveUtils {
  ResponsiveUtils._(); // Private constructor to prevent instantiation

  // ============================================================================
  // SCREEN SIZE DETECTION (delegates to Responsive widget for consistency)
  // ============================================================================

  /// Checks if the current screen is mobile size (< 768px).
  ///
  /// Delegates to the [Responsive] widget for consistency.
  /// Import: package:thot/shared/utils/responsive.dart
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  /// Checks if the current screen is tablet size (768px - 1023px).
  ///
  /// Delegates to the [Responsive] widget for consistency.
  /// Import: package:thot/shared/utils/responsive.dart
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  /// Checks if the current screen is desktop size (>= 1024px).
  ///
  /// Delegates to the [Responsive] widget for consistency.
  /// Import: package:thot/shared/utils/responsive.dart
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Checks if the current screen is tablet or desktop (>= 768px).
  ///
  /// Useful for applying web/tablet-specific layouts.
  static bool isWebOrTablet(BuildContext context) =>
      isDesktop(context) || isTablet(context);

  // ============================================================================
  // ADAPTIVE SPACING & PADDING (commonly used: 159 total usages)
  // ============================================================================

  /// Returns adaptive padding based on screen size.
  ///
  /// Values: Desktop 24.0 | Tablet 20.0 | Mobile 16.0
  /// Usage: 6 occurrences
  static double getAdaptivePadding(BuildContext context) {
    if (isDesktop(context)) return 24.0;
    if (isTablet(context)) return 20.0;
    return 16.0;
  }

  /// Returns adaptive card padding based on screen size.
  ///
  /// Values: Desktop 24.0 | Tablet 20.0 | Mobile 16.0
  /// Usage: 5 occurrences (admin screens)
  static double getAdaptiveCardPadding(BuildContext context) {
    if (isDesktop(context)) return 24.0;
    if (isTablet(context)) return 20.0;
    return 16.0;
  }

  /// Returns adaptive margin based on screen size.
  ///
  /// Values: Desktop 32.0 | Tablet 24.0 | Mobile 16.0
  /// Usage: 1 occurrence
  static double getAdaptiveMargin(BuildContext context) {
    if (isDesktop(context)) return 32.0;
    if (isTablet(context)) return 24.0;
    return 16.0;
  }

  /// Returns adaptive spacing with custom values per screen size.
  ///
  /// Provides full flexibility for specific spacing requirements.
  /// Usage: 7 occurrences
  static double getAdaptiveSpacing(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Returns adaptive spacing with default values.
  ///
  /// Values: Desktop 24.0 | Tablet 20.0 | Mobile 16.0
  /// Usage: 2 occurrences
  /// Note: Simpler alternative to [getAdaptiveSpacing] when defaults are acceptable.
  static double getAdaptiveSpacingSimple(BuildContext context) {
    if (isDesktop(context)) return 24.0;
    if (isTablet(context)) return 20.0;
    return 16.0;
  }

  // ============================================================================
  // ADAPTIVE TYPOGRAPHY (heavily used: 85 usages)
  // ============================================================================

  /// Returns adaptive font size based on screen size and a base size.
  ///
  /// Applies scaling multipliers: Desktop 1.2x | Tablet 1.1x | Mobile 1.0x
  /// Usage: 85 occurrences (most used method)
  static double getAdaptiveFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) return baseSize * 1.2;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize;
  }

  // ============================================================================
  // ADAPTIVE ICONS & UI ELEMENTS
  // ============================================================================

  /// Returns adaptive icon size with optional size overrides per screen type.
  ///
  /// Default values: Desktop 24.0 | Tablet 20.0 | Mobile 16.0
  /// Usage: 40 occurrences
  static double getAdaptiveIconSize(
    BuildContext context, {
    double? small,
    double? medium,
    double? large,
  }) {
    if (isDesktop(context)) return large ?? 24.0;
    if (isTablet(context)) return medium ?? 20.0;
    return small ?? 16.0;
  }

  /// Returns adaptive avatar radius based on screen size.
  ///
  /// Values: Desktop 40.0 | Tablet 36.0 | Mobile 32.0
  /// Usage: 3 occurrences (admin screens)
  static double getAdaptiveAvatarRadius(BuildContext context) {
    if (isDesktop(context)) return 40.0;
    if (isTablet(context)) return 36.0;
    return 32.0;
  }

  // ============================================================================
  // ADAPTIVE GRID LAYOUTS
  // ============================================================================

  /// Returns adaptive grid column count based on screen size.
  ///
  /// Values: Desktop 4 | Tablet 3 | Mobile 2
  /// Usage: 1 occurrence
  static int getAdaptiveGridCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  // ============================================================================
  // UNUSED METHODS (commented for potential future use)
  // ============================================================================
  // The following methods are not currently used in the codebase but kept for
  // potential future requirements. Consider removing if not needed long-term.

  // /// Returns responsive padding (alternative to getAdaptivePadding).
  // ///
  // /// Values: Desktop 32 | Tablet 24 | Mobile 16
  // /// Status: UNUSED (0 occurrences)
  // /// Note: Similar to getAdaptivePadding but with different desktop value.
  // static double getResponsivePadding(BuildContext context) {
  //   if (isDesktop(context)) return 32;
  //   if (isTablet(context)) return 24;
  //   return 16;
  // }

  // /// Returns cross-axis count for grid layouts (alternative to getAdaptiveGridCount).
  // ///
  // /// Values: Desktop 4 | Tablet 3 | Mobile 2
  // /// Status: UNUSED (0 occurrences)
  // /// Note: Duplicate of getAdaptiveGridCount. Use getAdaptiveGridCount instead.
  // static int getCrossAxisCount(BuildContext context) {
  //   if (isDesktop(context)) return 4;
  //   if (isTablet(context)) return 3;
  //   return 2;
  // }

  // /// Returns maximum width constraint based on screen size.
  // ///
  // /// Values: Desktop 1200 | Tablet 768 | Mobile infinity
  // /// Status: UNUSED (0 occurrences)
  // /// Use case: Limiting content width on larger screens for readability.
  // static double getMaxWidth(BuildContext context) {
  //   if (isDesktop(context)) return 1200;
  //   if (isTablet(context)) return 768;
  //   return double.infinity;
  // }
}
