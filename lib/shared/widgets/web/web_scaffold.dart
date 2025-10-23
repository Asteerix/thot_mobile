import 'package:flutter/material.dart';
import '../../../core/themes/web_theme.dart';
import 'web_sidebar.dart';
import 'web_header.dart';
import 'responsive_layout.dart';

/// Main web scaffold with sidebar, header, and responsive content area
class WebScaffold extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  final Widget body;
  final Widget? rightSidebar;
  final PreferredSizeWidget? header;
  final Widget? userProfile;
  final bool showHeader;
  final bool showSidebar;
  final bool showRightSidebar;
  final Color? backgroundColor;
  final double? maxContentWidth;
  final EdgeInsetsGeometry? contentPadding;

  const WebScaffold({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.body,
    this.rightSidebar,
    this.header,
    this.userProfile,
    this.showHeader = true,
    this.showSidebar = true,
    this.showRightSidebar = false,
    this.backgroundColor,
    this.maxContentWidth,
    this.contentPadding,
  });

  @override
  State<WebScaffold> createState() => _WebScaffoldState();
}

class _WebScaffoldState extends State<WebScaffold> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deviceType = context.deviceType;

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? colorScheme.background,
      body: ResponsiveLayout(
        builder: (context, deviceType) {
          switch (deviceType) {
            case DeviceType.mobile:
              return _buildMobileLayout(context, colorScheme);
            case DeviceType.tablet:
            case DeviceType.desktop:
            case DeviceType.largeDesktop:
              return _buildDesktopLayout(context, colorScheme, deviceType);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    // On mobile, use standard mobile layout (not web scaffold)
    return Column(
      children: [
        if (widget.showHeader && widget.header != null) widget.header!,
        Expanded(child: widget.body),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    final isTablet = deviceType == DeviceType.tablet;
    final showRightSidebar = widget.showRightSidebar &&
        (deviceType == DeviceType.desktop ||
            deviceType == DeviceType.largeDesktop);

    return Row(
      children: [
        // Left sidebar
        if (widget.showSidebar)
          WebSidebar(
            currentRoute: widget.currentRoute,
            onNavigate: widget.onNavigate,
            collapsed: _sidebarCollapsed && isTablet,
            onToggleCollapse: isTablet ? _toggleSidebar : null,
            userProfile: widget.userProfile,
          ),

        // Main content area
        Expanded(
          child: Column(
            children: [
              // Header
              if (widget.showHeader && widget.header != null) widget.header!,

              // Body content
              Expanded(
                child: _buildContentArea(
                  context,
                  colorScheme,
                  showRightSidebar,
                ),
              ),
            ],
          ),
        ),

        // Right sidebar (desktop only)
        if (showRightSidebar && widget.rightSidebar != null)
          _buildRightSidebar(context, colorScheme),
      ],
    );
  }

  Widget _buildContentArea(
    BuildContext context,
    ColorScheme colorScheme,
    bool hasRightSidebar,
  ) {
    final maxWidth = widget.maxContentWidth ??
        (hasRightSidebar ? double.infinity : WebTheme.maxContentWidth);

    return Container(
      color: widget.backgroundColor ?? colorScheme.background,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: widget.contentPadding != null
              ? Padding(
                  padding: widget.contentPadding!,
                  child: widget.body,
                )
              : widget.body,
        ),
      ),
    );
  }

  Widget _buildRightSidebar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: WebTheme.sidebarWidthExpanded,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: widget.rightSidebar,
    );
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }
}

/// Multi-column layout for feed-style pages (3 columns on desktop)
class WebMultiColumnLayout extends StatelessWidget {
  final Widget content;
  final Widget? leftSidebar;
  final Widget? rightSidebar;
  final double contentMaxWidth;
  final double leftSidebarWidth;
  final double rightSidebarWidth;
  final EdgeInsetsGeometry? padding;

  const WebMultiColumnLayout({
    super.key,
    required this.content,
    this.leftSidebar,
    this.rightSidebar,
    this.contentMaxWidth = WebTheme.maxFeedWidth,
    this.leftSidebarWidth = 280,
    this.rightSidebarWidth = 320,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, deviceType) {
        if (deviceType == DeviceType.mobile) {
          return _buildMobileLayout(context);
        }

        if (deviceType == DeviceType.tablet) {
          return _buildTabletLayout(context);
        }

        return _buildDesktopLayout(context);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(WebTheme.md),
      child: content,
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: padding ?? const EdgeInsets.all(WebTheme.xl),
            child: content,
          ),
        ),
        if (rightSidebar != null)
          SizedBox(
            width: rightSidebarWidth,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(WebTheme.xl),
              child: rightSidebar!,
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = WebTheme.isLargeDesktop(screenWidth);

    // Adjust widths for large screens
    final actualLeftWidth =
        isLargeScreen ? leftSidebarWidth + 40 : leftSidebarWidth;
    final actualRightWidth =
        isLargeScreen ? rightSidebarWidth + 60 : rightSidebarWidth;
    final actualContentWidth =
        isLargeScreen ? contentMaxWidth + 200 : contentMaxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeScreen
              ? WebTheme.maxWideLayoutWidth
              : WebTheme.maxContentWidth,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left sidebar (optional)
            if (leftSidebar != null)
              SizedBox(
                width: actualLeftWidth,
                child: Padding(
                  padding: padding ??
                      EdgeInsets.all(WebTheme.getScreenPadding(screenWidth)),
                  child: leftSidebar!,
                ),
              ),

            // Main content
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: actualContentWidth),
                child: Padding(
                  padding: padding ??
                      EdgeInsets.all(WebTheme.getScreenPadding(screenWidth)),
                  child: content,
                ),
              ),
            ),

            // Right sidebar (optional)
            if (rightSidebar != null)
              SizedBox(
                width: actualRightWidth,
                child: Padding(
                  padding: padding ??
                      EdgeInsets.all(WebTheme.getScreenPadding(screenWidth)),
                  child: rightSidebar!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
