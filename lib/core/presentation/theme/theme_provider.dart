import 'package:flutter/material.dart';
import 'package:thot/core/presentation/theme/app_theme.dart';
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
}