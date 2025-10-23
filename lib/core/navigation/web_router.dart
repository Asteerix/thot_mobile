import 'package:flutter/material.dart';
import 'route_names.dart';
@Deprecated('Not used - see AppRouter in app_router.dart instead')
class WebRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    return null;
  }
  static void _navigate(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }
  static String? _extractPathParameter(String? routeName, String paramName) {
    if (routeName == null) return null;
    final segments = routeName.split('/');
    for (int i = 0; i < segments.length; i++) {
      if (segments[i] == ':$paramName' && i > 0) {
        return segments.length > i + 1 ? segments[i + 1] : null;
      }
    }
    return null;
  }
  static String getInitialRoute(bool isAuthenticated, bool isAdmin) {
    if (!isAuthenticated) return RouteNames.login;
    if (isAdmin) return RouteNames.adminDashboard;
    return RouteNames.feed;
  }
  static Map<String, WidgetBuilder> getWebRoutes() {
    return {};
  }
}