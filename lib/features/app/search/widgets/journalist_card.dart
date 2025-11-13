import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';
import 'package:thot/shared/widgets/images/user_avatar.dart';

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
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              avatarUrl: journalist.avatarUrl,
              name: journalist.name ?? journalist.username,
              isJournalist: true,
              radius: 32,
            ),
            const SizedBox(height: 8),
            Text(
              journalist.name ?? journalist.username,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '${journalist.followersCount} abonnés',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.6),
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            FollowButton(
              userId: journalist.id,
              isFollowing: journalist.isFollowing,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
