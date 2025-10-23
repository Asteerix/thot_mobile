import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/shared/widgets/safe_network_image.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
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
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.black : Colors.white,
              ),
              child: ClipOval(
                child: SafeNetworkImage(
                  url: journalist.avatarUrl,
                  placeholderAsset:
                      'assets/images/defaults/default_journalist_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
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
                      if (journalist.isVerified) ...[
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
            ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: journalist.isFollowing
                    ? (isDark ? Colors.black : Colors.white)
                    : Theme.of(context).primaryColor,
                foregroundColor: journalist.isFollowing
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                journalist.isFollowing ? 'Abonné' : 'S\'abonner',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}