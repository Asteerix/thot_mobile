import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/features/app/profile/widgets/badges.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';
import 'package:thot/shared/widgets/images/user_avatar.dart';
class JournalistListItem extends StatelessWidget {
  final UserProfile journalist;
  final VoidCallback onFollow;
  const JournalistListItem({
    super.key,
    required this.journalist,
    required this.onFollow,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        context.push('/profile', extra: {
          'userId': journalist.id,
          'isCurrentUser': false,
          'forceReload': true,
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: journalist.avatarUrl,
              name: journalist.name ?? journalist.username,
              isJournalist: true,
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          journalist.name ?? journalist.username,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (journalist.pressCard != null && journalist.pressCard!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        const VerificationBadge(size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${journalist.username}',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${journalist.followersCount} abonnés',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      if (journalist.organization != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${journalist.organization}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FollowButton(
              userId: journalist.id,
              isFollowing: journalist.isFollowing,
            ),
          ],
        ),
      ),
    );
  }
}