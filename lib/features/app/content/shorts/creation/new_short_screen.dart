import 'package:thot/core/presentation/theme/app_colors.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/config/validation_constants.dart';
import 'package:thot/core/presentation/extensions/context_extensions.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/shared/media/services/upload_service.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/shared/media/widgets/media_picker.dart';
import 'package:thot/shared/media/widgets/video_player_preview.dart';
import 'package:thot/shared/widgets/loading/upload_progress_dialog.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/shared/widgets/forms/custom_text_field.dart';
import 'package:thot/shared/widgets/layouts/creation_screen_layout.dart';
import '../feed/shorts_feed_screen.dart';

class NewShortScreen extends StatefulWidget {
  final String journalistId;
  final bool isLiveMode;
  final String? domain;
  const NewShortScreen({
    super.key,
    required this.journalistId,
    this.isLiveMode = false,
    this.domain,
  });
  @override
  State<NewShortScreen> createState() => _NewShortScreenState();
}

class _NewShortScreenState extends State<NewShortScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  File? _selectedVideo;
  File? _selectedThumbnail;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  String? _error;
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
    _titleFocus.dispose();
    _descriptionFocus.dispose();
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
        SafeNavigation.showSnackBar(
            context,
            SnackBar(
                content: Text(e.toString()), backgroundColor: AppColors.red));
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
          color: Colors.black,
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
                color: Colors.white.withOpacity(0.1),
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
          color: Colors.black,
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
                color: Colors.white.withOpacity(0.1),
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
        'type': widget.isLiveMode ? PostType.live : PostType.short,
        'journalist': widget.journalistId,
        'domain': widget.domain ?? 'societe',
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
            postType: PostType.short.name,
            journalistId: widget.journalistId));

        Navigator.of(context).pop();
        context.go('/profile');
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

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Container(
                color: Colors.black,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Upload en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veuillez patienter',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 14),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Réessayer')),
          ]),
        ),
      );
    }

    final hasVideo = _selectedVideo != null;
    final hasThumbnail = _selectedThumbnail != null;
    final canSubmit = _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        hasVideo &&
        hasThumbnail;

    return AbsorbPointer(
      absorbing: _isUploading,
      child: CreationScreenLayout(
        title: widget.isLiveMode ? 'Nouveau live' : 'Nouveau short',
        subtitle: widget.domain ?? 'Société',
        scrollController: _scrollController,
        onSubmit: _checkAndPublish,
        isSubmitting: _isUploading,
        canSubmit: canSubmit,
        submitLabel: widget.isLiveMode ? 'Démarrer' : 'Continuer',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleController,
                focusNode: _titleFocus,
                textInputAction: TextInputAction.next,
                label: 'Titre',
                hint: widget.isLiveMode ? 'Titre du live' : 'Titre du short',
                maxLength: ValidationConstants.maxTitleLength,
                counterText: '',
                validator: (v) => (v == null || v.isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
                onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
              ),
              SizedBox(height: 16.0),
              CreationSection(
                title: 'Vidéo (portrait 9:16, ≤ 30s)',
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedVideo != null)
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                              borderRadius: BorderRadius.circular(12.0),
                              child: VideoPlayerPreview(
                                  videoFile: _selectedVideo!,
                                  height: MediaQuery.of(context).size.width *
                                      (16 / 9),
                                  autoPlay: true,
                                  type: MediaType.short),
                            )
                          : MediaPicker(
                              type: MediaType.short,
                              onMediaSelected: _handleVideoSelected,
                              height: MediaQuery.of(context).size.width *
                                  (16 / 9)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              CreationSection(
                title: 'Miniature (portrait 9:16)',
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedThumbnail != null)
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.file(_selectedThumbnail!,
                                  fit: BoxFit.cover),
                            )
                          : MediaPicker(
                              type: MediaType.shortThumbnail,
                              onMediaSelected: _handleThumbnailSelected,
                              height: MediaQuery.of(context).size.width *
                                  (16 / 9)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              CustomTextField(
                controller: _descriptionController,
                focusNode: _descriptionFocus,
                label: 'Description',
                hint: widget.isLiveMode
                    ? 'Décrivez votre live'
                    : 'Décrivez votre short',
                maxLines: 8,
                maxLength: ValidationConstants.maxContentLength,
                validator: (v) => (v == null || v.isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
              ),
              if (_error != null) ...[
                SizedBox(height: 16.0),
                Text(_error!,
                    style: const TextStyle(color: AppColors.red),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
