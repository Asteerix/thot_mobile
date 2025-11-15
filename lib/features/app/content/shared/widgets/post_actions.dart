import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
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
  final List<Post>? opposingPosts;
  final List<Post>? relatedPosts;
  const PostActions({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onSave,
    this.onPostUpdated,
    this.opposingPosts,
    this.relatedPosts,
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
    required VoidCallback? onPressed,
    required String label,
    bool isActive = false,
    Color? iconColor,
  }) {
    final isEnabled = onPressed != null;
    final effectiveIconColor = iconColor ?? (isActive ? Colors.red : Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.red.withOpacity(0.15)
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
              color: isActive
                  ? Colors.red.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 20,
                ),
                if (label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: effectiveIconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
              ],
            ),
          ),
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.25),
              color.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              medianOrientation != null
                  ? PoliticalOrientationUtils.getIconData(medianOrientation)
                  : Icons.public,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                totalVotes > 0
                    ? PoliticalOrientationUtils.getLabel(medianOrientation)
                    : 'Non voté',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (totalVotes > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalVotes',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  void _showOpposingPostsSheet(BuildContext context, Post currentPost) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 OPENING OPPOSITION SHEET');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 Current post: ${currentPost.title}');
    print('📍 widget.opposingPosts count: ${widget.opposingPosts?.length ?? 0}');
    print('📍 currentPost.opposedByPosts count: ${currentPost.opposedByPosts?.length ?? 0}');
    if (widget.opposingPosts != null) {
      for (var i = 0; i < widget.opposingPosts!.length; i++) {
        print('   [opposingPosts $i] ${widget.opposingPosts![i].title}');
      }
    }
    if (currentPost.opposedByPosts != null) {
      for (var i = 0; i < currentPost.opposedByPosts!.length; i++) {
        print('   [opposedByPosts $i] postId: ${currentPost.opposedByPosts![i].postId}');
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final validOpposedByIds = currentPost.opposedByPosts
        ?.where((op) => op.postId.isNotEmpty)
        .map((op) => op.postId)
        .toList() ?? [];

    print('📍 Valid opposedBy IDs after filter: $validOpposedByIds');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OppositionBottomSheet(
        opposingPosts: widget.opposingPosts ?? [],
        opposedByPosts: validOpposedByIds,
        currentPostId: currentPost.id,
      ),
    );
  }

  void _showRelatedPostsSheet(BuildContext context, Post currentPost) {
    if (widget.relatedPosts == null || widget.relatedPosts!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Posts liés',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: widget.relatedPosts!.length,
                itemBuilder: (context, index) {
                  return _buildPostListItem(context, widget.relatedPosts![index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostListItem(BuildContext context, Post post) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: () {
        Navigator.pop(context);
        if (post.type == PostType.video) {
          context.push('/video-detail', extra: {'postId': post.id});
        } else if (post.type == PostType.podcast) {
          context.push('/podcast-detail', extra: {'postId': post.id});
        } else if (post.type == PostType.question) {
          context.push('/question-detail', extra: {'questionId': post.id});
        } else if (post.type == PostType.short) {
          context.push('/shorts', extra: {'initialShortId': post.id});
        } else {
          context.push('/article-detail', extra: {'postId': post.id});
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 60,
                color: Colors.grey[800],
                child: post.imageUrl != null || post.thumbnailUrl != null
                    ? Image.network(
                        post.thumbnailUrl ?? post.imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _getPostTypeIcon(post.type),
                          color: Colors.white54,
                          size: 24,
                        ),
                      )
                    : Icon(
                        _getPostTypeIcon(post.type),
                        color: Colors.white54,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getPostTypeIcon(post.type),
                        color: _getPostTypeColor(post.type),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.journalist?.name ?? 'Anonyme',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
      ),
    );
  }

  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.video:
        return Icons.videocam;
      case PostType.podcast:
        return Icons.podcasts;
      case PostType.question:
        return Icons.help_outline;
      default:
        return Icons.article;
    }
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.video:
        return Colors.red;
      case PostType.podcast:
        return Colors.purple;
      case PostType.question:
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
                  Expanded(
                    flex: 1,
                    child: _buildActionButton(
                      icon: Icons.favorite,
                      isActive: displayPost.isLiked,
                      label: displayPost.likesCount > 0
                          ? _formatNumber(displayPost.likesCount)
                          : '0',
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
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 1,
                    child: _buildActionButton(
                      icon: Icons.comment,
                      label: displayPost.commentsCount > 0
                          ? _formatNumber(displayPost.commentsCount)
                          : '0',
                      onPressed: () {
                        if (displayPost.id.startsWith('invalid_post_id_')) return;
                        widget.onComment();
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(flex: 1, child: SizedBox()),
                  const SizedBox(width: 6),
                  if (displayPost.type != PostType.question) ...[
                    Expanded(
                      flex: 1,
                      child: _buildActionButton(
                        icon: Icons.compare_arrows,
                        label: ((widget.opposingPosts?.length ?? 0) + (displayPost.opposedByPosts?.length ?? 0)).toString(),
                        iconColor: Colors.red,
                        onPressed: ((widget.opposingPosts != null && widget.opposingPosts!.isNotEmpty) ||
                                    (displayPost.opposedByPosts != null && displayPost.opposedByPosts!.isNotEmpty))
                            ? () => _showOpposingPostsSheet(context, displayPost)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    flex: 1,
                    child: _buildActionButton(
                      icon: displayPost.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      isActive: displayPost.isSaved,
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
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (displayPost.stats.views > 0) ...[
                    Container(
                        width: 100,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatNumber(displayPost.stats.views),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
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

class _OppositionBottomSheet extends StatefulWidget {
  final List<Post> opposingPosts;
  final List<String> opposedByPosts;
  final String currentPostId;

  const _OppositionBottomSheet({
    required this.opposingPosts,
    required this.opposedByPosts,
    required this.currentPostId,
  });

  @override
  State<_OppositionBottomSheet> createState() => _OppositionBottomSheetState();
}

class _OppositionBottomSheetState extends State<_OppositionBottomSheet>
    with SingleTickerProviderStateMixin {
  final _postRepository = ServiceLocator.instance.postRepository;
  List<Post> _loadedOpposedByPosts = [];
  bool _isLoading = false;
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });
    _loadOpposedByPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOpposedByPosts() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📥 LOADING OPPOSED BY POSTS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 opposedByPosts IDs to load: ${widget.opposedByPosts}');
    print('📍 Count: ${widget.opposedByPosts.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (widget.opposedByPosts.isEmpty) {
      print('⚠️ No opposedByPosts to load');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final loadedPosts = <Post>[];
      for (final postId in widget.opposedByPosts) {
        print('📥 Loading opposed by post: $postId');
        try {
          final response = await _postRepository.getPost(postId);
          print('✅ Received response for $postId');
          final post = Post.fromJson(response);
          print('✅ Parsed post: ${post.title}');
          loadedPosts.add(post);
        } catch (e) {
          print('❌ Error loading opposed by post $postId: $e');
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ OPPOSED BY POSTS LOADED: ${loadedPosts.length}');
      for (var i = 0; i < loadedPosts.length; i++) {
        print('   [$i] ${loadedPosts[i].title}');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (mounted) {
        setState(() {
          _loadedOpposedByPosts = loadedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOpposing = widget.opposingPosts.isNotEmpty;
    final hasOpposedBy = _loadedOpposedByPosts.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.compare_arrows, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Oppositions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, size: 14),
                        const SizedBox(width: 4),
                        Text('J\'oppose (${widget.opposingPosts.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 14),
                        const SizedBox(width: 4),
                        Text('M\'opposent (${_loadedOpposedByPosts.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOpposingTab(),
                      _buildOpposedByTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpposingTab() {
    if (widget.opposingPosts.isEmpty) {
      return _buildEmptyState('Aucune publication opposée');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.opposingPosts.length,
      itemBuilder: (context, index) {
        final post = widget.opposingPosts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPostListItem(context, post),
        );
      },
    );
  }

  Widget _buildOpposedByTab() {
    if (_loadedOpposedByPosts.isEmpty) {
      return _buildEmptyState('Aucune publication ne s\'oppose à celle-ci');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _loadedOpposedByPosts.length,
      itemBuilder: (context, index) {
        final post = _loadedOpposedByPosts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPostListItem(context, post),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.compare_arrows,
            color: Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostListItem(BuildContext context, Post post) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: () {
        Navigator.pop(context);
        if (post.type == PostType.video) {
          context.push('/video-detail', extra: {'postId': post.id});
        } else if (post.type == PostType.podcast) {
          context.push('/podcast-detail', extra: {'postId': post.id});
        } else if (post.type == PostType.question) {
          context.push('/question-detail', extra: {'questionId': post.id});
        } else if (post.type == PostType.short) {
          context.push('/shorts', extra: {'initialShortId': post.id});
        } else {
          context.push('/article-detail', extra: {'postId': post.id});
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 60,
                color: Colors.grey[800],
                child: post.imageUrl != null || post.thumbnailUrl != null
                    ? Image.network(
                        post.thumbnailUrl ?? post.imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _getPostTypeIcon(post.type),
                          color: Colors.white54,
                          size: 24,
                        ),
                      )
                    : Icon(
                        _getPostTypeIcon(post.type),
                        color: Colors.white54,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getPostTypeIcon(post.type),
                        color: _getPostTypeColor(post.type),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.journalist?.name ?? 'Anonyme',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
      ),
    );
  }

  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.video:
        return Icons.videocam;
      case PostType.podcast:
        return Icons.podcasts;
      case PostType.question:
        return Icons.help_outline;
      default:
        return Icons.article;
    }
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.video:
        return Colors.red;
      case PostType.podcast:
        return Colors.purple;
      case PostType.question:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
