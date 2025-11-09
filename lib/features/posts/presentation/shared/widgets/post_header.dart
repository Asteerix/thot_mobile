import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
import 'package:thot/shared/widgets/common/app_avatar.dart';
import 'package:thot/features/profile/presentation/shared/widgets/follow_button.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
class PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final bool showFollowButton;
  final bool isVideoPost;
  const PostHeader({
    super.key,
    required this.post,
    required this.onBack,
    this.onShare,
    this.onReport,
    this.showFollowButton = true,
    this.isVideoPost = false,
  });
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}a';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
  void _navigateToProfile(BuildContext context) {
    if (post.journalist?.id != null) {
      context.pushNamed(
        RouteNames.profile,
        extra: {
          'userId': post.journalist!.id,
          'forceReload': true,
        },
      );
    }
  }
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (onShare != null)
              ListTile(
                leading: Icon(Icons.share, color: Colors.white),
                title: const Text(
                  'Partager',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onShare?.call();
                },
              ),
            if (onReport != null)
              ListTile(
                leading: Icon(Icons.flag, color: Colors.white),
                title: const Text(
                  'Signaler',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onReport?.call();
                },
              ),
            ListTile(
              leading: Icon(Icons.link, color: Colors.white),
              title: const Text(
                'Copier le lien',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
    final isOwnPost = currentUserId != null &&
                      post.journalist?.id != null &&
                      currentUserId == post.journalist!.id;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new),
                iconSize: 22,
                color: Colors.white,
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _navigateToProfile(context),
              child: AppAvatar(
                avatarUrl: post.journalist?.avatarUrl,
                radius: 16,
                isJournalist: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToProfile(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.journalist?.name ?? 'Auteur inconnu',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.journalist?.isVerified ?? false) ...[
                          const SizedBox(width: 4),
                          const VerificationBadge(size: 14),
                        ],
                      ],
                    ),
                    Text(
                      _getTimeAgo(post.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showFollowButton && post.journalist?.id != null && !isOwnPost)
              FollowButton(
                userId: post.journalist!.id!,
                isFollowing: post.journalist!.isFollowing,
                compact: true,
              ),
          ],
        ),
      ),
    );
  }
}