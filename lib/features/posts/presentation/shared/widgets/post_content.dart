import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/media/utils/image_utils.dart';
class PostContent extends StatefulWidget {
  final Post post;
  final bool isDetailView;
  const PostContent({
    super.key,
    required this.post,
    this.isDetailView = false,
  });
  @override
  State<PostContent> createState() => _PostContentState();
}
class _PostContentState extends State<PostContent>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  bool _isVisible = true;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.post.type == PostType.video && widget.post.videoUrl != null) {
      _initializeVideoPlayer();
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    switch (widget.post.type) {
      case PostType.video:
        return _buildVideoContent();
      case PostType.podcast:
        return _buildPodcastContent();
      case PostType.article:
      default:
        return _buildArticleContent();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _videoController?.play();
    }
  }
  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.videoUrl!),
      httpHeaders: {
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'video/mp4',
      },
    );
    await _videoController!.initialize();
    if (mounted) setState(() {});
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    super.dispose();
  }
  void _onVisibilityChanged(bool visible) {
    if (!mounted) return;
    if (_isVisible != visible) {
      setState(() {
        _isVisible = visible;
      });
      if (visible) {
        _videoController?.play();
      } else {
        _videoController?.pause();
      }
    }
  }
  Widget _buildVideoContent() {
    if (_videoController?.value.isInitialized != true) {
      return const Center(child: CircularProgressIndicator());
    }
    return VisibilityDetector(
      key: Key('video-${widget.post.id}'),
      onVisibilityChanged: (info) {
        _onVisibilityChanged(info.visibleFraction > 0.5);
      },
      child: _buildVideoPlayer(),
    );
  }
  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Icon(
                Icons.play_circle,
                size: 64,
                color: Colors.white,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _videoController!,
                        builder: (context, value, child) {
                          return Text(
                            _formatDuration(value.position),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.fast_rewind,
                                color: Colors.white),
                            onPressed: () {
                              final newPosition =
                                  _videoController!.value.position -
                                      const Duration(seconds: 10);
                              _videoController!.seekTo(newPosition);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.forward,
                                color: Colors.white),
                            onPressed: () {
                              final newPosition =
                                  _videoController!.value.position +
                                      const Duration(seconds: 10);
                              _videoController!.seekTo(newPosition);
                            },
                          ),
                        ],
                      ),
                      ValueListenableBuilder(
                        valueListenable: _videoController!,
                        builder: (context, value, child) {
                          return Text(
                            _formatDuration(value.duration),
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
  Widget _buildArticleContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            Hero(
              tag: 'image-${widget.post.id}',
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        ImageUtils.processImageUrl(widget.post.imageUrl!)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                if (widget.post.metadata?.article?.sources?.isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Sources',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.post.metadata?.article?.sources
                          ?.map((source) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• $source',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              )) ??
                      [],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPodcastContent() {
    return Column(
      children: [
        if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    ImageUtils.processImageUrl(widget.post.imageUrl!)),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon:
                              Icon(Icons.fast_rewind, color: Colors.white),
                          onPressed: () {
                          },
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.info,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.play_arrow, size: 32),
                            color: Colors.white,
                            onPressed: () {
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon:
                              Icon(Icons.forward, color: Colors.white),
                          onPressed: () {
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: Colors.blue,
                            inactiveTrackColor: Colors.grey[700],
                            thumbColor: Colors.white,
                            overlayColor: Colors.blue.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: 0,
                            onChanged: (value) {
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0:00',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(Duration(
                                    seconds: widget
                                            .post.metadata?.podcast?.duration ??
                                        0)),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (widget.post.content.isNotEmpty) ...[
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.post.content,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}