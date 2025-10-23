import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thot/features/media/utils/url_helper.dart';
import 'profile_logger.dart';
class ProfileCover extends StatelessWidget {
  final String? coverUrl;
  final bool isCurrentUser;
  final VoidCallback onImageUpdated;
  const ProfileCover({
    super.key,
    this.coverUrl,
    required this.isCurrentUser,
    required this.onImageUpdated,
  });
  @override
  Widget build(BuildContext context) {
    final processedUrl = UrlHelper.buildMediaUrl(coverUrl);
    return Stack(
      children: [
        if (processedUrl?.isNotEmpty ?? false)
          CachedNetworkImage(
            imageUrl: processedUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.black,
            ),
            errorWidget: (context, url, error) {
              ProfileLogger.e(
                  'Error loading cover image from $processedUrl (original: $coverUrl)',
                  error: error);
              return Container(
                color: Colors.black,
              );
            },
          )
        else
          Image.asset(
            'assets/images/default_cover.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        if (isCurrentUser)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
      ],
    );
  }
}