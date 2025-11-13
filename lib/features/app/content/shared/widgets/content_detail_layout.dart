import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/widgets/post_actions.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/feed/shared/main_screen.dart';
import 'package:thot/shared/widgets/images/user_avatar.dart';

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
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
    final isOwnPost = currentUserId != null &&
        post.journalist?.id != null &&
        currentUserId == post.journalist!.id;

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
          if (isOwnPost)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
                border: Border.all(
                  color: Colors.red.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _showDeleteConfirmation(context),
                splashRadius: 22,
                padding: const EdgeInsets.all(8),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Supprimer le post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce post ? Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(context);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    try {
      final postsStateProvider = context.read<PostsStateProvider>();
      await postsStateProvider.deletePost(post.id);

      if (context.mounted) {
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Post supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _navigateToJournalistProfile(BuildContext context, String? journalistId, bool isOwnPost) {
    if (journalistId == null || journalistId.isEmpty) return;

    // Toujours fermer le viewer actuel avant de naviguer
    context.pop();

    // Puis naviguer vers le profil
    if (isOwnPost) {
      context.go(RouteNames.profile);
    } else {
      context.go(
        RouteNames.profile,
        extra: {
          'userId': journalistId,
          'isCurrentUser': false,
          'forceReload': true,
        },
      );
    }
  }

  Widget _buildAuthorRow(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
    final journalistId = post.journalist?.id;
    final isOwnPost = currentUserId != null &&
        journalistId != null &&
        journalistId.isNotEmpty &&
        currentUserId == journalistId;

    final shouldShowFollow = journalistId != null &&
        journalistId.isNotEmpty &&
        !isOwnPost;

    print('🔍 [CONTENT_DETAIL] Post: ${post.title}');
    print('   - Journalist ID: $journalistId');
    print('   - Current User ID: $currentUserId');
    print('   - Is Own Post: $isOwnPost');
    print('   - Should Show Follow: $shouldShowFollow');

    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToJournalistProfile(context, journalistId, isOwnPost),
          child: UserAvatar(
            avatarUrl: post.journalist?.avatarUrl,
            name: post.journalist?.name ?? post.journalist?.username,
            isJournalist: true,
            radius: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToJournalistProfile(context, journalistId, isOwnPost),
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
        ),
        if (shouldShowFollow)
          FollowButton(
            userId: journalistId,
            isFollowing: post.journalist?.isFollowing ?? false,
            compact: false,
          )
        else if (!isOwnPost && post.journalist != null)
          Opacity(
            opacity: 0.5,
            child: Container(
              height: 36,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.grey, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'N/A',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (isOwnPost)
          const SizedBox(width: 110),
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
