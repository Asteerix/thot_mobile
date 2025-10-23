import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/shared/widgets/safe_network_image.dart';
import 'package:thot/core/constants/asset_paths.dart';
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
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
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
                GestureDetector(
                  onTap: onFollow,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: journalist.isFollowing
                          ? (isDark ? Colors.black : Colors.white)
                          : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      journalist.isFollowing ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              journalist.name ?? journalist.username,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 12,
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
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}