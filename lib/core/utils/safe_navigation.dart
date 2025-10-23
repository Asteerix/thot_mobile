import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart' as material show showDialog, showModalBottomSheet;
class SafeNavigation {
  static Future<T?> push<T>(BuildContext context, Route<T> route) {
    if (context.mounted) {
      return Navigator.push<T>(context, route);
    }
    return Future.value(null);
  }
  static void pop(BuildContext context, [dynamic result]) {
    if (context.mounted) {
      Navigator.pop(context, result);
    }
  }
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
  static void navigateTo(BuildContext context, String route, {Object? extra}) {
    if (context.mounted) {
      context.go(route, extra: extra);
    }
  }
  static void pushNamed(BuildContext context, String route, {Object? extra}) {
    if (context.mounted) {
      context.push(route, extra: extra);
    }
  }
  static void pushNamedAndRemoveUntil(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? extra,
  }) {
    if (context.mounted) {
      context.go(routeName, extra: extra);
    }
  }
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    if (context.mounted) {
      return material.showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
      );
    }
    return Future.value();
  }
  static Future<T?> showModalBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    if (context.mounted) {
      return material.showModalBottomSheet<T>(
        context: context,
        builder: builder,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
      );
    }
    return Future.value();
  }
  static void showSnackBar(
    BuildContext context,
    dynamic snackBarOrMessage, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (context.mounted) {
      if (snackBarOrMessage is SnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(snackBarOrMessage);
      } else if (snackBarOrMessage is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackBarOrMessage),
            duration: duration,
            action: action,
          ),
        );
      }
    }
  }
}