import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/shared/widgets/common/app_avatar.dart';
import 'package:thot/features/profile/presentation/shared/widgets/follow_button.dart';
import 'package:thot/features/posts/presentation/shared/widgets/post_actions.dart';
import 'package:thot/features/posts/application/providers/posts_state_provider.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/comments/presentation/shared/widgets/comment_sheet.dart';
class VideoDetailScreen extends StatefulWidget {
  final String initialPostId;
  final bool isFromProfile;
  final String? userId;
  final PostType? filterType;
  final bool isFromFeed;
  const VideoDetailScreen({
    super.key,
    required this.initialPostId,
    this.isFromProfile = false,
    this.userId,
    this.filterType,
    this.isFromFeed = false,
  });
  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}
class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late final PostRepositoryImpl _postRepository;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  Post? _post;
  String? _error;
  bool _isVideoInitializing = false;
  bool _isFullScreen = false;
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _loadPost();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      developer.log('Loading post: ${widget.initialPostId}',
          name: 'VideoDetailScreen');
      final response = await _postRepository.getPost(widget.initialPostId);
      final post = Post.fromJson(response);
      developer.log(
        'Post loaded successfully',
        name: 'VideoDetailScreen',
        error: {
          'title': post.title,
          'videoUrl': post.videoUrl,
          'thumbnailUrl': post.thumbnailUrl,
        },
      );
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
        if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
          await _initializeVideo(post.videoUrl!);
        } else {
          setState(() {
            _error = 'No video URL found for this post';
          });
        }
      }
    } catch (e) {
      developer.log(
        'Error loading post',
        name: 'VideoDetailScreen',
        error: e,
        stackTrace: StackTrace.current,
      );
      if (mounted) {
        setState(() {
          _error = 'Failed to load post: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _initializeVideo(String videoUrl) async {
    if (_isVideoInitializing) return;
    setState(() {
      _isVideoInitializing = true;
    });
    try {
      developer.log('Initializing video: $videoUrl', name: 'VideoDetailScreen');
      await _disposeVideoControllers();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      developer.log(
        'Video initialized',
        name: 'VideoDetailScreen',
        error: {
          'duration': _videoController!.value.duration.toString(),
          'size':
              '${_videoController!.value.size.width}x${_videoController!.value.size.height}',
          'aspectRatio': _videoController!.value.aspectRatio,
        },
      );
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        allowPlaybackSpeedChanging: false,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        fullScreenByDefault: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.blue,
          handleColor: AppColors.blue,
          backgroundColor: Theme.of(context).colorScheme.outline,
          bufferedColor: Theme.of(context).colorScheme.outline,
        ),
        placeholder: _buildPlaceholder(),
        errorBuilder: (context, errorMessage) {
          developer.log(
            'Video playback error',
            name: 'VideoDetailScreen',
            error: errorMessage,
          );
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red[300],
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Impossible de lire la vidéo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      _chewieController!.addListener(_fullScreenListener);
      if (mounted) {
        setState(() {
          _isVideoInitializing = false;
        });
      }
    } catch (e) {
      developer.log(
        'Failed to initialize video',
        name: 'VideoDetailScreen',
        error: e,
        stackTrace: StackTrace.current,
      );
      if (mounted) {
        setState(() {
          _error = 'Failed to load video: ${e.toString()}';
          _isVideoInitializing = false;
        });
      }
    }
  }
  void _fullScreenListener() {
    if (_chewieController != null &&
        _chewieController!.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = _chewieController!.isFullScreen;
      });
    }
  }
  Widget _buildPlaceholder() {
    return SizedBox.expand(
      child: Container(
        color: Colors.black,
        child: _post?.thumbnailUrl != null && _post!.thumbnailUrl!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _post!.thumbnailUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.play_circle,
                          color: Colors.white.withOpacity(0.5),
                          size: 64,
                        ),
                      );
                    },
                  ),
                  if (_isVideoInitializing)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: _isVideoInitializing
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : Icon(
                        Icons.play_circle,
                        color: Colors.white.withOpacity(0.5),
                        size: 64,
                      ),
              ),
      ),
    );
  }
  void _handleLike(Post post) async {
    setState(() {
      _post = _post?.copyWith(
        interactions: _post!.interactions.copyWith(
          isLiked: !_post!.interactions.isLiked,
          likes: _post!.interactions.isLiked
              ? _post!.interactions.likes - 1
              : _post!.interactions.likes + 1,
        ),
      );
    });
    try {
      final postService = ServiceLocator.instance.postRepository;
      await postService.toggleLike(post.id);
      developer.log('Like toggled successfully for post: ${post.id}',
          name: 'VideoDetailScreen');
    } catch (e) {
      if (mounted) {
        setState(() {
          _post = _post?.copyWith(
            interactions: _post!.interactions.copyWith(
              isLiked: !_post!.interactions.isLiked,
              likes: _post!.interactions.isLiked
                  ? _post!.interactions.likes - 1
                  : _post!.interactions.likes + 1,
            ),
          );
        });
      }
      developer.log('Error toggling like: $e', name: 'VideoDetailScreen');
    }
  }
  void _showCommentsSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: postId),
    );
  }
  void _handleSave(Post post) async {
    setState(() {
      _post = _post?.copyWith(
        interactions: _post!.interactions.copyWith(
          isSaved: !_post!.interactions.isSaved,
          bookmarks: _post!.interactions.isSaved
              ? _post!.interactions.bookmarks - 1
              : _post!.interactions.bookmarks + 1,
        ),
      );
    });
    try {
      final postService = ServiceLocator.instance.postRepository;
      await postService.toggleBookmark(post.id);
      developer.log('Bookmark toggled successfully for post: ${post.id}',
          name: 'VideoDetailScreen');
    } catch (e) {
      if (mounted) {
        setState(() {
          _post = _post?.copyWith(
            interactions: _post!.interactions.copyWith(
              isSaved: !_post!.interactions.isSaved,
              bookmarks: _post!.interactions.isSaved
                  ? _post!.interactions.bookmarks - 1
                  : _post!.interactions.bookmarks + 1,
            ),
          );
        });
      }
      developer.log('Error toggling bookmark: $e', name: 'VideoDetailScreen');
    }
  }
  Future<void> _disposeVideoControllers() async {
    try {
      if (_chewieController != null) {
        _chewieController!.removeListener(_fullScreenListener);
        if (_chewieController!.isPlaying) {
          await _chewieController!.pause();
        }
        _chewieController!.dispose();
        _chewieController = null;
      }
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }
    } catch (e) {
      developer.log('Error disposing video controllers: $e',
          name: 'VideoDetailScreen');
    }
  }
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _disposeVideoControllers();
    super.dispose();
  }
  Widget _buildVideoPlayer() {
    if (_chewieController != null &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }
    return _buildPlaceholder();
  }
  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red[300],
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Impossible de charger la vidéo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cette vidéo n\'existe plus ou a été supprimée',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadPost,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_post == null) {
      return Center(
        child: Text(
          'Post non trouvé',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    }
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        if (isLandscape && !_isFullScreen) {
          return Stack(
            children: [
              Center(child: _buildVideoPlayer()),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.onSurface,
              child: SafeArea(
                bottom: false,
                child: AspectRatio(
                  aspectRatio: (_videoController?.value.isInitialized ?? false)
                      ? _videoController!.value.aspectRatio
                      : 16 / 9,
                  child: _buildVideoPlayer(),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post!.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (_post!.journalist != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              AppAvatar(
                                avatarUrl: _post!.journalist!.avatarUrl,
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _post!.journalist!.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (_post!.journalist!.isVerified) ...[
                                          Icon(
                                            Icons.verified,
                                            color: AppColors.info,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              color: AppColors.info,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (_post!.journalist?.id != null)
                                Builder(
                                  builder: (context) {
                                    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
                                    final isOwnPost = currentUserId != null &&
                                                      currentUserId == _post!.journalist!.id;
                                    if (isOwnPost) {
                                      return const SizedBox.shrink();
                                    }
                                    return FollowButton(
                                      userId: _post!.journalist!.id!,
                                      isFollowing: _post!.journalist!.isFollowing,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (_post!.content.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _post!.content,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Consumer<PostsStateProvider>(
                        builder: (context, postsProvider, child) {
                          final currentPost =
                              postsProvider.getPost(_post!.id) ?? _post!;
                          return PostActions(
                            post: currentPost,
                            onLike: () => _handleLike(currentPost),
                            onComment: () => _showCommentsSheet(currentPost.id),
                            onSave: () => _handleSave(currentPost),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: Container(
                margin: const EdgeInsets.all(8),
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
                  iconSize: 20,
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
              title: _post != null
                  ? Text(
                      _post!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
                    )
                  : null,
            ),
      body: _buildContent(),
    );
  }
}