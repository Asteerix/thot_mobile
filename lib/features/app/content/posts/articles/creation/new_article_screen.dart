import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/config/validation_constants.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/shared/media/services/upload_service.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/shared/widgets/loading/upload_progress_dialog.dart';
import 'package:thot/shared/media/widgets/media_picker.dart';
import 'package:thot/features/app/content/shared/widgets/post_search_dialog.dart';
import 'package:thot/shared/widgets/forms/custom_text_field.dart';
import 'package:thot/shared/widgets/layouts/creation_screen_layout.dart';

class NewArticleScreen extends StatefulWidget {
  final String domain;
  final String journalistId;
  final String? postId;
  final bool isEditing;
  const NewArticleScreen({
    super.key,
    required this.domain,
    required this.journalistId,
    this.postId,
    this.isEditing = false,
  });
  @override
  State<NewArticleScreen> createState() => _NewArticleScreenState();
}

class _NewArticleScreenState extends State<NewArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();
  final _scrollController = ScrollController();
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _error;
  bool _isDirty = false;
  List<Post> _opposingPosts = [];
  File? _selectedImage;
  String? _existingImageUrl;
  int _wordCount = 0;
  int _readingMinutes = 0;
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _uploadService = UploadService();
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    if (widget.isEditing && widget.postId != null) {
      _loadExistingPost();
    }
  }

  void _onTextChanged() {
    setState(() {
      _isDirty = true;
      _wordCount = _countWords(_contentController.text);
      _readingMinutes = (_wordCount / 220).ceil().clamp(1, 60);
    });
  }

  int _countWords(String s) {
    final words = s
        .replaceAll(RegExp(r"\s+"), " ")
        .trim()
        .split(" ")
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isEmpty ? 0 : words.length;
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
        _contentController.text = post['content'] ?? '';
        _existingImageUrl = post['imageUrl'];
        if (post['opposingPosts'] != null &&
            (post['opposingPosts'] as List).isNotEmpty) {
          _opposingPosts = (post['opposingPosts'] as List)
              .map((op) => Post.fromJson(op))
              .toList();
        }
        _wordCount = _countWords(_contentController.text);
        _readingMinutes = (_wordCount / 220).ceil().clamp(1, 60);
        _isLoading = false;
        _isDirty = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleImageSelected(File file) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedImage = file;
      _existingImageUrl = null;
      _isDirty = true;
    });
  }

  void _removeImage() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
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

  Future<void> _submitArticle() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }
    final List<String> missingItems = [];
    if (_titleController.text.trim().isEmpty) missingItems.add('titre');
    if (_contentController.text.trim().isEmpty) missingItems.add('contenu');
    if (_selectedImage == null && _existingImageUrl == null) {
      missingItems.add('image');
    }
    if (missingItems.isNotEmpty) {
      HapticFeedback.lightImpact();
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Éléments manquants: ${missingItems.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      String imageUrl;
      if (_selectedImage != null) {
        final progressController = StreamController<double>();
        final uploadFuture = _uploadService.uploadArticleImage(
          _selectedImage!,
          onProgress: (progress) => progressController.add(progress),
        );
        imageUrl = await UploadProgressDialog.show<String>(
              context: context,
              progressStream: progressController.stream,
              uploadFuture: uploadFuture,
              message: 'Téléchargement de l\'image...',
            ) ??
            '';
        await progressController.close();
      } else {
        imageUrl = _existingImageUrl!;
      }
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'domain': widget.domain,
        'type': 'article',
        'status': 'published',
        'journalist': widget.journalistId,
        'imageUrl': imageUrl,
        if (_opposingPosts.isNotEmpty)
          'opposingPosts': _opposingPosts.map((post) => {
            'postId': post.id,
          }).toList(),
        'politicalOrientation': <String, dynamic>{
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
      Map<String, dynamic> result;
      if (widget.isEditing) {
        result = await _postRepository.updatePost(widget.postId!, data);
        EventBus().fire(PostUpdatedEvent(postId: widget.postId!));
        if (!mounted) return;
        _isDirty = false;
        SafeNavigation.pop(context, true);
      } else {
        result = await _postRepository.createPost(data);
        String? postId;
        if (result['_id'] != null) {
          postId = result['_id'];
        } else if (result['data'] != null && result['data']['_id'] != null) {
          postId = result['data']['_id'];
        }
        _isDirty = false;
        if (!mounted) return;

        EventBus().fire(PostCreatedEvent(
          postId: postId ?? '',
          postType: PostType.article.name,
          journalistId: widget.journalistId,
        ));

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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    if (_error != null && widget.isEditing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur: $_error',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExistingPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text('Réessayer', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }
    final hasImage = _selectedImage != null || _existingImageUrl != null;
    final canSubmit = _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty &&
        hasImage;
    return WillPopScope(
      onWillPop: () async {
        if (_isDirty && !_isSubmitting) {
          final leave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black,
              title: Text('Quitter sans enregistrer ?',
                  style: TextStyle(color: Colors.white)),
              content: Text(
                'Vous avez des modifications non publiées.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Quitter', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          return leave ?? false;
        }
        return true;
      },
      child: CreationScreenLayout(
        title: widget.isEditing ? 'Modifier l\'article' : 'Nouvel article',
        subtitle: '${widget.domain} • $_readingMinutes min de lecture',
        scrollController: _scrollController,
        onSubmit: _submitArticle,
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
                hint: 'Titre de l\'article',
                maxLength: ValidationConstants.maxTitleLength,
                counterText: '',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? ErrorMessages.requiredField
                    : null,
                onFieldSubmitted: (_) => _contentFocus.requestFocus(),
              ),
              SizedBox(height: 16.0),
              CreationSection(
                title: 'Image de couverture',
                padding: EdgeInsets.zero,
                child: hasImage
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    _existingImageUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeImage,
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
                        onMediaSelected: _handleImageSelected,
                        height: 200,
                      ),
              ),
              SizedBox(height: 16.0),
              CustomTextField(
                controller: _contentController,
                focusNode: _contentFocus,
                label: 'Contenu',
                hint: 'Rédigez votre article...',
                maxLines: 15,
                maxLength: ValidationConstants.maxContentLength,
                keyboardType: TextInputType.multiline,
                counterText:
                    '$_wordCount mots • $_readingMinutes min • ${_contentController.text.length}/${ValidationConstants.maxContentLength}',
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
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(Icons.article,
                                          color: Colors.white.withOpacity(0.5)),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(Icons.article,
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
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text('Ajouter une publication',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 16.0),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
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
