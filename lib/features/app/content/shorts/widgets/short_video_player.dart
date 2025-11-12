import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/shared/media/utils/image_utils.dart';

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
  @override
  void initState() {
    super.initState();
    _initializeVideo();
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
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await widget.shortsService.likeShort(post.id);
                          widget.onLike?.call();
                        } catch (e) {
                          debugPrint('likeShort error: $e');
                        }
                      },
                    ),
                    Text('${post.likesCount}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.thumb_down, color: Colors.white),
                      onPressed: () async {
                        try {
                          await widget.shortsService.dislikeShort(post.id);
                          widget.onDislike?.call();
                        } catch (e) {
                          debugPrint('dislikeShort error: $e');
                        }
                      },
                    ),
                    Text('${post.dislikesCount}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: Icon(Icons.comment, color: Colors.white),
                      onPressed: widget.onComment,
                    ),
                    Text('${post.commentsCount}',
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Icon(Icons.public, color: Colors.white70),
                  ],
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : null,
                          child: (avatarUrl == null || avatarUrl.isEmpty)
                              ? Icon(Icons.person,
                                  color: Colors.white, size: 24)
                              : null,
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
                      ],
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
