import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/shared/widgets/images/app_avatar.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';
import 'package:thot/features/app/profile/widgets/badges.dart';
import 'package:thot/shared/widgets/images/safe_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeedItem extends StatefulWidget {
  final VoidCallback onTap;
  final Post post;
  final double? width;
  final double? height;
  final Function(Post)? onPostUpdated;
  const FeedItem({
    super.key,
    required this.onTap,
    required this.post,
    this.width,
    this.height,
    this.onPostUpdated,
  });
  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late Post _currentPost;
  final _eventBus = EventBus();
  final List<StreamSubscription> _subscriptions = [];
  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _subscriptions.add(
      _eventBus.on<PostLikedEvent>().listen((event) {
        if (event.postId == _currentPost.id && mounted) {
          setState(() {
            _currentPost = _currentPost.copyWith(
              interactions: _currentPost.interactions.copyWith(
                isLiked: event.isLiked,
                likes: event.likeCount,
              ),
            );
          });
        }
      }),
    );
    _subscriptions.add(
      _eventBus.on<PostBookmarkedEvent>().listen((event) {
        if (event.postId == _currentPost.id && mounted) {
          setState(() {
            _currentPost = _currentPost.copyWith(
              interactions: _currentPost.interactions.copyWith(
                isSaved: event.isBookmarked,
                bookmarks: event.bookmarkCount,
              ),
            );
          });
        }
      }),
    );
    _subscriptions.add(
      _eventBus.on<PostVotedEvent>().listen((event) {
        if (event.postId == _currentPost.id && mounted) {
          {
            setState(() {
              _currentPost = _currentPost.copyWith(
                politicalOrientation:
                    _currentPost.politicalOrientation.copyWith(
                  userVotes: event.voteDistribution,
                  dominantView:
                      _getPoliticalOrientationFromString(event.dominantView),
                ),
              );
            });
          }
        }
      }),
    );
    _subscriptions.add(
      _eventBus.on<PostCommentedEvent>().listen((event) {
        if (event.postId == _currentPost.id && mounted) {
          setState(() {
            _currentPost = _currentPost.copyWith(
              interactions: _currentPost.interactions.copyWith(
                comments: event.commentCount,
              ),
            );
          });
        }
      }),
    );
    _subscriptions.add(
      _eventBus.on<ProfileUpdatedEvent>().listen((event) async {
        if (_currentPost.journalist?.id == event.userId && mounted) {
          if (_currentPost.journalist?.avatarUrl != null &&
              _currentPost.journalist!.avatarUrl!.isNotEmpty) {
            try {
              await CachedNetworkImage.evictFromCache(
                  _currentPost.journalist!.avatarUrl!);
            } catch (e) {
              // Silently fail cache eviction
            }
          }
          setState(() {});
        }
      }),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(FeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _currentPost = widget.post;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textScaler = MediaQuery.of(context).textScaler;
    final colorScheme = Theme.of(context).colorScheme;
    return Selector<PostsStateProvider, Post?>(
      selector: (context, provider) => provider.getPost(_currentPost.id),
      builder: (context, latestPost, child) {
        final displayPost = latestPost ?? _currentPost;
        if (latestPost != null && latestPost != _currentPost) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentPost != latestPost) {
              setState(() {
                _currentPost = latestPost;
              });
            }
          });
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 400;
            final titleFontSize = textScaler.scale(isWideScreen ? 18.0 : 16.0);
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.surface.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: widget.onTap,
                onDoubleTap: () {
                  _handleLike();
                },
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ShaderMask(
                                shaderCallback: (rect) {
                                  return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colorScheme.surface.withOpacity(0.1),
                                      colorScheme.surface.withOpacity(0.7),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.darken,
                                child: Builder(builder: (context) {
                                  String? imageUrl;
                                  if (displayPost.type == PostType.video) {
                                    imageUrl = displayPost.thumbnailUrl ??
                                        displayPost.imageUrl;
                                  } else {
                                    imageUrl = displayPost.imageUrl ??
                                        displayPost.thumbnailUrl;
                                  }
                                  if (imageUrl != null && imageUrl.isNotEmpty) {
                                    final cleanUrl = imageUrl.trim();
                                    if (cleanUrl.isEmpty ||
                                        cleanUrl.toLowerCase() == 'null' ||
                                        cleanUrl == 'undefined' ||
                                        (cleanUrl.startsWith('file://') &&
                                            cleanUrl.length <= 8)) {
                                      imageUrl = null;
                                    }
                                  }
                                  if (displayPost.type == PostType.video) {
                                    developer.log(
                                      'Video post image selection',
                                      name: 'FeedItem',
                                      error: {
                                        'postId': displayPost.id,
                                        'title': displayPost.title,
                                        'type': displayPost.type.toString(),
                                        'thumbnailUrl':
                                            displayPost.thumbnailUrl,
                                        'imageUrl': displayPost.imageUrl,
                                        'selectedUrl': imageUrl,
                                        'isValid': imageUrl != null,
                                      },
                                    );
                                  }
                                  return SafeNetworkImage(
                                    url: imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 800,
                                    memCacheHeight: 450,
                                    filterQuality: FilterQuality.medium,
                                  );
                                }),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTypeOverlay(displayPost),
                                    _buildPublicOpinionBadge(displayPost
                                        .politicalOrientation.dominantView),
                                  ],
                                ),
                              ),
                              if (displayPost.hasOppositions)
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.swap_horiz,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${displayPost.oppositions.length} opposition${displayPost.oppositions.length > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (displayPost.journalist?.id != null)
                                  GestureDetector(
                                    onTap: () {
                                      context.replaceNamed(
                                        RouteNames.profile,
                                        extra: {
                                          'userId':
                                              displayPost.journalist?.id ?? '',
                                          'forceReload': true
                                        },
                                      );
                                    },
                                    child: AppAvatar(
                                      avatarUrl:
                                          displayPost.journalist?.avatarUrl,
                                      radius: 16,
                                      isJournalist: true,
                                    ),
                                  )
                                else
                                  const AppAvatar(
                                    avatarUrl: null,
                                    radius: 16,
                                    isJournalist: false,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (displayPost.journalist?.id != null)
                                        GestureDetector(
                                          onTap: () {
                                            context.replaceNamed(
                                              RouteNames.profile,
                                              extra: {
                                                'userId': displayPost
                                                        .journalist?.id ??
                                                    '',
                                                'forceReload': true
                                              },
                                            );
                                          },
                                          child: Text(
                                            displayPost.journalist?.name ??
                                                'Unknown',
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 14,
                                              fontFamily: 'Tailwind',
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      else
                                        Text(
                                          displayPost.journalist?.name ??
                                              'Unknown',
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 14,
                                            fontFamily: 'Tailwind',
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (displayPost.journalist?.isVerified ??
                                          false) ...[
                                        const SizedBox(width: 4),
                                        const VerificationBadge(size: 16),
                                      ],
                                      Text(
                                        ' • ${_getTimeAgo(displayPost.createdAt)}',
                                        style: TextStyle(
                                          color: colorScheme.outline
                                              .withOpacity(0.6),
                                          fontSize: 13,
                                          fontFamily: 'Tailwind',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, _) {
                                    final currentUserId =
                                        authProvider.userProfile?.id;
                                    final journalistId =
                                        displayPost.journalist?.id;
                                    if (journalistId == null ||
                                        currentUserId == null ||
                                        currentUserId == journalistId) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: FollowButton(
                                        userId: journalistId,
                                        isFollowing: displayPost
                                                .journalist?.isFollowing ??
                                            false,
                                        compact: true,
                                        onFollowChanged: (isFollowing) {
                                          setState(() {
                                            _currentPost =
                                                _currentPost.copyWith(
                                              journalist: JournalistProfile(
                                                id: displayPost.journalist?.id,
                                                name: displayPost
                                                        .journalist?.name ??
                                                    '',
                                                username: displayPost
                                                    .journalist?.username,
                                                avatarUrl: displayPost
                                                    .journalist?.avatarUrl,
                                                specialties: displayPost
                                                        .journalist
                                                        ?.specialties ??
                                                    [],
                                                history: displayPost
                                                    .journalist?.history,
                                                isVerified: displayPost
                                                        .journalist
                                                        ?.isVerified ??
                                                    false,
                                                isFollowing: isFollowing,
                                              ),
                                            );
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              displayPost.title,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatChip(
                                  displayPost.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite,
                                  _formatCount(displayPost.interactions.likes),
                                  color: displayPost.isLiked
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                  compact: false,
                                  onTap: _handleLike,
                                ),
                                const SizedBox(width: 16),
                                _buildStatChip(
                                  Icons.comment,
                                  _formatCount(
                                      displayPost.interactions.comments),
                                  color: colorScheme.onSurface,
                                  compact: false,
                                ),
                                if (displayPost.hasOppositions &&
                                    displayPost.politicalOrientation.hasVoted ==
                                        false) ...[
                                  const SizedBox(width: 16),
                                  _buildStatChip(
                                    Icons.swap_horiz,
                                    _formatCount(
                                        displayPost.oppositions.length),
                                    color: colorScheme.error,
                                    compact: false,
                                  ),
                                ],
                                const Spacer(),
                                _buildStatChip(
                                  displayPost.isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark,
                                  '',
                                  color: colorScheme.onSurface,
                                  compact: false,
                                  onTap: _handleBookmark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeOverlay(Post post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor(post.type),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(post.type),
              color: Theme.of(context).colorScheme.onSurface,
              size: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _getTypeLabel(post.type),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Tailwind',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicOpinionBadge(PoliticalOrientation? orientation) {
    final color = _getPoliticalViewColor(orientation);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: _getPoliticalViewIcon(orientation),
      ),
    );
  }

  Widget _getPoliticalViewIcon(PoliticalOrientation? view) {
    return Icon(
      Icons.public,
      size: 20,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildStatChip(IconData icon, String count,
      {required Color color, bool compact = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 16 : 18,
              color: color,
            ),
            if (count.isNotEmpty) ...[
              SizedBox(width: compact ? 2 : 4),
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Tailwind',
                  letterSpacing: 0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    }
    return 'À l\'instant';
  }

  String _getTypeLabel(PostType type) {
    return switch (type) {
      PostType.article => 'ARTICLE',
      PostType.video => 'VIDÉO',
      PostType.podcast => 'PODCAST',
      PostType.short => 'SHORT',
      PostType.question => 'QUESTION',
      PostType.live => 'LIVE',
      PostType.poll => 'SONDAGE',
      PostType.testimony => 'TÉMOIGNAGE',
      PostType.documentation => 'DOCUMENTATION',
      PostType.opinion => 'OPINION',
    };
  }

  IconData _getTypeIcon(PostType type) {
    return switch (type) {
      PostType.article => Icons.article,
      PostType.video => Icons.play_circle,
      PostType.podcast => Icons.mic,
      PostType.short => Icons.videocam,
      PostType.question => Icons.help_outline,
      PostType.live => Icons.tv,
      PostType.poll => Icons.bar_chart,
      PostType.testimony => Icons.mic,
      PostType.documentation => Icons.folder,
      PostType.opinion => Icons.comment,
    };
  }

  Color _getTypeColor(PostType type) {
    return switch (type) {
      PostType.article => Theme.of(context).colorScheme.primary,
      PostType.video => Theme.of(context).colorScheme.error,
      PostType.podcast => AppColors.success,
      PostType.short => AppColors.purple,
      PostType.question => AppColors.warning,
      PostType.live => AppColors.red,
      PostType.poll => AppColors.blue,
      PostType.testimony => AppColors.green,
      PostType.documentation => AppColors.purple,
      PostType.opinion => AppColors.orange,
    };
  }

  Color _getPoliticalViewColor(PoliticalOrientation? view) {
    return switch (view) {
      PoliticalOrientation.extremelyProgressive =>
        AppColors.extremelyProgressive,
      PoliticalOrientation.progressive => AppColors.progressive,
      PoliticalOrientation.extremelyConservative =>
        AppColors.extremelyConservative,
      PoliticalOrientation.conservative => AppColors.conservative,
      PoliticalOrientation.neutral => AppColors.neutral,
      null => AppColors.neutral,
    };
  }

  Future<void> _handleLike() async {
    HapticFeedback.lightImpact();
    final postsStateProvider = context.read<PostsStateProvider>();
    try {
      await postsStateProvider.toggleLike(_currentPost.id);
      final updatedPost = postsStateProvider.getPost(_currentPost.id);
      if (updatedPost != null && mounted) {
        _eventBus.fire(PostLikedEvent(
          postId: updatedPost.id,
          isLiked: updatedPost.isLiked,
          likeCount: updatedPost.likesCount,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleBookmark() async {
    HapticFeedback.lightImpact();
    final wasSaved = _currentPost.isSaved;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(!wasSaved ? 'Ajouté aux favoris' : 'Retiré des favoris'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
    final postsStateProvider = context.read<PostsStateProvider>();
    try {
      await postsStateProvider.toggleBookmark(_currentPost.id);
      final updatedPost = postsStateProvider.getPost(_currentPost.id);
      if (updatedPost != null && mounted) {
        _eventBus.fire(PostBookmarkedEvent(
          postId: updatedPost.id,
          isBookmarked: updatedPost.isSaved,
          bookmarkCount: updatedPost.interactions.bookmarks,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  PoliticalOrientation? _getPoliticalOrientationFromString(String? value) {
    if (value == null) return null;
    try {
      return PoliticalOrientation.values.firstWhere(
        (o) => o.toString().split('.').last == value,
      );
    } catch (e) {
      return null;
    }
  }
}
