import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/widgets/content_detail_layout.dart';
import 'package:thot/features/app/content/shared/widgets/content_description_dialog.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import 'package:thot/core/di/service_locator.dart';

/// Écran de détail pour les podcasts
class PodcastDetailScreen extends StatefulWidget {
  final String postId;

  const PodcastDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  final _postRepository = ServiceLocator.instance.postRepository;
  final _audioPlayer = AudioPlayer();
  Post? _post;
  List<Post>? _opposingPosts;
  List<Post>? _relatedPosts;
  bool _isLoading = true;
  String? _error;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPodcast();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _loadPodcast() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.postId);

      if (post == null) {
        throw Exception('Podcast non trouvé');
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

      // Charger l'audio si disponible
      final audioUrl = post.metadata?.podcast?.audioUrl;
      if (audioUrl != null) {
        await _audioPlayer.setSourceUrl(audioUrl);
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

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _showFullDescription() {
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
                _error ?? 'Podcast non trouvé',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPodcast,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return ContentDetailLayout(
      post: _post!,
      previewWidget: _buildPodcastPreview(),
      actionButtonText: "Lire la description complète",
      onActionPressed: _showFullDescription,
      onComment: _showComments,
      opposingPosts: _opposingPosts,
      relatedPosts: _relatedPosts,
      additionalContent: _buildAudioPlayer(),
    );
  }

  Widget _buildPodcastPreview() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_post!.imageUrl != null)
                  Image.network(
                    _post!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.podcasts, color: Colors.white54, size: 64),
                    ),
                  )
                else
                  const Center(
                    child: Icon(Icons.podcasts, color: Colors.white54, size: 64),
                  ),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
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
                      color: Colors.purple.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.podcasts, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Podcast',
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
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_duration),
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

  Widget _buildAudioPlayer() {
    final audioUrl = _post?.metadata?.podcast?.audioUrl;
    if (audioUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.purple,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  final newPosition = _position - const Duration(seconds: 10);
                  await _audioPlayer.seek(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  );
                },
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () async {
                  final newPosition = _position + const Duration(seconds: 10);
                  await _audioPlayer.seek(
                    newPosition > _duration ? _duration : newPosition,
                  );
                },
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
