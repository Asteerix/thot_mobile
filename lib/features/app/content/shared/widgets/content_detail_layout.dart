import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/widgets/post_actions.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';
import 'package:thot/core/routing/route_names.dart';

/// Layout de base commun pour tous les types de contenu (articles, vidéos, podcasts, questions)
class ContentDetailLayout extends StatelessWidget {
  final Post post;
  final Widget previewWidget;
  final String actionButtonText;
  final VoidCallback onActionPressed;
  final VoidCallback onComment;
  final List<Post>? opposingPosts;
  final List<Post>? relatedPosts;
  final Widget? additionalContent;
  const ContentDetailLayout({
    super.key,
    required this.post,
    required this.previewWidget,
    required this.actionButtonText,
    required this.onActionPressed,
    required this.onComment,
    this.opposingPosts,
    this.relatedPosts,
    this.additionalContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                previewWidget,
                _buildContentInfo(context),
                _buildActionButton(context),
                if (additionalContent != null) additionalContent!,
                const Spacer(),
              ],
            ),
          ),
          PostActions(
            post: post,
            onLike: () {},
            onComment: onComment,
            onSave: () {},
            opposingPosts: opposingPosts,
            relatedPosts: relatedPosts,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900]!.withOpacity(0.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
              splashRadius: 22,
              padding: const EdgeInsets.all(8),
            ),
          ),
          Image.asset(
            'assets/thot_only.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContentInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          _buildAuthorRow(context),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              post.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[800],
          ),
          child: ClipOval(
            child: post.journalist?.avatarUrl != null
                ? Image.network(
                    post.journalist!.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        (post.journalist?.name ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      (post.journalist?.name ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.journalist?.name ?? 'Anonyme',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '16h',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (post.journalist?.id != null && post.journalist!.id != null && post.journalist!.id!.isNotEmpty)
          FollowButton(
            userId: post.journalist!.id!,
            isFollowing: post.journalist?.isFollowing ?? false,
            compact: false,
          ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: onActionPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          actionButtonText,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

}
