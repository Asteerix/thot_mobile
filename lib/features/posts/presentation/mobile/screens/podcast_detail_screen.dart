import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/features/posts/presentation/shared/widgets/post_actions.dart';
import 'package:thot/features/comments/presentation/shared/widgets/comment_sheet.dart';
class PositionData {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  PositionData({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });
}
class PodcastDetailScreen extends StatefulWidget {
  final String postId;
  const PodcastDetailScreen({super.key, required this.postId});
  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}
class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  late final PostRepositoryImpl _postRepository;
  late final AudioPlayer _audioPlayer;
  bool _isLoading = true;
  bool _isAudioLoading = false;
  Post? _post;
  String? _error;
  String? _audioError;
  Stream<Duration> get _positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get _durationStream => _audioPlayer.durationStream;
  Stream<bool> get _playingStream => _audioPlayer.playingStream;
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration?, bool, PositionData>(
        _positionStream,
        _durationStream,
        _playingStream,
        (position, duration, isPlaying) => PositionData(
          position: position,
          duration: duration ?? Duration.zero,
          isPlaying: isPlaying,
        ),
      );
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _audioPlayer = AudioPlayer();
    _loadPost();
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _audioError = null;
      });
      final response = await _postRepository.getPost(widget.postId);
      final post = Post.fromJson(response);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
        if (post.videoUrl != null) {
          setState(() => _isAudioLoading = true);
          try {
            debugPrint('Loading audio from URL: ${post.videoUrl}');
            await _audioPlayer.setUrl(post.videoUrl!);
            setState(() => _isAudioLoading = false);
          } catch (e) {
            debugPrint('Error loading audio: $e');
            setState(() {
              _audioError = 'Failed to load audio: ${e.toString()}';
              _isAudioLoading = false;
            });
          }
        } else {
          setState(() => _audioError = 'No audio URL found for this podcast');
        }
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
  Widget _buildAudioControls() {
    if (_audioError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          _audioError!,
          style: const TextStyle(color: AppColors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_isAudioLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface),
      );
    }
    return StreamBuilder<PositionData>(
      stream: _positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data ??
            PositionData(
              position: Duration.zero,
              duration: Duration.zero,
              isPlaying: false,
            );
        return Column(
          children: [
            Slider(
              value: positionData.position.inMilliseconds.toDouble(),
              max: positionData.duration.inMilliseconds.toDouble(),
              activeColor: Colors.white,
              inactiveColor: Colors.white.withOpacity(0.3),
              onChanged: (value) {
                _audioPlayer.seek(Duration(milliseconds: value.round()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(positionData.position),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          positionData.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 48,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        onPressed: () {
                          if (positionData.isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    _formatDuration(positionData.duration),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: const TextStyle(color: AppColors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPost,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_post == null) {
      return const Scaffold(
        body: Center(
          child: Text('Post not found'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _post!.title,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Tailwind',
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  color: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, size: 48, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(height: 16),
                      if (_post?.videoUrl != null) _buildAudioControls(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: _post!.journalist?.avatarUrl !=
                                        null &&
                                    _post!.journalist!.avatarUrl!.isNotEmpty
                                ? NetworkImage(ImageUtils.getAvatarUrl(
                                    _post!.journalist!.avatarUrl))
                                : const AssetImage(
                                        'assets/images/defaults/default_journalist_avatar.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post!.journalist?.name ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tailwind',
                                ),
                              ),
                              if (_post!.journalist?.isVerified ?? false)
                                Text(
                                  'Verified Journalist',
                                  style: TextStyle(
                                    color: AppColors.info,
                                    fontSize: 12,
                                    fontFamily: 'Tailwind',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _post!.content,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Tailwind',
                        ),
                      ),
                      if (_post?.metadata?.podcast?.transcript != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Transcription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tailwind',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _post!.metadata!.podcast!.transcript!,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Tailwind',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                    Theme.of(context).colorScheme.onSurface,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: PostActions(
                post: _post!,
                onLike: () {
                  debugPrint('Like podcast: ${_post!.id}');
                },
                onComment: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentsBottomSheet(
                      postId: _post!.id,
                    ),
                  );
                },
                onPostUpdated: (updatedPost) {
                  setState(() {
                    _post = updatedPost;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}