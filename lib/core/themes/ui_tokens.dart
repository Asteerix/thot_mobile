import 'package:flutter/material.dart';
class UITokens {
  static const Color surfaceContainerHighest = Color(0xFFF5F5F5);
  @Deprecated('Non utilisé dans la codebase. Considérer la suppression.')
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  @Deprecated('Non utilisé. Préférer AppColors.warning de app_colors.dart')
  static const Color warning = Color(0xFFFFA000);
  static const Color success = Color(0xFF4CAF50);
  @Deprecated('Non utilisé. Préférer AppColors.onSurface de app_colors.dart')
  static const Color onSurface = Color(0xFF000000);
  @Deprecated('Non utilisé. Préférer les tokens de app_colors.dart')
  static const Color onPrimary = Color(0xFFFFFFFF);
  @Deprecated('Non utilisé. Préférer les tokens de app_colors.dart')
  static const Color onSecondary = Color(0xFF000000);
  static const Color neutral10 = Color(0xFFFAFAFA);
  @Deprecated('Duplique surfaceContainerHighest. Considérer la suppression.')
  static const Color neutral20 = Color(0xFFF5F5F5);
  @Deprecated('Duplique surfaceContainer. Considérer la suppression.')
  static const Color neutral30 = Color(0xFFEEEEEE);
  @Deprecated('Non utilisé. Considérer la suppression.')
  static const Color neutral40 = Color(0xFFE0E0E0);
  @Deprecated('Non utilisé. Considérer la suppression.')
  static const Color neutral50 = Color(0xFF9E9E9E);
  @Deprecated('Non utilisé. Considérer la suppression.')
  static const Color neutral60 = Color(0xFF757575);
  @Deprecated('Non utilisé. Considérer la suppression.')
  static const Color neutral70 = Color(0xFF616161);
  @Deprecated('Non utilisé. Considérer la suppression.')
  static const Color neutral80 = Color(0xFF424242);
  @Deprecated('Non utilisé. Considérer la suppression.')
  static const Color neutral90 = Color(0xFF212121);
}
@Deprecated('Utiliser AppColors de app_colors.dart à la place pour éviter duplication')
class AppColors {
  static const Color progressive = Color(0xFF2196F3);
  static const Color extremelyProgressive = Color(0xFFFFFFFF);
  static const Color primary = UITokens.primary;
  static const Color secondary = UITokens.secondary;
  static const Color error = UITokens.error;
  static const Color surface = UITokens.surface;
  static const Color background = UITokens.neutral10;
}
class AppSpacing {
  static const double xSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xLarge = 32.0;
  @Deprecated('Non utilisé dans la codebase. Considérer la suppression.')
  static const double xxLarge = 48.0;
}