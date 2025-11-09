import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/media/domain/config/media_config.dart';
import 'package:thot/core/constants/validation_constants.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/media/infrastructure/upload_service.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/media/presentation/shared/widgets/media_picker.dart';
import 'package:thot/features/media/presentation/shared/widgets/video_player_preview.dart';
import 'package:thot/features/posts/presentation/shared/widgets/post_search_dialog.dart';
import 'package:thot/shared/widgets/forms/custom_text_field.dart';
import 'package:thot/shared/widgets/screens/creation_screen_layout.dart';
import 'package:thot/shared/widgets/common/upload_progress_dialog.dart';
class NewVideoScreen extends StatefulWidget {
  final String domain;
  final String journalistId;
  final String? postId;
  final bool isEditing;
  const NewVideoScreen({
    super.key,
    required this.domain,
    required this.journalistId,
    this.postId,
    this.isEditing = false,
  });
  @override
  State<NewVideoScreen> createState() => _NewVideoScreenState();
}
class _NewVideoScreenState extends State<NewVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _isDirty = false;
  String? _error;
  Post? _opposingPost;
  String? _oppositionDescription = '';
  File? _selectedVideo;
  File? _selectedThumbnail;
  String? _existingVideoUrl;
  String? _existingThumbnailUrl;
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _uploadService = UploadService();
    _titleController.addListener(() => setState(() => _isDirty = true));
    _descriptionController.addListener(() => setState(() => _isDirty = true));
    if (widget.isEditing && widget.postId != null) {
      _loadExistingPost();
    }
  }
  Future<void> _loadExistingPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final post = await _postRepository.getPost(widget.postId!);
      if (!mounted) return;
      setState(() {
        _titleController.text = post['title'] ?? '';
        _descriptionController.text = post['content'] ?? '';
        _existingVideoUrl = post['videoUrl'];
        _existingThumbnailUrl = post['thumbnailUrl'];
        if (post['opposingPosts'] != null &&
            (post['opposingPosts'] as List).isNotEmpty) {
          final opposingPost = post['opposingPosts'][0];
          _opposingPost = Post.fromJson(opposingPost);
          _oppositionDescription = opposingPost['description'] ?? '';
        }
        _isLoading = false;
        _isDirty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMessageHelper.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _handleVideoSelected(File file) async {
    try {
      final c = VideoPlayerController.file(file);
      await c.initialize();
      final duration = c.value.duration;
      await c.dispose();
      final max = Duration(seconds: MediaConfig.videoMaxDuration);
      if (duration > max) {
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text(
                'La durée maximale est de ${max.inMinutes} min. Votre vidéo fait ${duration.inMinutes} min ${duration.inSeconds % 60}s.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() {
        _selectedVideo = file;
        _existingVideoUrl = null;
        _isDirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Erreur lors de la sélection de la vidéo: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  void _handleThumbnailSelected(File file) {
    setState(() {
      _selectedThumbnail = file;
      _existingThumbnailUrl = null;
      _isDirty = true;
    });
  }
  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _existingVideoUrl = null;
      _isDirty = true;
    });
  }
  void _removeThumbnail() {
    setState(() {
      _selectedThumbnail = null;
      _existingThumbnailUrl = null;
      _isDirty = true;
    });
  }
  Future<void> _searchOpposingPost() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PostSearchDialog(
        onPostSelected: (post) {
          setState(() {
            _opposingPost = post;
            _oppositionDescription = '';
            _isDirty = true;
          });
          final isDark = Theme.of(context).brightness == Brightness.dark;
          SafeNavigation.showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
              title: Text('Raison de l\'opposition', style: TextStyle(color: Colors.white)),
              content: TextField(
                onChanged: (value) => _oppositionDescription = value,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Expliquez pourquoi cette publication est en opposition...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  onPressed: () => SafeNavigation.pop(context),
                  child: Text('Valider', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Future<void> _submitVideo() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    final List<String> missingItems = [];
    if (_titleController.text.trim().isEmpty) missingItems.add('titre');
    if (_descriptionController.text.trim().isEmpty) missingItems.add('description');
    if (_selectedVideo == null && _existingVideoUrl == null) missingItems.add('vidéo');
    if (_selectedThumbnail == null && _existingThumbnailUrl == null) missingItems.add('miniature');
    if (missingItems.isNotEmpty) {
      HapticFeedback.lightImpact();
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Éléments manquants: ${missingItems.join(', ')}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      String videoUrl;
      String thumbnailUrl;
      if (_selectedVideo != null) {
        final progressController = StreamController<double>();
        final uploadFuture = _uploadService.uploadVideo(
          _selectedVideo!,
          onProgress: (progress) => progressController.add(progress),
        );
        videoUrl = await UploadProgressDialog.show<String>(
              context: context,
              progressStream: progressController.stream,
              uploadFuture: uploadFuture,
              message: 'Téléchargement de la vidéo...',
            ) ?? '';
        await progressController.close();
      } else {
        videoUrl = _existingVideoUrl!;
      }
      if (_selectedThumbnail != null) {
        final progressController = StreamController<double>();
        final uploadFuture = _uploadService.uploadThumbnail(
          _selectedThumbnail!,
          onProgress: (progress) => progressController.add(progress),
        );
        thumbnailUrl = await UploadProgressDialog.show<String>(
              context: context,
              progressStream: progressController.stream,
              uploadFuture: uploadFuture,
              message: 'Téléchargement de la miniature...',
            ) ?? '';
        await progressController.close();
      } else {
        thumbnailUrl = _existingThumbnailUrl!;
      }
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'content': _descriptionController.text.trim(),
        'domain': widget.domain,
        'type': PostTypes.video,
        'status': 'published',
        'journalistId': widget.journalistId,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        if (_opposingPost != null)
          'opposingPosts': [
            {
              'postId': _opposingPost!.id,
              'description': _oppositionDescription ?? ''
            }
          ],
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
      };
      if (widget.isEditing) {
        await _postRepository.updatePost(widget.postId!, data);
        EventBus().fire(PostUpdatedEvent(postId: widget.postId!));
        if (!mounted) return;
        _isDirty = false;
        SafeNavigation.pop(context, true);
      } else {
        final result = await _postRepository.createPost(data);
        String? postId;
        if (result['_id'] != null) {
          postId = result['_id'];
        } else if (result['data'] != null && result['data']['_id'] != null) {
          postId = result['data']['_id'];
        }
        EventBus().fire(PostCreatedEvent(
          postId: postId ?? '',
          postType: PostTypes.video,
          journalistId: widget.journalistId,
        ));
        _isDirty = false;
        if (!mounted) return;
        if (postId != null) {
          GoRouter.of(context).go(
            '/post/$postId',
            extra: {
              'postId': postId,
              'isFromProfile': false,
              'filterType': PostType.video,
              'isFromFeed': true,
            },
          );
        } else {
          SafeNavigation.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMessageHelper.getUserFriendlyMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && widget.isEditing) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $_error',
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExistingPost,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    final hasVideo = _selectedVideo != null || _existingVideoUrl != null;
    final hasThumbnail = _selectedThumbnail != null || _existingThumbnailUrl != null;
    final canSubmit = _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        hasVideo &&
        hasThumbnail;
    return WillPopScope(
      onWillPop: () async {
        if (_isDirty && !_isSubmitting) {
          final leave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
              title: Text('Quitter sans enregistrer ?',
                  style: TextStyle(color: Colors.white)),
              content: Text(
                'Vous avez des modifications non publiées.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler', style: TextStyle(color: AppColors.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Quitter', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          return leave ?? false;
        }
        return true;
      },
      child: CreationScreenLayout(
        title: widget.isEditing ? 'Modifier la vidéo' : 'Nouvelle vidéo',
        subtitle: widget.domain,
        scrollController: _scrollController,
        onSubmit: _submitVideo,
        isSubmitting: _isSubmitting,
        canSubmit: canSubmit,
        submitLabel: widget.isEditing ? 'Enregistrer' : 'Publier',
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
                hint: 'Titre de la vidéo',
                maxLength: ValidationConstants.maxTitleLength,
                counterText: '',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
                onFieldSubmitted: (_) => _descFocus.requestFocus(),
              ),
              SizedBox(height: UIConstants.paddingM),
              CreationSection(
                title: 'Vidéo',
                padding: EdgeInsets.zero,
                child: hasVideo
                    ? Stack(
                        children: [
                          if (_selectedVideo != null)
                            VideoPlayerPreview(videoFile: _selectedVideo!)
                          else
                            Container(
                              height: 200,
                              color: Colors.black,
                              child: Center(
                                child: Icon(Icons.play_circle,
                                    size: 64, color: Colors.white),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeVideo,
                              icon: Icon(Icons.delete),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : MediaPicker(
                        type: MediaType.video,
                        onMediaSelected: _handleVideoSelected,
                        height: 200,
                      ),
              ),
              SizedBox(height: UIConstants.paddingM),
              CreationSection(
                title: 'Miniature',
                padding: EdgeInsets.zero,
                child: hasThumbnail
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedThumbnail != null
                                ? Image.file(
                                    _selectedThumbnail!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _existingThumbnailUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeThumbnail,
                              icon: Icon(Icons.delete),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.6),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : MediaPicker(
                        type: MediaType.article,
                        onMediaSelected: _handleThumbnailSelected,
                        height: 150,
                      ),
              ),
              SizedBox(height: UIConstants.paddingM),
              CustomTextField(
                controller: _descriptionController,
                focusNode: _descFocus,
                label: 'Description',
                hint: 'Décrivez votre vidéo...',
                maxLines: 5,
                maxLength: ValidationConstants.maxContentLength,
                keyboardType: TextInputType.multiline,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
              ),
              SizedBox(height: UIConstants.paddingM),
              CreationSection(
                title: 'Publication en opposition (optionnel)',
                child: _opposingPost != null
                    ? ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _opposingPost!.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  _opposingPost!.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.surface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.videocam,
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                        title: Text(
                          _opposingPost!.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: _oppositionDescription?.isNotEmpty ?? false
                            ? Text(
                                _oppositionDescription!,
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
                          onPressed: () {
                            setState(() {
                              _opposingPost = null;
                              _oppositionDescription = '';
                              _isDirty = true;
                            });
                          },
                        ),
                      )
                    : Center(
                        child: TextButton.icon(
                          onPressed: _searchOpposingPost,
                          icon: Icon(Icons.add, color: AppColors.primary),
                          label: Text('Ajouter une publication',
                              style: TextStyle(color: AppColors.primary)),
                        ),
                      ),
              ),
              if (_error != null) ...[
                SizedBox(height: UIConstants.paddingM),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}