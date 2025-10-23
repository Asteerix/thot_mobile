import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/monitoring/logger_service.dart';
class ShortsFeedScreen extends StatefulWidget {
  final String? initialShortId;
  final bool isLiveMode;
  const ShortsFeedScreen({
    super.key,
    this.initialShortId,
    this.isLiveMode = false,
  });
  @override
  State<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}
class _ShortsFeedScreenState extends State<ShortsFeedScreen> {
  final _logger = LoggerService.instance;
  final PageController _pageController = PageController();
  late final PostRepositoryImpl _postRepository;
  List<Post> _shorts = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  String? _currentDomain;
  final Map<String, List<Post>> _shortsByDomain = {};
  List<String> _availableDomains = [];
  final Map<String, int> _domainPageIndices = {};
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isFrontCamera = true;
  List<CameraDescription> _cameras = [];
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _loadShorts();
    if (widget.isLiveMode) {
      _initializeCamera();
    }
  }
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      final camera = _isFrontCamera
          ? _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );
      _cameraController?.dispose();
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }
  void _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
    });
    await _initializeCamera();
  }
  void _toggleRecording() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    if (_isRecording) {
      await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
    } else {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }
  Color _getPoliticalColor(PoliticalOrientation? orientation) {
    if (orientation == null) return Colors.grey;
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return Colors.blue[900]!;
      case PoliticalOrientation.conservative:
        return Colors.blue[700]!;
      case PoliticalOrientation.neutral:
        return Colors.grey;
      case PoliticalOrientation.progressive:
        return Colors.red[700]!;
      case PoliticalOrientation.extremelyProgressive:
        return Colors.red[900]!;
    }
  }
  IconData _getPoliticalIcon(PoliticalOrientation? orientation) {
    return Icons.public;
  }
  Future<void> _loadShorts() async {
    _logger.info('Starting to load shorts...');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _logger.info(
          'Calling postService.getPosts with type: ${widget.isLiveMode ? PostTypes.live : PostTypes.short}');
      final response = await _postRepository.getPosts(
        type: widget.isLiveMode ? PostTypes.live : PostTypes.short,
      );
      _logger.debug('Response received: ${response.keys}');
      if (!mounted) return;
      final postsData = response['posts'] as List<dynamic>? ?? [];
      final allShorts = postsData
          .map((data) => Post.fromJson(data as Map<String, dynamic>))
          .toList();
      _logger.info('Found ${allShorts.length} shorts');
      if (allShorts.isNotEmpty) {
        final firstShort = allShorts.first;
        _logger.debug('First short details:');
        _logger.debug('  - ID: ${firstShort.id}');
        _logger.debug('  - Title: ${firstShort.title}');
        _logger.debug('  - VideoUrl: ${firstShort.videoUrl}');
        _logger.debug('  - ThumbnailUrl: ${firstShort.thumbnailUrl}');
        _logger.debug('  - Type: ${firstShort.type}');
        _logger.debug('  - Domain: ${firstShort.domain}');
        _logger.debug(
            '  - Journalist: ${firstShort.journalist?.name} (@${firstShort.journalist?.username})');
      }
      _shortsByDomain.clear();
      for (final short in allShorts) {
        final domain = short.domain.toString().split('.').last;
        _shortsByDomain.putIfAbsent(domain, () => []).add(short);
      }
      _availableDomains = _shortsByDomain.keys.toList();
      if (_currentDomain == null && _availableDomains.isNotEmpty) {
        _currentDomain = _availableDomains[0];
      }
      for (final domain in _availableDomains) {
        _domainPageIndices[domain] = 0;
      }
      setState(() {
        _shorts = _currentDomain != null
            ? _shortsByDomain[_currentDomain]!
            : allShorts;
        _isLoading = false;
      });
      _logger.info('Shorts loaded successfully!');
      _logger.debug('Current shorts count: ${_shorts.length}');
      if (_shorts.isNotEmpty && !widget.isLiveMode) {
        _logger.info('Initializing first video...');
        _initializeVideoForShort(_shorts[0]);
      }
      if (widget.initialShortId != null) {
        for (final entry in _shortsByDomain.entries) {
          final index =
              entry.value.indexWhere((s) => s.id == widget.initialShortId);
          if (index != -1) {
            _currentDomain = entry.key;
            _shorts = entry.value;
            _domainPageIndices[entry.key] = index;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pageController.jumpToPage(index);
            });
            break;
          }
        }
      }
    } catch (e) {
      _logger.error('Error loading shorts: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  Future<void> _initializeVideoForShort(Post short) async {
    final videoUrl = short.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      _logger.warning('No video URL for short: ${short.id}');
      return;
    }
    final shortId = short.id;
    _logger.info('Initializing video for short $shortId');
    _logger.debug('Video URL: $videoUrl');
    if (_videoControllers.containsKey(shortId)) {
      _logger.debug('Video controller already exists for $shortId');
      final controller = _videoControllers[shortId]!;
      if (!controller.value.isPlaying) {
        controller.play();
      }
      return;
    }
    try {
      String formattedUrl = videoUrl;
      if (!videoUrl.startsWith('http')) {
        formattedUrl = videoUrl.startsWith('/') ? videoUrl : '/$videoUrl';
        _logger.warning('Relative video URL detected: $videoUrl');
      }
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(formattedUrl),
      );
      await videoController.initialize();
      _logger.info('Video initialized successfully for $shortId');
      _logger.debug('Video dimensions: ${videoController.value.size}');
      _logger.debug('Video duration: ${videoController.value.duration}');
      await videoController.play();
      await videoController.setLooping(true);
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: true,
        showControls: true,
        aspectRatio: 9 / 16,
        allowFullScreen: false,
        allowMuting: true,
        showOptions: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: AppColors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Erreur vidéo',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  errorMessage,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      if (mounted) {
        setState(() {
          _videoControllers[shortId] = videoController;
          _chewieControllers[shortId] = chewieController;
        });
      }
    } catch (e) {
      _logger.error('Error initializing video for $shortId: $e');
      _logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur de chargement vidéo: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  Widget _buildLiveView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isCameraInitialized)
          CameraPreview(_cameraController!)
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        Positioned(
          top: 60,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.live_tv,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isCameraInitialized)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? AppColors.red: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    color: _isRecording ? Colors.white : AppColors.red,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildNestedPageView() {
    if (_availableDomains.isEmpty) {
      return const Center(
        child: Text(
          'Aucun short disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _availableDomains.length,
      onPageChanged: (index) {
        setState(() {
          if (_currentDomain != null) {
            _domainPageIndices[_currentDomain!] = _currentIndex;
          }
          _currentDomain = _availableDomains[index];
          _shorts = _shortsByDomain[_currentDomain]!;
          _currentIndex = _domainPageIndices[_currentDomain!] ?? 0;
        });
      },
      itemBuilder: (context, domainIndex) {
        final domain = _availableDomains[domainIndex];
        final shortsInDomain = _shortsByDomain[domain]!;
        return PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: shortsInDomain.length,
          controller:
              PageController(initialPage: _domainPageIndices[domain] ?? 0),
          onPageChanged: (index) {
            _logger.debug('Page changed to index $index in domain $domain');
            setState(() {
              _currentIndex = index;
              _domainPageIndices[domain] = index;
            });
            if (index < shortsInDomain.length) {
              _initializeVideoForShort(shortsInDomain[index]);
            }
          },
          itemBuilder: (context, shortIndex) {
            return _buildShortItem(shortsInDomain[shortIndex]);
          },
        );
      },
    );
  }
  Widget _buildShortItem(Post short) {
    final isLive = short.type == PostType.live;
    final shortId = short.id;
    final videoUrl = short.videoUrl ?? '';
    _logger.debug('Building short item:');
    _logger.debug('  - ID: $shortId');
    _logger.debug('  - VideoUrl: $videoUrl');
    _logger.debug('  - IsLive: $isLive');
    _logger.debug(
        '  - Journalist: ${short.journalist?.name} (ID: ${short.journalist?.id})');
    _logger.debug('  - Journalist Avatar: ${short.journalist?.avatarUrl}');
    _logger.debug('  - Journalist Username: ${short.journalist?.username}');
    if (!widget.isLiveMode &&
        videoUrl.isNotEmpty &&
        !_videoControllers.containsKey(shortId)) {
      _logger.debug('Lazy initializing video for $shortId');
      _initializeVideoForShort(short);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.isLiveMode && _isCameraInitialized)
          CameraPreview(_cameraController!)
        else if (_chewieControllers.containsKey(shortId))
          Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Chewie(controller: _chewieControllers[shortId]!),
              ),
            ),
          )
        else if (videoUrl.isNotEmpty)
          Container(
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement de la vidéo...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vidéo non disponible',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'URL: ${videoUrl.isEmpty ? "Aucune URL" : videoUrl}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 60,
          right: 16,
          child: Column(
            children: [
              if (widget.isLiveMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.live_tv,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_cameras.length > 1)
                      IconButton(
                        icon: Icon(
                          _isFrontCamera
                              ? Icons.camera_front
                              : Icons.camera_rear,
                          color: Colors.white,
                        ),
                        onPressed: _switchCamera,
                      ),
                  ],
                ),
              if (isLive && !widget.isLiveMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.live_tv,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              IconButton(
                icon: Icon(Icons.favorite_border),
                color: Colors.white,
                onPressed: () {},
              ),
              Text(
                '${short.likesCount}',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: Icon(Icons.comment_outlined),
                color: Colors.white,
                onPressed: () {},
              ),
              Text(
                '${short.commentsCount}',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: Icon(
                    _getPoliticalIcon(short.politicalOrientation.dominantView)),
                color:
                    _getPoliticalColor(short.politicalOrientation.dominantView),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      short.domain.toString().split('.').last,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                short.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (short.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  short.content,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: ClipOval(
                      child: short.journalist?.avatarUrl != null &&
                              short.journalist!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              ImageUtils.getAvatarUrl(
                                  short.journalist!.avatarUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                _logger.error(
                                    'Avatar load error: $error for journalist: ${short.journalist?.name}');
                                return Center(
                                  child: Text(
                                    (short.journalist?.name?.substring(0, 1) ??
                                            '?')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                (short.journalist?.name?.substring(0, 1) ?? '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                short.journalist?.name ?? 'Journaliste inconnu',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (short.journalist?.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const VerificationBadge(size: 16),
                            ],
                          ],
                        ),
                        if (short.journalist?.username != null)
                          Text(
                            '@${short.journalist!.username}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.isLiveMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: _isRecording ? AppColors.red: Colors.white,
                  onPressed: _toggleRecording,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: _isRecording ? Colors.white : AppColors.red,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: const TextStyle(color: AppColors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadShorts,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_shorts.isEmpty && !widget.isLiveMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            widget.isLiveMode
                ? 'Aucun live en cours'
                : 'Aucun short disponible',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: SafeArea(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            color: Colors.white,
            onPressed: () {
              _logger.info('Back button pressed');
              SafeNavigation.pop(context);
            },
          ),
        ),
      ),
      body: widget.isLiveMode ? _buildLiveView() : _buildNestedPageView(),
    );
  }
  @override
  void dispose() {
    _pageController.dispose();
    _cameraController?.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    for (final controller in _chewieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}