import 'package:flutter/material.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/themes/app_colors.dart';
class FollowUtils {
  static Future<void> handleFollowAction(
    UserProfile user,
    Function(UserProfile) onSuccess,
    Function(String) onError,
  ) async {
    try {
      final wasFollowing = user.isFollowing;
      final profileRepository = ServiceLocator.instance.profileRepository;
      final result = wasFollowing
          ? await profileRepository.unfollowUser(user.id)
          : await profileRepository.followUser(user.id);
      result.fold(
        (failure) => onError(failure.message),
        (_) {
          final updatedUser = user.copyWith(
            isFollowing: !wasFollowing,
            followersCount: user.followersCount + (wasFollowing ? -1 : 1),
          );
          onSuccess(updatedUser);
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }
  static void showErrorSnackBar(BuildContext context, String error) {
    SafeNavigation.showSnackBar(
      context,
      SnackBar(
        content: Text(
          'Erreur: $error',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  static UserProfile getUpdatedUserProfile(
      UserProfile user, bool wasFollowing) {
    return user.copyWith(
      followersCount: user.followersCount + (wasFollowing ? -1 : 1),
      isFollowing: !wasFollowing,
    );
  }
}