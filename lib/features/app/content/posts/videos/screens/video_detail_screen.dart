import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/widgets/content_detail_layout.dart';
import 'package:thot/features/app/content/shared/widgets/content_description_dialog.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import 'package:thot/core/di/service_locator.dart';

/// Écran de détail pour les vidéos
class VideoDetailScreen extends StatefulWidget {
  final String postId;

  const VideoDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final _postRepository = ServiceLocator.instance.postRepository;
  Post? _post;
  List<Post>? _opposingPosts;
  List<Post>? _relatedPosts;
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideo();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.postId);

      if (post == null) {
        throw Exception('Vidéo non trouvée');
      }

      // Charger les posts en opposition et relatés
      final opposing = <Post>[];
      final related = <Post>[];

      if (post.opposingPosts != null) {
        for (final opposingData in post.opposingPosts!) {
          try {
            final opposingPost = await postsStateProvider.loadPost(opposingData.postId);
            if (opposingPost != null) opposing.add(opposingPost);
          } catch (e) {
            debugPrint('Erreur chargement post opposé: $e');
          }
        }
      }

      if (post.relatedPosts != null) {
        for (final relatedPost in post.relatedPosts!) {
          related.add(relatedPost);
        }
      }

      // Initialiser le contrôleur vidéo si URL disponible
      if (post.videoUrl != null) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(post.videoUrl!))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
            }
          }).catchError((error) {
            debugPrint('Erreur initialisation vidéo: $error');
          });
      }

      if (mounted) {
        setState(() {
          _post = post;
          _opposingPosts = opposing.isEmpty ? null : opposing;
          _relatedPosts = related.isEmpty ? null : related;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _showFullVideo() {
    if (_post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentDescriptionDialog(post: _post!),
    );
  }

  void _showComments() {
    if (_post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(postId: _post!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_error != null || _post == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Vidéo non trouvée',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadVideo,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return ContentDetailLayout(
      post: _post!,
      previewWidget: _buildVideoPreview(),
      actionButtonText: "Lire la description complète",
      onActionPressed: _showFullVideo,
      onComment: _showComments,
      opposingPosts: _opposingPosts,
      relatedPosts: _relatedPosts,
    );
  }

  Widget _buildVideoPreview() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isVideoInitialized && _videoController != null)
                  VideoPlayer(_videoController!)
                else if (_post!.thumbnailUrl != null)
                  Image.network(
                    _post!.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.videocam, color: Colors.white54, size: 64),
                    ),
                  )
                else
                  const Center(
                    child: Icon(Icons.videocam, color: Colors.white54, size: 64),
                  ),
                if (!_isVideoInitialized || !(_videoController?.value.isPlaying ?? false))
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Vidéo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isVideoInitialized && _videoController != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_videoController!.value.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
