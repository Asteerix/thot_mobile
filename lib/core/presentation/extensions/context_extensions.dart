import 'package:flutter/material.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/utils/safe_navigation.dart';
extension ServiceContextExtensions on BuildContext {
  PostRepositoryImpl get postRepository =>
      ServiceLocator.instance.postRepository;
  void safeShowSnackBar(
    dynamic snackBarOrMessage, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    SafeNavigation.showSnackBar(
      this,
      snackBarOrMessage,
      duration: duration,
      action: action,
    );
  }
}