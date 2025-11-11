import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/shared/widgets/safe_network_image.dart';
import 'package:thot/core/constants/asset_paths.dart';
import 'package:thot/features/profile/presentation/shared/widgets/follow_button.dart';
class JournalistCard extends StatelessWidget {
  final UserProfile journalist;
  final VoidCallback onFollow;
  const JournalistCard({
    super.key,
    required this.journalist,
    required this.onFollow,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        context.push('/profile', extra: {
          'userId': journalist.id,
          'isCurrentUser': false,
          'forceReload': true,
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: SafeNetworkImage(
                  url: journalist.avatarUrl,
                  placeholderAsset: AssetPaths.defaultJournalistAvatar,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              journalist.name ?? journalist.username,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '${journalist.followersCount} abonnés',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6),
                fontSize: 8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FollowButton(
              userId: journalist.id,
              isFollowing: journalist.isFollowing,
              onFollowChanged: (isFollowing) {
                onFollow();
              },
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}