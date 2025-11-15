import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/widgets/content_detail_layout.dart';
import 'package:thot/features/app/content/shared/widgets/content_description_dialog.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import 'package:thot/core/di/service_locator.dart';

/// Écran de détail pour les articles
class ArticleDetailScreen extends StatefulWidget {
  final String postId;

  const ArticleDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _postRepository = ServiceLocator.instance.postRepository;
  Post? _post;
  List<Post>? _opposingPosts;
  List<Post>? _relatedPosts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArticle();
    });
  }

  Future<void> _loadArticle() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.postId);

      if (post == null) {
        throw Exception('Article non trouvé');
      }

      // Charger les posts en opposition et relatés
      final opposing = <Post>[];
      final related = <Post>[];

      if (post.opposingPosts != null) {
        for (final opposingData in post.opposingPosts!) {
          try {
            final opposingPost =
                await postsStateProvider.loadPost(opposingData.postId);
            if (opposingPost != null) opposing.add(opposingPost);
          } catch (e) {
            debugPrint('Erreur chargement post opposé: $e');
          }
        }
      }

      if (post.opposedByPosts != null) {
        for (final opposedData in post.opposedByPosts!) {
          try {
            final opposedPost =
                await postsStateProvider.loadPost(opposedData.postId);
            if (opposedPost != null) opposing.add(opposedPost);
          } catch (e) {
            debugPrint('Erreur chargement post opposé par: $e');
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

  void _showFullArticle() {
    if (_post == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentDescriptionDialog(post: _post!),
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

  int _calculateReadingTime(String content) {
    if (content.isEmpty) return 5;
    final wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil();
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
                _error ?? 'Article non trouvé',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadArticle,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return ContentDetailLayout(
      post: _post!,
      previewWidget: _buildArticlePreview(),
      actionButtonText: "Lire l'article complet",
      onActionPressed: _showFullArticle,
      onComment: _showComments,
      opposingPosts: _opposingPosts,
      relatedPosts: _relatedPosts,
    );
  }

  Widget _buildArticlePreview() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_post!.imageUrl != null)
                Image.network(
                  _post!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.article, color: Colors.white54, size: 64),
                  ),
                )
              else
                const Center(
                  child: Icon(Icons.article, color: Colors.white54, size: 64),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Article',
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
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_calculateReadingTime(_post!.content)} min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
