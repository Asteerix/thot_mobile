import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/features/app/content/shared/widgets/post_actions.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/posts/questions/widgets/voting_dialog.dart';
import 'package:thot/features/app/content/shared/widgets/political_orientation_utils.dart';

class PostActions extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onSave;
  final Function(Post)? onPostUpdated;
  const PostActions({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onSave,
    this.onPostUpdated,
  });
  @override
  State<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends State<PostActions> {
  late Post _currentPost;
  final EventBus _eventBus = EventBus();
  bool _isLikeProcessing = false;
  bool _isBookmarkProcessing = false;
  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsStateProvider = context.read<PostsStateProvider>();
      postsStateProvider.updatePostSilently(_currentPost);
    });
  }

  @override
  void didUpdateWidget(PostActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _currentPost = widget.post;
    } else if (oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.likesCount != widget.post.likesCount) {
      _currentPost = widget.post;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).floor()}M';
    } else if (number >= 1000) {
      return '${(number / 1000).floor()}K';
    }
    return number.toString();
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.red.withOpacity(0.15)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 24,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.red : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPoliticalOrientationButton(Post post) {
    final votes = post.politicalOrientation.userVotes;
    final frequencies = [
      votes['extremelyConservative'] ?? 0,
      votes['conservative'] ?? 0,
      votes['neutral'] ?? 0,
      votes['progressive'] ?? 0,
      votes['extremelyProgressive'] ?? 0,
    ];
    final totalVotes = frequencies.fold(0, (sum, freq) => sum + freq);
    PoliticalOrientation? medianOrientation;
    if (totalVotes > 0) {
      final medianPosition = totalVotes / 2;
      var cumulative = 0;
      for (var i = 0; i < frequencies.length; i++) {
        cumulative += frequencies[i];
        if (cumulative > medianPosition) {
          medianOrientation = PoliticalOrientation.values[i];
          break;
        }
      }
    }
    final color = medianOrientation != null
        ? PoliticalOrientationUtils.getColor(medianOrientation)
        : Colors.grey;
    return InkWell(
      onTap: () {
        if (post.id.startsWith('invalid_post_id_')) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => VotingDialog(
            post: post,
            onVoteChanged: (updatedPost) {
              if (widget.onPostUpdated != null) {
                widget.onPostUpdated!(updatedPost);
              }
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.public,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                totalVotes > 0
                    ? PoliticalOrientationUtils.getLabel(medianOrientation)
                    : 'Non voté',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (totalVotes > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalVotes',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PostsStateProvider, Post?>(
      selector: (context, provider) => provider.getPost(_currentPost.id),
      builder: (context, providerPost, _) {
        final displayPost = providerPost ?? _currentPost;
        return Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.favorite,
                    isActive: displayPost.isLiked,
                    label: displayPost.likesCount > 0
                        ? _formatNumber(displayPost.likesCount)
                        : '',
                    onPressed: () async {
                      if (_isLikeProcessing) return;
                      if (displayPost.id.startsWith('invalid_post_id_')) return;
                      setState(() {
                        _isLikeProcessing = true;
                      });
                      final postsStateProvider =
                          context.read<PostsStateProvider>();
                      try {
                        await postsStateProvider.toggleLike(displayPost.id);
                      } catch (e) {
                        if (!mounted) return;
                        SafeNavigation.showSnackBar(
                          context,
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _isLikeProcessing = false;
                            });
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.comment,
                    label: displayPost.commentsCount > 0
                        ? _formatNumber(displayPost.commentsCount)
                        : '',
                    onPressed: () {
                      if (displayPost.id.startsWith('invalid_post_id_')) return;
                      widget.onComment();
                    },
                  ),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.bookmark,
                    label: '',
                    onPressed: () async {
                      debugPrint(
                          '🎯 [POST_ACTIONS] Bookmark button pressed | postId: ${displayPost.id}, isProcessing: $_isBookmarkProcessing');
                      if (_isBookmarkProcessing) {
                        debugPrint(
                            '⚠️ [POST_ACTIONS] Bookmark already processing, ignoring click');
                        return;
                      }
                      if (displayPost.id.startsWith('invalid_post_id_')) return;
                      setState(() {
                        _isBookmarkProcessing = true;
                      });
                      debugPrint(
                          '🔒 [POST_ACTIONS] Bookmark processing locked | postId: ${displayPost.id}');
                      final postsStateProvider =
                          context.read<PostsStateProvider>();
                      try {
                        await postsStateProvider.toggleBookmark(displayPost.id);
                        final updatedPost =
                            postsStateProvider.getPost(displayPost.id);
                        if (updatedPost != null && mounted) {
                          SafeNavigation.showSnackBar(
                            context,
                            SnackBar(
                              content: Text(updatedPost.isSaved
                                  ? 'Ajouté aux favoris'
                                  : 'Retiré des favoris'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint(
                            '❌ [POST_ACTIONS] Bookmark error | error: $e');
                        if (!mounted) return;
                        SafeNavigation.showSnackBar(
                          context,
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _isBookmarkProcessing = false;
                            });
                            debugPrint(
                                '🔓 [POST_ACTIONS] Bookmark processing unlocked | postId: ${displayPost.id}');
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (displayPost.stats.views > 0) ...[
                    Container(
                      width: 95,
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 45,
                            child: Text(
                              _formatNumber(displayPost.stats.views),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: _buildPoliticalOrientationButton(displayPost),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
