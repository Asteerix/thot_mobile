import 'package:thot/core/presentation/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/core/presentation/extensions/context_extensions.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/shared/media/services/upload_service.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/shared/media/widgets/media_picker.dart';
import 'package:thot/features/app/content/shared/widgets/editor_ui.dart';

enum QuestionType { poll, openEnded }

class NewQuestionScreen extends StatefulWidget {
  final String journalistId;
  final String? domain;
  final String? questionType;
  const NewQuestionScreen({
    super.key,
    required this.journalistId,
    this.domain,
    this.questionType,
  });
  @override
  State<NewQuestionScreen> createState() => _NewQuestionScreenState();
}

class _NewQuestionScreenState extends State<NewQuestionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(2, (_) => TextEditingController());
  final _scrollController = ScrollController();
  bool _isMultipleChoice = false;
  File? _selectedImage;
  bool _isUploading = false;
  int _currentStep = 0;
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  QuestionType _questionType = QuestionType.poll;
  String? _selectedDomain;
  static final List<Map<String, dynamic>> _domains = [
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
      'icon': Icons.group,
      'color': AppColors.success
    },
    {
      'id': 'psychologie',
      'title': 'Psychologie',
      'icon': Icons.psychology,
      'color': AppColors.red
    },
    {
      'id': 'sport',
      'title': 'Sport',
      'icon': Icons.emoji_events,
      'color': AppColors.warning
    },
    {
      'id': 'technologie',
      'title': 'Technologie',
      'icon': Icons.laptop,
      'color': AppColors.blue
    },
  ];
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _uploadService = UploadService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    if (widget.domain != null) {
      _selectedDomain = widget.domain;
      _currentStep = 1;
    }
    if (widget.questionType != null) {
      _questionType = widget.questionType == 'debate'
          ? QuestionType.openEnded
          : QuestionType.poll;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleImageSelected(File file) {
    setState(() => _selectedImage = file);
    HapticFeedback.lightImpact();
  }

  void _removeImage() {
    HapticFeedback.lightImpact();
    setState(() => _selectedImage = null);
  }

  void _replaceImage() {
    HapticFeedback.lightImpact();
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
                type: MediaType.question,
                onMediaSelected: (file) {
                  _handleImageSelected(file);
                  SafeNavigation.pop(context);
                },
                height: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
      HapticFeedback.lightImpact();
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
      HapticFeedback.lightImpact();
    }
  }

  bool _validateQuestion() {
    if (_questionController.text.trim().isEmpty) {
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Veuillez entrer une question'),
          backgroundColor: AppColors.orange,
        ),
      );
      return false;
    }
    if (_questionType == QuestionType.poll) {
      final validOptions =
          _optionControllers.where((c) => c.text.trim().isNotEmpty).toList();
      if (validOptions.length < 2) {
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Ajoutez au moins 2 options de vote'),
            backgroundColor: AppColors.orange,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _publishQuestion() async {
    if (!_validateQuestion()) return;
    setState(() => _isUploading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final uploadResult =
            await _uploadService.uploadImage(_selectedImage!, type: 'question');
        imageUrl = uploadResult['url'] as String?;
      }
      final data = {
        'title': _questionController.text.trim(),
        'content': _questionController.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'type': 'question',
        'journalist': widget.journalistId,
        'domain': _selectedDomain ?? 'societe',
        'status': 'published',
        'metadata': {
          'question': {
            'questionType':
                _questionType == QuestionType.poll ? 'poll' : 'open',
            'type': _questionType == QuestionType.poll ? 'poll' : 'open',
            if (_questionType == QuestionType.poll) ...{
              'options': _optionControllers
                  .where((c) => c.text.trim().isNotEmpty)
                  .map((c) => {
                        'text': c.text.trim(),
                        'votes': 0,
                      })
                  .toList(),
              'isMultipleChoice': _isMultipleChoice,
            },
            'totalVotes': 0,
          },
        },
      };
      final result = await _postRepository.createPost(data);
      if (mounted) {
        HapticFeedback.heavyImpact();
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
              content: Text('Question publiée avec succès!'),
              backgroundColor: AppColors.success),
        );
        context.pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onPrimary),
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
              HapticFeedback.lightImpact();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (domain['color'] as Color).withOpacity(0.2),
                    (domain['color'] as Color).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (domain['color'] as Color).withOpacity(0.3),
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

  Widget _buildQuestionTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _questionType = QuestionType.poll);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _questionType == QuestionType.poll
                      ? Colors.blue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: _questionType == QuestionType.poll
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sondage',
                      style: TextStyle(
                        color: _questionType == QuestionType.poll
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _questionType = QuestionType.openEnded);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _questionType == QuestionType.openEnded
                      ? Colors.purple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum,
                      color: _questionType == QuestionType.openEnded
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Débat',
                      style: TextStyle(
                        color: _questionType == QuestionType.openEnded
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 0) {
      return _buildDomainSelection();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.black,
                centerTitle: true,
                title: Text(
                  'Nouvelle question',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuestionTypeSelector(),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withOpacity(0.5),
                                Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _questionType == QuestionType.poll
                                            ? Icons.help_outline
                                            : Icons.forum,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Votre question',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_questionController.text.length}/300',
                                    style: TextStyle(
                                      color:
                                          _questionController.text.length > 280
                                              ? AppColors.warning
                                              : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _questionController,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                maxLength: 300,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _questionType == QuestionType.poll
                                      ? 'Ex: Quelle est votre opinion sur...?'
                                      : 'Ex: Que pensez-vous de...? Débattons!',
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_questionType == QuestionType.poll) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.list,
                                            size: 18,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Options de vote',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _isMultipleChoice
                                              ? 'Multiple'
                                              : 'Unique',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: _isMultipleChoice,
                                            onChanged: (v) {
                                              setState(
                                                  () => _isMultipleChoice = v);
                                              HapticFeedback.selectionClick();
                                            },
                                            activeThumbColor: AppColors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(_optionControllers.length,
                                    (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.blue.withOpacity(0.2),
                                                AppColors.purple
                                                    .withOpacity(0.2),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + index),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                _optionControllers[index],
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              fontSize: 15,
                                            ),
                                            maxLength: 100,
                                            decoration: InputDecoration(
                                              hintText: 'Option ${index + 1}',
                                              hintStyle: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 14,
                                              ),
                                              filled: true,
                                              fillColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              counterText: '',
                                            ),
                                          ),
                                        ),
                                        if (_optionControllers.length > 2)
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors.error,
                                            ),
                                            onPressed: () =>
                                                _removeOption(index),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                if (_optionControllers.length < 6)
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: _addOption,
                                      icon: Icon(Icons.add_circle_outline),
                                      label: Text('Ajouter une option'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.blue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.image,
                                            size: 18,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Image (optionnelle)',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_selectedImage != null)
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.swap_horiz,
                                              color: AppColors.info,
                                              size: 20,
                                            ),
                                            onPressed: _replaceImage,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: AppColors.error,
                                              size: 20,
                                            ),
                                            onPressed: _removeImage,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : MediaPicker(
                                          type: MediaType.question,
                                          onMediaSelected: _handleImageSelected,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              (9 / 16),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Publication en cours...',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: PublishBar(
        enabled: !_isUploading,
        isSubmitting: _isUploading,
        onSubmit: _publishQuestion,
        primaryLabel: _questionType == QuestionType.poll
            ? 'Lancer le sondage'
            : 'Lancer le débat',
        primaryColor: _questionType == QuestionType.poll
            ? AppColors.blue
            : AppColors.purple,
      ),
    );
  }
}
