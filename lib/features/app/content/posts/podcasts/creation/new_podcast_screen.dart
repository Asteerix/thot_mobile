import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/config/validation_constants.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/shared/media/services/upload_service.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/shared/media/widgets/media_picker.dart';
import 'package:thot/shared/media/widgets/audio_player_preview.dart';
import 'package:thot/features/app/content/shared/widgets/post_search_dialog.dart';
import 'package:thot/shared/widgets/forms/custom_text_field.dart';
import 'package:thot/shared/widgets/layouts/creation_screen_layout.dart';
import 'package:thot/shared/widgets/loading/upload_progress_dialog.dart';

class NewPodcastScreen extends StatefulWidget {
  final String domain;
  final String journalistId;
  final String? postId;
  final bool isEditing;
  const NewPodcastScreen({
    super.key,
    required this.domain,
    required this.journalistId,
    this.postId,
    this.isEditing = false,
  });
  @override
  State<NewPodcastScreen> createState() => _NewPodcastScreenState();
}

class _NewPodcastScreenState extends State<NewPodcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocus = FocusNode();
  final _descFocus = FocusNode();
  final _scrollController = ScrollController();
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _isDirty = false;
  String? _error;
  List<Post> _opposingPosts = [];
  File? _selectedAudio;
  File? _selectedThumbnail;
  String? _existingAudioUrl;
  String? _existingThumbnailUrl;
  Duration? _audioDuration;
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
        _existingAudioUrl = post['audioUrl'];
        _existingThumbnailUrl = post['thumbnailUrl'];
        if (post['opposingPosts'] != null &&
            (post['opposingPosts'] as List).isNotEmpty) {
          _opposingPosts = (post['opposingPosts'] as List)
              .map((op) => Post.fromJson(op))
              .toList();
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

  Future<void> _handleAudioSelected(File file) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(file.path);
      final duration = player.duration;
      await player.dispose();
      setState(() {
        _selectedAudio = file;
        _existingAudioUrl = null;
        _audioDuration = duration;
        _isDirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content:
              Text('Erreur lors de la sélection de l\'audio: ${e.toString()}'),
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

  void _removeAudio() {
    setState(() {
      _selectedAudio = null;
      _existingAudioUrl = null;
      _audioDuration = null;
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
            if (!_opposingPosts.any((p) => p.id == post.id)) {
              _opposingPosts.add(post);
            }
            _isDirty = true;
          });
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Publication ajoutée aux oppositions'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitPodcast() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    final List<String> missingItems = [];
    if (_titleController.text.trim().isEmpty) {
      missingItems.add('titre');
    }
    if (_descriptionController.text.trim().isEmpty) {
      missingItems.add('description');
    }
    if (_selectedAudio == null && _existingAudioUrl == null) {
      missingItems.add('audio');
    }
    if (_selectedThumbnail == null && _existingThumbnailUrl == null) {
      missingItems.add('miniature');
    }
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
      String audioUrl;
      String thumbnailUrl;
      if (_selectedAudio != null) {
        final progressController = StreamController<double>();
        final uploadFuture = _uploadService.uploadPodcast(
          _selectedAudio!,
          onProgress: (progress) => progressController.add(progress),
        );
        audioUrl = await UploadProgressDialog.show<String>(
              context: context,
              progressStream: progressController.stream,
              uploadFuture: uploadFuture,
              message: 'Téléchargement de l\'audio...',
            ) ??
            '';
        await progressController.close();
      } else {
        audioUrl = _existingAudioUrl!;
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
            ) ??
            '';
        await progressController.close();
      } else {
        thumbnailUrl = _existingThumbnailUrl!;
      }
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'content': _descriptionController.text.trim(),
        'domain': widget.domain,
        'type': 'podcast',
        'status': 'published',
        'journalist': widget.journalistId,
        'imageUrl': thumbnailUrl,
        'videoUrl': audioUrl,
        if (_opposingPosts.isNotEmpty)
          'opposingPosts': _opposingPosts.map((post) => {
            'postId': post.id,
          }).toList(),
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
          'podcast': {
            if (_audioDuration != null) 'duration': _audioDuration!.inSeconds,
          },
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
          postType: PostType.podcast.name,
          journalistId: widget.journalistId,
        ));
        _isDirty = false;
        if (!mounted) return;

        Navigator.of(context).pop();
        context.go('/profile');
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
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && widget.isEditing) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
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
    final hasAudio = _selectedAudio != null || _existingAudioUrl != null;
    final hasThumbnail =
        _selectedThumbnail != null || _existingThumbnailUrl != null;
    final canSubmit = _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        hasAudio &&
        hasThumbnail;
    return WillPopScope(
      onWillPop: () async {
        if (_isDirty && !_isSubmitting) {
          final leave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.surface,
              title: Text('Quitter sans enregistrer ?',
                  style: TextStyle(color: Colors.white)),
              content: Text(
                'Vous avez des modifications non publiées.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler',
                      style: TextStyle(color: AppColors.primary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      Text('Quitter', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          return leave ?? false;
        }
        return true;
      },
      child: CreationScreenLayout(
        title: widget.isEditing ? 'Modifier le podcast' : 'Nouveau podcast',
        subtitle: _audioDuration != null
            ? '${widget.domain} • ${_audioDuration!.inMinutes} min'
            : widget.domain,
        scrollController: _scrollController,
        onSubmit: _submitPodcast,
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
                hint: 'Titre du podcast',
                maxLength: ValidationConstants.maxTitleLength,
                counterText: '',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
                onFieldSubmitted: (_) => _descFocus.requestFocus(),
              ),
              SizedBox(height: 16.0),
              CreationSection(
                title: 'Fichier audio',
                padding: EdgeInsets.zero,
                child: hasAudio
                    ? Stack(
                        children: [
                          if (_selectedAudio != null)
                            AudioPlayerPreview(audioFile: _selectedAudio!)
                          else
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(Icons.music_note,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeAudio,
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
                        type: MediaType.podcast,
                        onMediaSelected: _handleAudioSelected,
                        height: 100,
                      ),
              ),
              SizedBox(height: 16.0),
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
              SizedBox(height: 16.0),
              CustomTextField(
                controller: _descriptionController,
                focusNode: _descFocus,
                label: 'Description',
                hint: 'Décrivez votre podcast...',
                maxLines: 5,
                maxLength: ValidationConstants.maxContentLength,
                keyboardType: TextInputType.multiline,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
              ),
              SizedBox(height: 16.0),
              CreationSection(
                title: 'Publications en opposition (optionnel)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._opposingPosts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final post = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: post.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    post.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCard
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(Icons.podcasts,
                                          color: Colors.white.withOpacity(0.5)),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCard
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(Icons.podcasts,
                                      color: Colors.white.withOpacity(0.5)),
                                ),
                          title: Text(
                            post.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.5)),
                            onPressed: () {
                              setState(() {
                                _opposingPosts.removeAt(index);
                                _isDirty = true;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    Center(
                      child: TextButton.icon(
                        onPressed: _searchOpposingPost,
                        icon: Icon(Icons.add, color: AppColors.primary),
                        label: Text('Ajouter une publication',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 16.0),
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
