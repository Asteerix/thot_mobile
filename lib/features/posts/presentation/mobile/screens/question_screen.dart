import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/posts/domain/entities/question.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/question_cards.dart';
class QuestionScreen extends StatefulWidget {
  final String questionId;
  final String journalistId;
  const QuestionScreen({
    super.key,
    required this.questionId,
    required this.journalistId,
  });
  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}
class _QuestionScreenState extends State<QuestionScreen> {
  late final PostRepositoryImpl _postRepository =
      ServiceLocator.instance.postRepository;
  Question? _question;
  Post? _post;
  bool _isLoading = true;
  String? _error;
  final _responseController = TextEditingController();
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }
  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
  Future<void> _loadQuestion() async {
    try {
      try {
        final postData = await _postRepository.getPost(widget.questionId);
        if (!mounted) return;
        setState(() {
          _post = Post.fromJson(postData);
          _question = Question.fromJson(postData);
          _isLoading = false;
        });
        return;
      } catch (_) {
      }
      final response = await _postRepository.getQuestion(
        widget.questionId,
      );
      if (!mounted) return;
      setState(() {
        _question = Question.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  Future<void> _submitResponse() async {
    if (_responseController.text.isEmpty) return;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await _postRepository.respondToQuestion(
        widget.journalistId,
        widget.questionId,
        _responseController.text,
      );
      if (!mounted) return;
      _responseController.clear();
      _loadQuestion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
                style: TextStyle(color: AppColors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestion,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_question == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Question introuvable',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Question'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuestionCard(
                    question: _question!,
                    onVote: (optionId, optionText) async {
                      try {
                        if (_post != null && optionId != null) {
                          await _postRepository.voteOnQuestion(
                            _post!.id,
                            optionId,
                          );
                        } else {
                          await _postRepository.answerQuestion(
                            widget.journalistId,
                            _question!.id,
                            optionText,
                          );
                        }
                        _loadQuestion();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    isExpanded: true,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _responseController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Votre réponse...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.blue),
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send),
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}