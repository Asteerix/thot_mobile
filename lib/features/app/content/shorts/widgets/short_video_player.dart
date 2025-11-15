import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/shared/media/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import 'package:thot/features/app/content/posts/questions/widgets/voting_dialog.dart';
import 'package:thot/features/app/content/shared/widgets/political_orientation_utils.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/shared/widgets/images/user_avatar.dart';
import 'package:thot/core/routing/route_names.dart';

class ShortVideoPlayer extends StatefulWidget {
  final Post post;
  final PostRepositoryImpl shortsService;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onComment;
  const ShortVideoPlayer({
    super.key,
    required this.post,
    required this.shortsService,
    this.onLike,
    this.onDislike,
    this.onComment,
  });
  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isDescriptionExpanded = false;
  late Post _currentPost;
  bool _isLikeProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsStateProvider = context.read<PostsStateProvider>();
      postsStateProvider.updatePostSilently(_currentPost);
    });
  }

  @override
  void didUpdateWidget(ShortVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
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

  Future<void> _initializeVideo() async {
    final url = widget.post.videoUrl;
    if (url == null || url.isEmpty) {
      debugPrint('ShortVideoPlayer: empty videoUrl for post ${widget.post.id}');
      return;
    }
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      httpHeaders: const {
        'ngrok-skip-browser-warning': 'true',
      },
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('ShortVideoPlayer: Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final d = DateTime.now().difference(dateTime);
    if (d.inDays > 365) {
      final y = (d.inDays / 365).floor();
      return '$y ${y == 1 ? 'year' : 'years'} ago';
    } else if (d.inDays > 30) {
      final m = (d.inDays / 30).floor();
      return '$m ${m == 1 ? 'month' : 'months'} ago';
    } else if (d.inDays > 0) {
      return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
    } else if (d.inHours > 0) {
      return '${d.inHours} ${d.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes} ${d.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  String _formatViewCount(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
    return views.toString();
  }

  String _politicalOrientationLabel(PoliticalOrientation o) {
    switch (o) {
      case PoliticalOrientation.extremelyConservative:
        return 'Très conservateur';
      case PoliticalOrientation.conservative:
        return 'Conservateur';
      case PoliticalOrientation.neutral:
        return 'Neutre';
      case PoliticalOrientation.progressive:
        return 'Progressiste';
      case PoliticalOrientation.extremelyProgressive:
        return 'Très progressiste';
    }
  }

  void _showDeleteConfirmation() {
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
              await _deletePost();
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

  Future<void> _deletePost() async {
    try {
      final postsStateProvider = context.read<PostsStateProvider>();
      await postsStateProvider.deletePost(widget.post.id);

      if (context.mounted) {
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Post supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (post.id.startsWith('invalid_post_id_')) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => VotingDialog(
                post: post,
                onVoteChanged: (updatedPost) {
                  setState(() {
                    _currentPost = updatedPost;
                  });
                },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(
              Icons.public,
              color: color,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (totalVotes > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$totalVotes',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoLayer() {
    if (_controller != null && _controller!.value.isInitialized) {
      final size = _controller!.value.size;
      if (size.width > 0 && size.height > 0) {
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(_controller!),
          ),
        );
      }
    }
    final thumb = widget.post.imageUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(
        ImageUtils.getAvatarUrl(thumb),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final views = post.stats.views;
    final createdAt = post.createdAt;
    final journalist = post.journalist;
    final orientation = post.politicalOrientation.displayOrientation;
    final avatarUrl = journalist?.avatarUrl != null
        ? ImageUtils.getAvatarUrl(journalist!.avatarUrl!)
        : null;
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
    final isOwnPost = currentUserId != null &&
        post.journalist?.id != null &&
        currentUserId == post.journalist!.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          final c = _controller;
          if (c == null) return;
          if (c.value.isPlaying) {
            c.pause();
          } else {
            c.play();
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildVideoLayer()),
          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (isOwnPost)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                      onPressed: _showDeleteConfirmation,
                      splashRadius: 22,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Selector<PostsStateProvider, Post?>(
                  selector: (context, provider) =>
                      provider.getPost(_currentPost.id),
                  builder: (context, providerPost, _) {
                    final displayPost = providerPost ?? _currentPost;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color:
                                displayPost.isLiked ? Colors.red : Colors.white,
                            size: 32,
                          ),
                          onPressed: () async {
                            if (_isLikeProcessing) return;
                            if (displayPost.id.startsWith('invalid_post_id_')) {
                              return;
                            }
                            setState(() {
                              _isLikeProcessing = true;
                            });
                            final postsStateProvider =
                                context.read<PostsStateProvider>();
                            try {
                              await postsStateProvider
                                  .toggleLike(displayPost.id);
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
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                if (mounted) {
                                  setState(() {
                                    _isLikeProcessing = false;
                                  });
                                }
                              });
                            }
                          },
                        ),
                        Text(
                          _formatNumber(displayPost.likesCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          icon: const Icon(Icons.comment,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            if (displayPost.id.startsWith('invalid_post_id_')) {
                              return;
                            }
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  CommentsBottomSheet(postId: displayPost.id),
                            );
                          },
                        ),
                        Text(
                          _formatNumber(displayPost.commentsCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPoliticalOrientationButton(displayPost),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
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
                    Icons.tag,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (post.domain is String
                            ? (post.domain as String)
                            : post.domain.name)
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (journalist?.id == null || journalist!.id!.isEmpty) return;

                        if (isOwnPost) {
                          context.go(RouteNames.profile);
                        } else {
                          context.push(
                            '/profile',
                            extra: {
                              'userId': journalist.id,
                              'isCurrentUser': false,
                              'forceReload': true,
                            },
                          );
                        }
                      },
                      child: Row(
                        children: [
                          UserAvatar(
                            avatarUrl: journalist?.avatarUrl,
                            name: journalist?.name ?? journalist?.username,
                            isJournalist: true,
                            radius: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              journalist?.name.isNotEmpty == true
                                  ? journalist!.name
                                  : (journalist?.username?.isNotEmpty == true
                                      ? '@${journalist!.username}'
                                      : '@journalist'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (post.title.isNotEmpty)
                      Text(
                        post.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: _isDescriptionExpanded ? null : 2,
                        overflow: _isDescriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    if (post.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        post.content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: _isDescriptionExpanded ? null : 2,
                        overflow: _isDescriptionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_formatViewCount(views)} vues • ${_getTimeAgo(createdAt)} • ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Icon(Icons.public, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _politicalOrientationLabel(orientation),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_controller != null && _controller!.value.hasError)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Impossible de lire la vidéo',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
