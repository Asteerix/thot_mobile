import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/models/question.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/widgets/content_detail_layout.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import 'package:thot/features/app/content/posts/questions/widgets/question_answer_dialog.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';

/// Écran de détail pour les questions
class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final _postRepository = ServiceLocator.instance.postRepository;
  Post? _post;
  Question? _question;
  List<Post>? _opposingPosts;
  List<Post>? _relatedPosts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestion();
    });
  }

  Future<void> _loadQuestion() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.questionId);

      if (post == null) {
        throw Exception('Question non trouvée');
      }

      // Charger les données brutes de la question
      final rawData = await _postRepository.getPost(widget.questionId);
      Question? question;

      if (rawData['metadata'] != null && rawData['metadata']['question'] != null) {
        question = Question.fromJson(rawData['metadata']['question']);
      }

      // Charger les posts en opposition et relatés
      final opposing = <Post>[];
      final related = <Post>[];

      if (post.opposingPosts != null) {
        for (final opposingData in post.opposingPosts!) {
          try {
            final opposingPost = await postsStateProvider.loadPost(opposingData.postId);
            if (opposingPost != null) opposing.add(opposingPost);
          } catch (e) {
            debugPrint('Erreur chargement post opposé: $e');
          }
        }
      }

      if (post.relatedPosts != null) {
        for (final relatedPost in post.relatedPosts!) {
          related.add(relatedPost);
        }
      }

      if (mounted) {
        setState(() {
          _post = post;
          _question = question;
          _opposingPosts = opposing.isEmpty ? null : opposing;
          _relatedPosts = related.isEmpty ? null : related;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }


  void _showFullQuestion() {
    if (_post == null || _question == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuestionAnswerDialog(
        post: _post!,
        question: _question!,
      ),
    );
  }

  void _showComments() {
    if (_post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(postId: _post!.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_error != null || _post == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Question non trouvée',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestion,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return ContentDetailLayout(
      post: _post!,
      previewWidget: _buildQuestionPreview(),
      actionButtonText: "Répondre à la question",
      onActionPressed: _showFullQuestion,
      onComment: _showComments,
      opposingPosts: _opposingPosts,
      relatedPosts: _relatedPosts,
    );
  }

  Widget _buildQuestionPreview() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blue.withOpacity(0.8),
              AppColors.purple.withOpacity(0.8),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (_post!.imageUrl != null)
                Opacity(
                  opacity: 0.3,
                  child: Image.network(
                    _post!.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _question?.title ?? _post!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Question',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
