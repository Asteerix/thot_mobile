import 'package:flutter/material.dart';
import '../../../core/themes/web_theme.dart';

/// Device type for responsive layouts
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop;

  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop || this == DeviceType.largeDesktop;
  bool get isLargeDesktop => this == DeviceType.largeDesktop;
}

/// Responsive layout builder that adapts based on screen size
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   builder: (context, deviceType) {
///     return deviceType.isMobile ? MobileView() : DesktopView();
///   },
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  // DEAD CODE: constructeur byDevice jamais utilisé dans la codebase
  // const ResponsiveLayout.byDevice({
  //   super.key,
  //   Widget? mobile,
  //   Widget? tablet,
  //   Widget? desktop,
  // }) : builder = _defaultBuilder;
  //
  // static Widget _defaultBuilder(BuildContext context, DeviceType deviceType) {
  //   return const SizedBox.shrink();
  // }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = getDeviceType(constraints.maxWidth);
        return builder(context, deviceType);
      },
    );
  }

  static DeviceType getDeviceType(double width) {
    if (WebTheme.isMobile(width)) return DeviceType.mobile;
    if (WebTheme.isTablet(width)) return DeviceType.tablet;
    if (WebTheme.isLargeDesktop(width)) return DeviceType.largeDesktop;
    return DeviceType.desktop;
  }
}

/// Extension pour accéder facilement au type de device et aux valeurs responsives
///
/// Usage:
/// ```dart
/// if (context.isMobile) { ... }
/// final padding = context.screenPadding;
/// ```
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveLayout.getDeviceType(width);
  }

  bool get isMobile => deviceType.isMobile;
  bool get isTablet => deviceType.isTablet;
  bool get isDesktop => deviceType.isDesktop;
  bool get isLargeDesktop => deviceType.isLargeDesktop;

  double get screenPadding {
    final width = MediaQuery.of(this).size.width;
    return WebTheme.getScreenPadding(width);
  }

  int get columnCount {
    final width = MediaQuery.of(this).size.width;
    return WebTheme.getColumnCount(width);
  }

  double get contentMaxWidth {
    final width = MediaQuery.of(this).size.width;
    return WebTheme.getContentMaxWidth(width);
  }
}

/// Grid responsive qui adapte automatiquement le nombre de colonnes selon l'écran
///
/// Utilisé dans: explore_screen_web, search_screen_web, profile_screen_web,
/// followers_screen_web, admin_dashboard_screen_web
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = WebTheme.gridSpacing,
    this.runSpacing = WebTheme.gridSpacing,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;
    final columns = _getColumnCount(deviceType);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      childAspectRatio: childAspectRatio ?? 1.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  int _getColumnCount(DeviceType deviceType) {
    return switch (deviceType) {
      DeviceType.mobile => mobileColumns ?? 1,
      DeviceType.tablet => tabletColumns ?? 2,
      DeviceType.desktop => desktopColumns ?? 3,
      DeviceType.largeDesktop => desktopColumns ?? 4,
    };
  }
}

// DEAD CODE: ResponsivePadding jamais utilisé dans la codebase
// class ResponsivePadding extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry? mobile;
//   final EdgeInsetsGeometry? tablet;
//   final EdgeInsetsGeometry? desktop;
//
//   const ResponsivePadding({
//     super.key,
//     required this.child,
//     this.mobile,
//     this.tablet,
//     this.desktop,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final deviceType = context.deviceType;
//     final padding = switch (deviceType) {
//       DeviceType.mobile => mobile ?? const EdgeInsets.all(WebTheme.md),
//       DeviceType.tablet => tablet ?? const EdgeInsets.all(WebTheme.xl),
//       DeviceType.desktop => desktop ?? const EdgeInsets.all(WebTheme.desktopScreenPaddingHorizontal),
//       DeviceType.largeDesktop => desktop ?? const EdgeInsets.all(WebTheme.xxxl),
//     };
//
//     return Padding(padding: padding, child: child);
//   }
// }

// DEAD CODE: ResponsiveValue jamais utilisé dans la codebase
// class ResponsiveValue<T> {
//   final T mobile;
//   final T? tablet;
//   final T? desktop;
//
//   const ResponsiveValue({
//     required this.mobile,
//     this.tablet,
//     this.desktop,
//   });
//
//   T get(BuildContext context) {
//     final deviceType = context.deviceType;
//     return switch (deviceType) {
//       DeviceType.mobile => mobile,
//       DeviceType.tablet => tablet ?? desktop ?? mobile,
//       DeviceType.desktop || DeviceType.largeDesktop => desktop ?? tablet ?? mobile,
//     };
//   }
// }
