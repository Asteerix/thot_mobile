import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/models/question.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/widgets/content_detail_layout.dart';
import 'package:thot/features/app/content/shared/widgets/full_article_dialog.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import 'package:thot/features/app/content/posts/questions/widgets/question_answer_dialog.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/shared/media/widgets/professional_video_player.dart';
import 'package:thot/shared/media/widgets/professional_audio_player.dart';

/// Viewer avec PageView vertical pour scroller entre les posts
/// Adapte le contenu selon la source :
/// - Depuis le feed général : tous les posts du feed
/// - Depuis les abonnements : posts des comptes suivis
/// - Depuis un profil : posts de cet utilisateur uniquement
class ContentViewer extends StatefulWidget {
  final String initialPostId;
  final PostType? filterType;
  final String? userId;
  final bool isFromProfile;

  const ContentViewer({
    super.key,
    required this.initialPostId,
    this.filterType,
    this.userId,
    this.isFromProfile = false,
  });

  @override
  State<ContentViewer> createState() => _ContentViewerState();
}

class _ContentViewerState extends State<ContentViewer> {
  final _postRepository = ServiceLocator.instance.postRepository;
  final PageController _pageController = PageController();
  List<Post> _posts = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  final Set<String> _loadedPostIds = {};

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPost();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Charger plus de posts quand on approche de la fin
    if (_currentIndex >= _posts.length - 2 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final postsStateProvider = context.read<PostsStateProvider>();
      final initialPost =
          await postsStateProvider.loadPost(widget.initialPostId);

      if (initialPost == null) {
        throw Exception('Post non trouvé');
      }

      _loadedPostIds.add(initialPost.id);

      if (mounted) {
        setState(() {
          _posts = [initialPost];
          _isLoading = false;
        });
      }

      // Charger immédiatement plus de posts
      await _loadMorePosts();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) {
      print(
          '⏸️ SKIP LOAD: isLoadingMore=$_isLoadingMore, hasMorePosts=$_hasMorePosts');
      return;
    }

    print('📥 LOADING MORE POSTS: page ${_currentPage + 1}');
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _postRepository.getPosts(
        page: _currentPage + 1,
        type: null,
        userId: widget.userId,
      );

      final postsData = response['posts'] as List<dynamic>;
      print('📦 RECEIVED ${postsData.length} posts from API');

      final newPosts = postsData
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .where((post) {
        final isValid = post.id.isNotEmpty &&
            !post.id.startsWith('invalid_post_id_') &&
            !_loadedPostIds.contains(post.id);
        if (isValid) {
          _loadedPostIds.add(post.id);
        }
        return isValid;
      }).toList();

