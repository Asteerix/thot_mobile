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
  String? _questionType;
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
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📺 QUESTION_DETAIL_SCREEN - LOAD QUESTION');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🆔 Question ID: ${widget.questionId}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.questionId);

      print('📦 Post loaded: ${post?.id} - ${post?.title}');

      if (post == null) {
        throw Exception('Question non trouvée');
      }

      // Charger les données brutes de la question
      final rawData = await _postRepository.getPost(widget.questionId);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📥 RÉCUPÉRATION QUESTION DEPUIS BACKEND');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🆔 Question ID: ${widget.questionId}');
      print('📦 Raw data keys: ${rawData.keys}');
      print('📦 Raw data complete:');
      rawData.forEach((key, value) {
        if (key == 'metadata' && value is Map) {
          print('   $key:');
          (value as Map).forEach((k, v) {
            if (k == 'question' && v is Map) {
              print('      $k:');
              (v as Map).forEach((qk, qv) {
                print('         $qk: $qv');
              });
            } else {
              print('      $k: $v');
            }
          });
        } else if (value is Map && key != 'journalist') {
          print('   $key: ${value.keys}');
        } else {
          print('   $key: $value');
        }
      });
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      Question? question;
      String? questionType;

      if (rawData['metadata'] != null && rawData['metadata']['question'] != null) {
        final questionData = Map<String, dynamic>.from(rawData['metadata']['question']);

        // Ajouter les données du journaliste depuis le post parent
        if (rawData['journalist'] != null) {
          questionData['author'] = rawData['journalist'];
          questionData['journalist'] = rawData['journalist'];
        }

        // Ajouter les autres données depuis le post parent
        questionData['id'] = rawData['_id'] ?? rawData['id'];
        questionData['title'] = rawData['title'];
        questionData['description'] = rawData['content'] ?? '';
        questionData['imageUrl'] = rawData['imageUrl'] ?? '';
        questionData['createdAt'] = rawData['createdAt'];

        // Parser les interactions correctement
        final interactions = rawData['interactions'];
        if (interactions != null && interactions is Map) {
          final likes = interactions['likes'];
          final comments = interactions['comments'];
          questionData['likes'] = (likes is Map) ? (likes['count'] ?? 0) : (likes ?? 0);
          questionData['comments'] = (comments is Map) ? (comments['count'] ?? 0) : (comments ?? 0);
          questionData['isLiked'] = interactions['isLiked'] ?? false;
        } else {
          questionData['likes'] = 0;
          questionData['comments'] = 0;
          questionData['isLiked'] = false;
        }

        // Ajouter political view (requis)
        questionData['politicalView'] = rawData['politicalOrientation']?['journalistChoice'] ?? 'neutral';

        // Ajouter votes (requis, vide par défaut)
        questionData['votes'] = questionData['voters'] ?? [];

        // S'assurer que les options ont un ID
        if (questionData['options'] is List) {
          final options = questionData['options'] as List;
          for (var i = 0; i < options.length; i++) {
            if (options[i] is Map && options[i]['id'] == null) {
              options[i]['id'] = options[i]['_id'] ?? i.toString();
            }
          }
        }

        print('📋 Question data enriched with parent data');
        print('   Journalist: ${questionData['journalist']?['name']}');
        print('   Title: ${questionData['title']}');
        print('   Likes: ${questionData['likes']}');
        print('   Comments: ${questionData['comments']}');
        print('   Political view: ${questionData['politicalView']}');
        print('   Options: ${questionData['options']?.length}');

        question = Question.fromJson(questionData);
        questionType = questionData['questionType'] ?? questionData['type'] ?? 'poll';

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ QUESTION PARSÉE');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📋 Question ID: ${question.id}');
        print('📋 Question title: ${question.title}');
        print('📋 Question type from data: ${questionData['questionType']} / ${questionData['type']}');
        print('📋 Question type final: $questionType');
        print('📋 Question options count: ${question.options.length}');
        question.options.asMap().forEach((index, option) {
          print('   Option $index: ${option.text} (votes: ${option.votes}, id: ${option.id})');
        });
        print('📋 Total votes: ${question.totalVotes}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
          _questionType = questionType;
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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎬 SHOW FULL QUESTION');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 Post: ${_post?.id}');
    print('📋 Question: ${_question?.id}');
    print('📋 Question title: ${_question?.title}');
    print('📋 Question options: ${_question?.options.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (_post == null || _question == null) {
      print('❌ Cannot show question: post or question is null');
      return;
    }

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

    final isDebate = _questionType == 'open' || _questionType == 'openEnded';
    final buttonText = isDebate ? "Débattez en commentaire" : "Répondre à la question";

    return ContentDetailLayout(
      post: _post!,
      previewWidget: _buildQuestionPreview(),
      actionButtonText: buttonText,
      onActionPressed: isDebate ? _showComments : _showFullQuestion,
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
                          decoration: TextDecoration.none,
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
