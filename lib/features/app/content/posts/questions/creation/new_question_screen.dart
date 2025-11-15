import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/shared/media/config/media_config.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/shared/media/services/upload_service.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/shared/media/widgets/media_picker.dart';
import 'package:thot/core/routing/app_router.dart';

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
  late final PostRepositoryImpl _postRepository;
  late final UploadService _uploadService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  QuestionType _questionType = QuestionType.poll;

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
    if (_selectedImage == null) {
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Veuillez ajouter une image'),
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
      final uploadResult =
          await _uploadService.uploadImage(_selectedImage!, type: 'question');
      final imageUrl = uploadResult['url'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Erreur lors de l\'upload de l\'image');
      }

      final questionData = <String, dynamic>{
        'title': _questionController.text.trim(),
        'content': _questionController.text.trim(),
        'imageUrl': imageUrl,
        'type': 'question',
        'journalist': widget.journalistId,
        'domain': widget.domain ?? 'societe',
        'status': 'published',
        'metadata': <String, dynamic>{
          'question': <String, dynamic>{
            'questionType':
                _questionType == QuestionType.poll ? 'poll' : 'openEnded',
            'type': _questionType == QuestionType.poll ? 'poll' : 'openEnded',
            'totalVotes': 0,
            'voters': <Map<String, dynamic>>[],
            if (_questionType == QuestionType.poll)
              'options': _optionControllers
                  .where((c) => c.text.trim().isNotEmpty)
                  .map((c) => <String, dynamic>{
                        'text': c.text.trim(),
                        'votes': 0,
                        'voters': <Map<String, dynamic>>[],
                      })
                  .toList(),
            if (_questionType == QuestionType.poll)
              'isMultipleChoice': _isMultipleChoice,
            'allowComments': true,
          },
        },
        'politicalOrientation': <String, dynamic>{
          'journalistChoice': 'neutral',
          'displayOrientation': 'neutral',
          'voters': <Map<String, dynamic>>[],
          'userVotes': <String, dynamic>{
            'extremelyConservative': 0,
            'conservative': 0,
            'neutral': 0,
            'progressive': 0,
            'extremelyProgressive': 0,
          },
        },
        'interactions': <String, dynamic>{
          'likes': <String, dynamic>{
            'count': 0,
            'users': <String>[],
          },
          'comments': <String, dynamic>{
            'count': 0,
          },
          'shares': 0,
          'bookmarks': 0,
          'saves': <String, dynamic>{
            'count': 0,
            'users': <String>[],
          },
        },
        'stats': <String, dynamic>{
          'views': 0,
          'shares': 0,
        },
      };

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 AVANT ENVOI AU BACKEND');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 Question data keys: ${questionData.keys}');
      print('📋 Question data complete:');
      questionData.forEach((key, value) {
        print('   $key: $value');
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final result = await _postRepository.createPost(questionData);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ RÉPONSE DU BACKEND APRÈS CRÉATION');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📦 Result type: ${result.runtimeType}');
      print('📦 Result keys: ${result.keys}');
      print('📦 Result complete:');
      result.forEach((key, value) {
        if (key == 'data' && value is Map) {
          print('   $key:');
          (value as Map).forEach((k, v) {
            print('      $k: $v');
          });
        } else {
          print('   $key: $value');
        }
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (mounted) {
        HapticFeedback.heavyImpact();

        String questionId = '';
        if (result['data'] != null && result['data'] is Map) {
          questionId = (result['data']['_id'] ?? result['data']['id'] ?? '').toString();
        } else {
          questionId = (result['_id'] ?? result['id'] ?? '').toString();
        }

        if (questionId.isEmpty) {
          throw Exception('Question ID manquant dans la réponse');
        }

        print('📋 Question ID: $questionId');

        EventBus().fire(PostCreatedEvent(
          postId: questionId,
          postType: 'question',
          journalistId: widget.journalistId,
        ));

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🚀 NAVIGATION VERS LA QUESTION');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📍 Route: ${RouteNames.questionDetail}');
        print('📍 Question ID: $questionId');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Question publiée avec succès!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2)),
        );

        Navigator.of(context).pop();
        context.go('/profile');
      }
    } catch (e, stackTrace) {
      print('❌ Error creating question: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isUploading = false);
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur lors de la publication: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildQuestionTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
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
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      color: _questionType == QuestionType.poll
                          ? Colors.black
                          : Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sondage',
                      style: TextStyle(
                        color: _questionType == QuestionType.poll
                            ? Colors.black
                            : Colors.white.withOpacity(0.6),
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
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum,
                      color: _questionType == QuestionType.openEnded
                          ? Colors.black
                          : Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Débat',
                      style: TextStyle(
                        color: _questionType == QuestionType.openEnded
                            ? Colors.black
                            : Colors.white.withOpacity(0.6),
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

  Widget _buildDomainChip() {
    final domainName = widget.domain ?? 'Société';
    final capitalizedDomain =
        domainName[0].toUpperCase() + domainName.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 14, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(
            capitalizedDomain,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Nouvelle question',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(42),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    width: double.infinity,
                    color: Colors.black,
                    child: Row(children: [
                      _buildDomainChip(),
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
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
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Votre question',
                                        style: TextStyle(
                                          color: Colors.white,
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
                                              ? Colors.orange
                                              : Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _questionController,
                                style: const TextStyle(
                                  color: Colors.white,
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
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.03),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  counterText: '',
                                  contentPadding: const EdgeInsets.all(16),
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
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
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Options de vote',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
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
                                            color:
                                                Colors.white.withOpacity(0.6),
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
                                            activeColor: Colors.white,
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
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + index),
                                              style: const TextStyle(
                                                color: Colors.white,
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
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            maxLength: 100,
                                            decoration: InputDecoration(
                                              hintText: 'Option ${index + 1}',
                                              hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.4),
                                                fontSize: 14,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.03),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              counterText: '',
                                            ),
                                          ),
                                        ),
                                        if (_optionControllers.length > 2)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red,
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
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: Colors.white),
                                      label: const Text('Ajouter une option',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
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
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Image',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
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
                                            icon: const Icon(
                                              Icons.swap_horiz,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            onPressed: _replaceImage,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.red,
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
              color: Colors.white.withOpacity(0.1),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Publication en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isUploading ? null : _publishQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isUploading ? Colors.white.withOpacity(0.3) : Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    _questionType == QuestionType.poll
                        ? 'Lancer le sondage'
                        : 'Lancer le débat',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
