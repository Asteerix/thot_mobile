import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/posts/articles/screens/article_detail_screen.dart';
import 'package:thot/features/app/content/posts/videos/screens/video_detail_screen.dart';
import 'package:thot/features/app/content/posts/podcasts/screens/podcast_detail_screen.dart';
import 'package:thot/features/app/content/posts/questions/screens/question_detail_screen.dart';

/// Wrapper intelligent qui charge le post et redirige vers le bon écran de détail
class PostDetailWrapper extends StatefulWidget {
  final String initialPostId;
  final bool isFromProfile;
  final String? userId;
  final PostType? filterType;
  final bool isFromFeed;

  const PostDetailWrapper({
    super.key,
    required this.initialPostId,
    this.isFromProfile = false,
    this.userId,
    this.filterType,
    this.isFromFeed = false,
  });

  @override
  State<PostDetailWrapper> createState() => _PostDetailWrapperState();
}

class _PostDetailWrapperState extends State<PostDetailWrapper> {
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final post = await postsStateProvider.loadPost(widget.initialPostId);

      if (post == null) {
        throw Exception('Post non trouvé');
      }

      if (mounted) {
        setState(() {
          _post = post;
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
                _error ?? 'Post non trouvé',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPost,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Rediriger vers le bon écran selon le type
    switch (_post!.type) {
      case PostType.video:
        return VideoDetailScreen(postId: widget.initialPostId);
      case PostType.podcast:
        return PodcastDetailScreen(postId: widget.initialPostId);
      case PostType.question:
        return QuestionDetailScreen(questionId: widget.initialPostId);
      default:
        return ArticleDetailScreen(postId: widget.initialPostId);
    }
  }
}