      print('✅ FILTERED TO ${newPosts.length} new unique posts');

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _currentPage++;
          _hasMorePosts = newPosts.isNotEmpty;
          _isLoadingMore = false;
        });
        print('📊 TOTAL POSTS NOW: ${_posts.length}');
      }
    } catch (e) {
      print('❌ ERROR LOADING MORE POSTS: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
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

    if (_error != null || _posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Aucun contenu disponible',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInitialPost,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
              onPageChanged: (index) {
                print(
                    '📄 PAGE CHANGED: Index $index/${_posts.length} - Post: ${index < _posts.length ? _posts[index].title : "Loading..."}');
                if (index < _posts.length) {
                  setState(() {
                    _currentIndex = index;
                  });
                  // Charger plus de posts si on approche de la fin
                  if (index >= _posts.length - 2 &&
                      !_isLoadingMore &&
                      _hasMorePosts) {
                    _loadMorePosts();
                  }
                }
              },
              itemBuilder: (context, index) {
                print('🏗️ BUILDING PAGE $index');

                if (index == _posts.length) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final post = _posts[index];
                print('📱 Displaying post: ${post.title}');

                return _buildPostScreen(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostScreen(Post post) {
    // Récupérer les posts liés directement (déjà des Post)
    final relatedPostsList = post.relatedPosts ?? [];

    // Pour les posts opposés, on doit les charger via leur ID
    // Pour l'instant, on passe les listes vides et on les chargera plus tard
    final opposingPostsList = <Post>[];

    return SafeArea(
      child: _ContentDetailView(
        key: ValueKey(post.id),
        post: post,
        onComment: () => _showComments(post),
        onShowFullContent: () => _showFullContent(post),
        opposingPosts: opposingPostsList,
        relatedPosts: relatedPostsList,
      ),
    );
  }

  void _showComments(Post post) {
    if (post.id.isEmpty || post.id.startsWith('invalid_post_id_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'afficher les commentaires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    SafeNavigation.showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => CommentsBottomSheet(postId: post.id),
    );
  }

  void _showFullContent(Post post) {
    if (post.id.isEmpty || post.id.startsWith('invalid_post_id_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'afficher le contenu complet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (post.type == PostType.question) {
      _showQuestionDialog(post);
    } else {
      SafeNavigation.showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        enableDrag: true,
        builder: (context) => FullArticleDialog(post: post),
      );
    }
  }

  void _showQuestionDialog(Post post) async {
    try {
      final postRepository = ServiceLocator.instance.postRepository;
      final rawData = await postRepository.getPost(post.id);

      if (rawData['metadata'] == null || rawData['metadata']['question'] == null) {
        return;
      }

      final questionData = Map<String, dynamic>.from(rawData['metadata']['question']);

      // Vérifier le type de question
      final questionType = questionData['questionType'] ?? questionData['type'] ?? 'poll';
      final options = questionData['options'] ?? [];
      final hasOptions = options is List && options.isNotEmpty;
      final isDebate = (questionType == 'open' || questionType == 'openEnded') || !hasOptions;

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 Question type: $questionType');
      print('📋 Options: $options');
      print('📋 Has options: $hasOptions');
      print('📋 Is debate: $isDebate');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Si c'est un débat, ouvrir directement les commentaires
      if (isDebate) {
        print('💬 Opening comments for debate question');
        _showComments(post);
        return;
      }

      // Sinon, c'est un poll, ouvrir le dialog de vote
      final isMultipleChoice = questionData['isMultipleChoice'] ?? false;
      print('📋 Question isMultipleChoice from backend: $isMultipleChoice');

      questionData['author'] = rawData['journalist'];
      questionData['journalist'] = rawData['journalist'];
      questionData['id'] = rawData['_id'] ?? rawData['id'];
      questionData['title'] = rawData['title'];
      questionData['description'] = rawData['content'] ?? '';
      questionData['imageUrl'] = rawData['imageUrl'] ?? '';
      questionData['createdAt'] = rawData['createdAt'];
      questionData['isMultipleChoice'] = isMultipleChoice;

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

      questionData['politicalView'] = rawData['politicalOrientation']?['journalistChoice'] ?? 'neutral';

      final voters = questionData['voters'] ?? [];
      print('📋 Voters from backend: $voters');
      questionData['votes'] = voters;

      if (questionData['options'] is List) {
        final options = questionData['options'] as List;
        for (var i = 0; i < options.length; i++) {
          if (options[i] is Map && options[i]['id'] == null) {
            options[i]['id'] = options[i]['_id'] ?? i.toString();
          }
        }
      }

      final question = Question.fromJson(questionData);
      print('📋 Question votes count: ${question.votes.length}');
      print('📋 User voted options: ${question.getUserVotedOptions()}');

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => QuestionAnswerDialog(
          post: post,
          question: question,
        ),
      );
    } catch (e) {
      print('❌ Error showing question dialog: $e');
    }
  }
}

/// Vue de détail d'un post individuel dans le feed
class _ContentDetailView extends StatefulWidget {
  final Post post;
  final VoidCallback onComment;
  final VoidCallback onShowFullContent;
  final List<Post> opposingPosts;
  final List<Post> relatedPosts;

  const _ContentDetailView({
    super.key,
    required this.post,
    required this.onComment,
    required this.onShowFullContent,
    required this.opposingPosts,
    required this.relatedPosts,
  });

  @override
  State<_ContentDetailView> createState() => _ContentDetailViewState();
}

class _ContentDetailViewState extends State<_ContentDetailView> {
  final _postRepository = ServiceLocator.instance.postRepository;
  List<Post> _loadedOpposingPosts = [];
  bool _isLoadingOpposing = false;

  @override
  void initState() {
    super.initState();
    _loadOpposingPosts();
  }

  Future<void> _loadOpposingPosts() async {
    final hasOpposing = widget.post.opposingPosts != null && widget.post.opposingPosts!.isNotEmpty;
    final hasOpposedBy = widget.post.opposedByPosts != null && widget.post.opposedByPosts!.isNotEmpty;

    if (!hasOpposing && !hasOpposedBy) {
      return;
    }

    setState(() {
      _isLoadingOpposing = true;
    });

    try {
      final loadedPosts = <Post>[];

      if (hasOpposing) {
        for (final opposition in widget.post.opposingPosts!) {
          try {
            final response = await _postRepository.getPost(opposition.postId);
            final post = Post.fromJson(response);
            loadedPosts.add(post);
          } catch (e) {
            print('Error loading opposing post ${opposition.postId}: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _loadedOpposingPosts = loadedPosts;
          _isLoadingOpposing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOpposing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDetailLayout(
      post: widget.post,
      previewWidget: _buildPreview(),
      actionButtonText: _getActionButtonText(),
      onActionPressed: widget.onShowFullContent,
      onComment: widget.onComment,
      opposingPosts: _loadedOpposingPosts.isEmpty ? null : _loadedOpposingPosts,
      relatedPosts: widget.relatedPosts.isEmpty ? null : widget.relatedPosts,
      additionalContent:
          widget.post.type == PostType.question ? _buildQuestionVoting() : null,
    );
  }

  Widget _buildPreview() {
    final post = widget.post;
    final screenWidth = MediaQuery.of(context).size.width;

    if (post.type == PostType.video && post.videoUrl != null) {
      return SizedBox(
        width: screenWidth,
        height: screenWidth * 9 / 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProfessionalVideoPlayer(
              videoUrl: post.videoUrl!,
              thumbnailUrl: post.thumbnailUrl ?? post.imageUrl,
              autoPlay: true,
              looping: true,
              showControls: true,
            ),
          ),
        ),
      );
    }

    if (post.type == PostType.podcast) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ProfessionalVideoPlayer(
          videoUrl: post.videoUrl ?? '',
          thumbnailUrl: post.imageUrl,
          autoPlay: false,
          showControls: true,
        ),
      );
    }

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
              if (post.imageUrl != null || post.thumbnailUrl != null)
                Image.network(
                  post.thumbnailUrl ?? post.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    IconData icon = Icons.article;
    if (widget.post.type == PostType.video) icon = Icons.videocam;
    if (widget.post.type == PostType.podcast) icon = Icons.podcasts;
    if (widget.post.type == PostType.question) icon = Icons.help_outline;

    return Center(
      child: Icon(icon, color: Colors.white54, size: 64),
    );
  }

  String _getActionButtonText() {
    if (widget.post.type == PostType.question) {
      final questionMetadata = widget.post.metadata?.question;
      if (questionMetadata != null) {
        final questionType = questionMetadata.questionType;
        final hasOptions = questionMetadata.options?.isNotEmpty ?? false;
        final isDebate = questionType == 'openEnded' || !hasOptions;
        return isDebate ? "Débattez en commentaire" : "Répondre à la question";
      }
      return "Répondre à la question";
    }
    if (widget.post.type == PostType.video) return "Lire la description complète";
    if (widget.post.type == PostType.podcast) return "Lire la description complète";
    return "Lire l'article complet";
  }

  String _getQuestionButtonText(Post post) {
    // Cette méthode sera appelée après avoir chargé les données de la question
    // Pour déterminer le bon texte du bouton
    return "Répondre à la question";  // Par défaut
  }

  Widget? _buildQuestionVoting() {
    if (widget.post.type != PostType.question) return null;
    return const SizedBox.shrink();
  }
}
