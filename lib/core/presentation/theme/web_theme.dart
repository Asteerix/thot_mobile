class WebTheme {
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  static const double largeDesktopBreakpoint = 1920.0;
  static const double unit = 8.0;
  static const double xs = unit * 0.5;
  static const double sm = unit;
  static const double md = unit * 2;
  static const double lg = unit * 3;
  static const double xl = unit * 4;
  static const double xxl = unit * 6;
  static const double xxxl = unit * 8;
  static const double screenPaddingHorizontal = xl;
  static const double screenPaddingVertical = xl;
  static const double desktopScreenPaddingHorizontal = xxl;
  static const double desktopScreenPaddingVertical = xl;
  static const double maxContentWidth = 1400.0;
  static const double maxFeedWidth = 900.0;
  static const double maxFormWidth = 600.0;
  static const double maxWideLayoutWidth = 1600.0;
  static const double sidebarWidthCollapsed = 80.0;
  static const double sidebarWidthExpanded = 280.0;
  static const double sidebarIconSize = 24.0;
  static const double headerHeight = 64.0;
  static const double searchBarWidth = 500.0;
  static const double searchBarHeight = 40.0;
  static const double buttonHeight = 44.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 52.0;
  static const double inputHeight = 44.0;
  static const double inputHeightLarge = 52.0;
  static const double buttonPaddingHorizontal = xl;
  static const double buttonPaddingVertical = md;
  static const double cardPadding = lg;
  static const double cardPaddingLarge = xl;
  static const double listItemPadding = lg;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  static const double avatarSizeSmall = 40.0;
  static const double avatarSizeMedium = 56.0;
  static const double avatarSizeLarge = 80.0;
  static const double avatarSizeXLarge = 120.0;
  static const double columnSpacing = lg;
  static const double columnSpacingLarge = xl;
  static const double gridSpacing = md;
  static const double gridSpacingLarge = lg;
  static const double feedItemSpacing = lg;
  static const double postImageMaxHeight = 600.0;
  static const double modalMaxWidth = 800.0;
  static const double dialogMaxWidth = 500.0;
  static const double dialogPadding = xl;
  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < tabletBreakpoint;
  static bool isDesktop(double width) => width >= tabletBreakpoint;
  static bool isLargeDesktop(double width) => width >= largeDesktopBreakpoint;
  static int getColumnCount(double width) {
    if (isMobile(width)) return 1;
    if (isTablet(width)) return 2;
    if (isLargeDesktop(width)) return 3;
    return 2;
  }
  static double getScreenPadding(double width) {
    if (isMobile(width)) return md;
    if (isTablet(width)) return xl;
    if (isLargeDesktop(width)) return xxxl;
    return desktopScreenPaddingHorizontal;
  }
  static double getContentMaxWidth(double width) {
    if (isMobile(width)) return double.infinity;
    if (isLargeDesktop(width)) return maxWideLayoutWidth;
    return maxContentWidth;
  }
  static double getFeedMaxWidth(double width) {
    if (isMobile(width)) return double.infinity;
    if (isLargeDesktop(width)) return maxFeedWidth + 200;
    return maxFeedWidth;
  }
}