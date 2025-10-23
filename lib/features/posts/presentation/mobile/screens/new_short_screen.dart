import 'package:thot/core/themes/app_colors.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/media/domain/config/media_config.dart';
import 'package:thot/core/constants/validation_constants.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/media/infrastructure/upload_service.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/media/presentation/shared/widgets/media_picker.dart';
import 'package:thot/features/media/presentation/shared/widgets/video_player_preview.dart';
import 'package:thot/shared/widgets/common/upload_progress_dialog.dart';
import 'package:thot/features/posts/presentation/shared/widgets/editor_ui.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import './shorts_feed_screen.dart';
class NewShortScreen extends StatefulWidget {
  final String journalistId;
  final bool isLiveMode;
  const NewShortScreen({
    super.key,
    required this.journalistId,
    this.isLiveMode = false,
  });
  @override
  State<NewShortScreen> createState() => _NewShortScreenState();
}
class _NewShortScreenState extends State<NewShortScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  File? _selectedVideo;
  File? _selectedThumbnail;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  String? _error;
  String? _selectedDomain;
  int _currentStep = 0;
  static const List<Map<String, dynamic>> _domains = [
    {
      'id': 'politique',
      'title': 'Politique',
      'icon': Icons.account_balance,
      'color': Colors.blue
    },
    {
      'id': 'economie',
      'title': 'Économie',
      'icon': Icons.trending_up,
      'color': Colors.green
    },
    {
      'id': 'science',
      'title': 'Science',
      'icon': Icons.science,
      'color': Colors.purple
    },
    {
      'id': 'international',
      'title': 'International',
      'icon': Icons.public,
      'color': Colors.orange
    },
    {
      'id': 'juridique',
      'title': 'Juridique',
      'icon': Icons.gavel,
      'color': Colors.red
    },
    {
      'id': 'philosophie',
      'title': 'Philosophie',
      'icon': Icons.psychology,
      'color': AppColors.purple
    },
    {
      'id': 'societe',
      'title': 'Société',
      'icon': Icons.groups,
      'color': AppColors.success
    },
    {
      'id': 'psychologie',
      'title': 'Psychologie',
      'icon': Icons.self_improvement,
      'color': AppColors.red
    },
    {
      'id': 'sport',
      'title': 'Sport',
      'icon': Icons.sports_soccer,
      'color': Colors.amber
    },
    {
      'id': 'technologie',
      'title': 'Technologie',
      'icon': Icons.computer,
      'color': AppColors.blue
    },
  ];
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _uploadService = UploadService();
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  Future<void> _handleVideoSelected(File file) async {
    try {
      await _videoController?.dispose();
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      final w = _videoController!.value.size.width;
      final h = _videoController!.value.size.height;
      if (w > h) {
        throw Exception('Les shorts doivent être en format portrait (9:16).');
      }
      final d = _videoController!.value.duration;
      if (d.inSeconds > 30) {
        throw Exception(
            'Durée max: 30 secondes. Votre vidéo fait ${d.inSeconds}s.');
      }
      setState(() {
        _selectedVideo = file;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _selectedVideo = null;
      });
      if (mounted) {
        SafeNavigation.showSnackBar(context,
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
      }
    }
  }
  void _handleThumbnailSelected(File file) {
    setState(() => _selectedThumbnail = file);
  }
  void _replaceVideo() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: MediaPicker(
                type: MediaType.short,
                onMediaSelected: (file) {
                  _handleVideoSelected(file);
                  Navigator.pop(context);
                },
                height: MediaQuery.of(context).size.width * (16 / 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _replaceThumbnail() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: MediaPicker(
                type: MediaType.shortThumbnail,
                onMediaSelected: (file) {
                  _handleThumbnailSelected(file);
                  Navigator.pop(context);
                },
                height: MediaQuery.of(context).size.width * (16 / 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _checkAndPublish() {
    final List<String> missingItems = [];
    if (_titleController.text.trim().isEmpty) {
      missingItems.add('Titre');
    }
    if (_descriptionController.text.trim().isEmpty) {
      missingItems.add('Description');
    }
    if (_selectedVideo == null) {
      missingItems.add('Vidéo');
    }
    if (_selectedThumbnail == null) {
      missingItems.add('Miniature');
    }
    if (missingItems.isNotEmpty) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      final message = 'Éléments manquants: ${missingItems.join(', ')}';
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    _publishContent();
  }
  Future<void> _publishContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVideo == null || _selectedThumbnail == null) {
      SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Veuillez sélectionner une vidéo et une miniature'),
              backgroundColor: AppColors.red));
      return;
    }
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      try {
        final videoHash = await _uploadService.getFileHash(_selectedVideo!);
        final isDuplicate = await _postRepository.checkDuplicate(videoHash);
        if (isDuplicate) {
          if (!mounted) return;
          SafeNavigation.showSnackBar(
              context,
              const SnackBar(
                  content: Text('Cette vidéo a déjà été publiée'),
                  backgroundColor: AppColors.red));
          setState(() => _isUploading = false);
          return;
        }
      } catch (_) {}
      final videoProgress = StreamController<double>();
      String? videoUrl;
      try {
        if (!mounted) return;
        videoUrl = await UploadProgressDialog.show<String>(
          context: context,
          progressStream: videoProgress.stream,
          uploadFuture: _uploadService.uploadVideo(
            _selectedVideo!,
            isShort: true,
            onProgress: (p) => videoProgress.add(p * 0.7),
          ),
          message: 'Téléchargement de la vidéo…',
        );
      } catch (e) {
        await videoProgress.close();
        throw Exception(
            'Erreur lors du téléchargement de la vidéo: ${e.toString()}');
      }
      await videoProgress.close();
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('URL de vidéo invalide après téléchargement');
      }
      if (!videoUrl.contains('http') && !videoUrl.startsWith('/')) {
        throw Exception('Format d\'URL de vidéo invalide: $videoUrl');
      }
      final thumbProgress = StreamController<double>();
      String? imageUrl;
      try {
        if (!mounted) return;
        imageUrl = await UploadProgressDialog.show<String>(
          context: context,
          progressStream: thumbProgress.stream,
          uploadFuture: _uploadService.uploadThumbnail(
            _selectedThumbnail!,
            isShort: true,
            onProgress: (p) => thumbProgress.add(0.7 + p * 0.3),
          ),
          message: 'Téléchargement de la miniature…',
        );
      } catch (e) {
        await thumbProgress.close();
        throw Exception(
            'Erreur lors du téléchargement de la miniature: ${e.toString()}');
      }
      await thumbProgress.close();
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('URL de miniature invalide après téléchargement');
      }
      if (!imageUrl.contains('http') && !imageUrl.startsWith('/')) {
        throw Exception('Format d\'URL de miniature invalide: $imageUrl');
      }
      final width = _videoController!.value.size.width.toInt();
      final height = _videoController!.value.size.height.toInt();
      final duration = _videoController!.value.duration.inSeconds;
      final size = await _selectedVideo!.length();
      final videoHash = await _uploadService.getFileHash(_selectedVideo!);
      final data = {
        'title': _titleController.text.trim(),
        'content': _descriptionController.text.trim(),
        'videoUrl': videoUrl,
        'thumbnailUrl': imageUrl,
        'type': widget.isLiveMode ? PostTypes.live : PostTypes.short,
        'journalistId': widget.journalistId,
        'domain': _selectedDomain ?? 'societe',
        'status': 'published',
        'politicalOrientation': {
          'journalistChoice': 'neutral',
          'userVotes': {
            'extremelyConservative': 0,
            'conservative': 0,
            'neutral': 0,
            'progressive': 0,
            'extremelyProgressive': 0
          },
          'finalScore': 0
        },
        'metadata': {
          'short': {'duration': duration, 'views': 0, 'likes': 0},
          'video': {
            'size': size,
            'duration': duration,
            'width': width,
            'height': height,
            'quality': '${height}p',
            'hash': videoHash,
            'original_name': _selectedVideo!.path.split('/').last,
            'original_extension': _selectedVideo!.path.split('.').last,
          }
        }
      };
      Map<String, dynamic> result;
      try {
        result = await _postRepository.createPost(data);
      } catch (e) {
        throw Exception(
            'Erreur lors de la création de la publication: ${e.toString()}');
      }
      final postId = result['_id'] ?? result['data']?['_id'];
      if (postId == null && !widget.isLiveMode) {
        throw Exception('ID de publication non reçu après création');
      }
      if (!mounted) return;
      if (widget.isLiveMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const ShortsFeedScreen(isLiveMode: true)),
        );
      } else {
        EventBus().fire(PostCreatedEvent(
            postId: postId,
            postType: PostTypes.short,
            journalistId: widget.journalistId));
        GoRouter.of(context).go(
          '/post/$postId',
          extra: {
            'postId': postId,
            'isFromProfile': false,
            'filterType': PostType.short,
            'isFromFeed': true
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMessageHelper.getUserFriendlyMessage(e);
        _isUploading = false;
      });
    } finally {
      if (mounted && _isUploading) {
        setState(() => _isUploading = false);
      }
    }
  }
  Widget _buildDomainSelection() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Choisir un domaine',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _domains.length,
        itemBuilder: (context, index) {
          final domain = _domains[index];
          return InkWell(
            onTap: () {
              setState(() {
                _selectedDomain = domain['id'];
                _currentStep = 1;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    domain['icon'] as IconData,
                    size: 40,
                    color: domain['color'] as Color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    domain['title'] as String,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return _buildDomainSelection();
    }
    if (_isUploading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Container(
                color: Colors.black.withOpacity(0.8),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.blue),
                    const SizedBox(height: 20),
                    Text(
                      'Upload en cours...',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veuillez patienter',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null && _selectedVideo == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Error: $_error',
                style: const TextStyle(color: AppColors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Réessayer')),
          ]),
        ),
      );
    }
    return AbsorbPointer(
      absorbing: _isUploading,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.black,
              centerTitle: true,
              title: Text(widget.isLiveMode ? 'Nouveau live' : 'Nouveau short',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.onSurface,
                  child: Row(children: [
                    DomainChip(
                      text: _domains.firstWhere(
                        (d) => d['id'] == _selectedDomain,
                        orElse: () => {'title': 'Société'},
                      )['title'] as String,
                    ),
                  ]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(UIConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Glass(
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.surface, fontSize: 22, height: 1.2),
                          decoration: InputDecoration(
                            hintText: widget.isLiveMode
                                ? 'Titre du live'
                                : 'Titre du short',
                            hintStyle: TextStyle(
                                color: AppColors.textSecondary, fontSize: 20),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          maxLength: ValidationConstants.maxTitleLength,
                          validator: (v) => (v == null || v.isEmpty)
                              ? ErrorMessages.requiredField
                              : null,
                        ),
                      ),
                      const SizedBox(height: UIConstants.paddingM),
                      Glass(
                        padding: EdgeInsets.zero,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(UIConstants.paddingM),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Vidéo (portrait 9:16, ≤ 30s)',
                                        style:
                                            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    if (_selectedVideo != null)
                                      IconButton(
                                        onPressed: _replaceVideo,
                                        icon: Icon(Icons.swap_horiz,
                                            color: AppColors.blue),
                                      ),
                                  ],
                                ),
                              ),
                              AspectRatio(
                                aspectRatio: 9 / 16,
                                child: _selectedVideo != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            UIConstants.radiusM),
                                        child: VideoPlayerPreview(
                                            videoFile: _selectedVideo!,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                (16 / 9),
                                            autoPlay: true,
                                            type: MediaType.short),
                                      )
                                    : MediaPicker(
                                        type: MediaType.short,
                                        onMediaSelected: _handleVideoSelected,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                (16 / 9)),
                              ),
                            ]),
                      ),
                      const SizedBox(height: UIConstants.paddingM),
                      Glass(
                        padding: EdgeInsets.zero,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(UIConstants.paddingM),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Miniature (portrait 9:16)',
                                        style:
                                            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    if (_selectedThumbnail != null)
                                      IconButton(
                                        onPressed: _replaceThumbnail,
                                        icon: Icon(Icons.swap_horiz,
                                            color: AppColors.blue),
                                      ),
                                  ],
                                ),
                              ),
                              AspectRatio(
                                aspectRatio: 9 / 16,
                                child: _selectedThumbnail != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            UIConstants.radiusM),
                                        child: Image.file(_selectedThumbnail!,
                                            fit: BoxFit.cover),
                                      )
                                    : MediaPicker(
                                        type: MediaType.shortThumbnail,
                                        onMediaSelected:
                                            _handleThumbnailSelected,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                (16 / 9)),
                              ),
                            ]),
                      ),
                      const SizedBox(height: UIConstants.paddingM),
                      Glass(
                        child: TextFormField(
                          controller: _descriptionController,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.surface, height: 1.45, fontSize: 16),
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: widget.isLiveMode
                                ? 'Décrivez votre live'
                                : 'Décrivez votre short',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                          ),
                          maxLength: ValidationConstants.maxContentLength,
                          validator: (v) => (v == null || v.isEmpty)
                              ? ErrorMessages.requiredField
                              : null,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: UIConstants.paddingM),
                        Text(_error!,
                            style: const TextStyle(color: AppColors.red),
                            textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: PublishBar(
          enabled: !_isUploading,
          isSubmitting: _isUploading,
          onSubmit: _checkAndPublish,
          primaryLabel: widget.isLiveMode ? 'Démarrer' : 'Publier',
          primaryColor: widget.isLiveMode ? AppColors.red: AppColors.blue,
        ),
      ),
    );
  }
}