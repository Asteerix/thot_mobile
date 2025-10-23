import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thot/shared/widgets/common/shimmer_loading.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/media/utils/url_helper.dart';
import 'profile_logger.dart';
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String userId;
  final bool isCurrentUser;
  final VoidCallback onImageUpdated;
  final String role;
  static const double imageSize = 100;
  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    required this.userId,
    required this.isCurrentUser,
    required this.onImageUpdated,
    required this.role,
  });
  String get _defaultAvatarPath {
    return role == UserTypes.journalist
        ? UIConstants.defaultJournalistAvatarPath
        : UIConstants.defaultUserAvatarPath;
  }
  Widget _buildAvatarImage() {
    final processedUrl = UrlHelper.buildMediaUrl(avatarUrl);
    if (processedUrl == null || processedUrl.isEmpty) {
      return _buildDefaultAvatar();
    }
    if (processedUrl
            .contains('/assets/images/defaults/default_user_avatar.png') ||
        processedUrl.contains(
            '/assets/images/defaults/default_journalist_avatar.png')) {
      return _buildDefaultAvatar();
    }
    if (processedUrl.startsWith('/assets/') ||
        processedUrl.startsWith('assets/')) {
      final assetPath = processedUrl.startsWith('/')
          ? processedUrl.substring(1)
          : processedUrl;
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: imageSize,
            height: imageSize,
            errorBuilder: (context, error, stackTrace) {
              ProfileLogger.e('Error loading asset avatar', error: error);
              return _buildDefaultAvatar();
            },
          ),
        ),
      );
    }
    if (processedUrl.startsWith('http://') ||
        processedUrl.startsWith('https://')) {
      return Container(
        width: imageSize,
        height: imageSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            key:
                ValueKey(processedUrl),
            imageUrl: processedUrl,
            cacheKey: processedUrl,
            fit: BoxFit.cover,
            width: imageSize,
            height: imageSize,
            httpHeaders: const {
              'ngrok-skip-browser-warning': 'true',
            },
            placeholder: (context, url) => const ShimmerLoading(
              width: imageSize,
              height: imageSize,
              borderRadius: imageSize / 2,
            ),
            errorWidget: (context, url, error) {
              ProfileLogger.e('Error loading avatar from $processedUrl', error: error);
              return _buildDefaultAvatar();
            },
          ),
        ),
      );
    }
    ProfileLogger.e(
        'Invalid avatar URL format after processing: $processedUrl (original: $avatarUrl)');
    return _buildDefaultAvatar();
  }
  Widget _buildDefaultAvatar() {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Center(
          child: Image.asset(
            _defaultAvatarPath,
            fit: BoxFit.cover,
            width: imageSize,
            height: imageSize,
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Stack(
          children: [
            Hero(
              tag: 'profile-avatar-$userId',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageSize / 2),
                child: _buildAvatarImage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}