import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/features/app/content/shared/widgets/content_detail_layout.dart';
import 'package:thot/core/di/service_locator.dart';

/// Viewer avec PageView vertical pour scroller entre les posts
/// Similaire au système des shorts mais pour tous les types de contenu
class ContentFeedViewer extends StatefulWidget {
  final String initialPostId;
  final PostType? filterType;
  final String? userId;
  final bool isFromProfile;

  const ContentFeedViewer({
    super.key,
    required this.initialPostId,
    this.filterType,
    this.userId,
    this.isFromProfile = false,
  });

  @override
  State<ContentFeedViewer> createState() => _ContentFeedViewerState();
}

class _ContentFeedViewerState extends State<ContentFeedViewer> {
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
    if (_currentIndex >= _posts.length - 2 && !_isLoadingMore && _hasMorePosts) {
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
      print('⏸️ SKIP LOAD: isLoadingMore=$_isLoadingMore, hasMorePosts=$_hasMorePosts');
      return;
    }

    print('📥 LOADING MORE POSTS: page ${_currentPage + 1}');
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _postRepository.getPosts(
        page: _currentPage + 1,
        type: widget.filterType?.name,
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
          })
          .toList();

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
                  if (index >= _posts.length - 2 && !_isLoadingMore && _hasMorePosts) {
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
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DEBUG: Page ${_currentIndex + 1}/${_posts.length} (Total loaded: ${_posts.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Loading: $_isLoadingMore | HasMore: $_hasMorePosts | Current Page: $_currentPage',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Swipe UP/DOWN to navigate',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostScreen(Post post) {
    return SafeArea(
      child: _ContentDetailView(
        key: ValueKey(post.id),
        post: post,
        onComment: () => _showComments(post),
        opposingPosts: [],
        relatedPosts: [],
      ),
    );
  }

  void _showComments(Post post) {
    // Navigation vers commentaires
  }
}

/// Vue de détail d'un post individuel dans le feed
class _ContentDetailView extends StatelessWidget {
  final Post post;
  final VoidCallback onComment;
  final List<Post> opposingPosts;
  final List<Post> relatedPosts;

  const _ContentDetailView({
    super.key,
    required this.post,
    required this.onComment,
    required this.opposingPosts,
    required this.relatedPosts,
  });

  @override
  Widget build(BuildContext context) {
    return ContentDetailLayout(
      post: post,
      previewWidget: _buildPreview(),
      actionButtonText: _getActionButtonText(),
      onActionPressed: () => _showFullContent(context),
      onComment: onComment,
      opposingPosts: opposingPosts.isEmpty ? null : opposingPosts,
      relatedPosts: relatedPosts.isEmpty ? null : relatedPosts,
      additionalContent:
          post.type == PostType.question ? _buildQuestionVoting() : null,
    );
  }

  Widget _buildPreview() {
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
              _buildTypeOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    IconData icon = Icons.article;
    if (post.type == PostType.video) icon = Icons.videocam;
    if (post.type == PostType.podcast) icon = Icons.podcasts;
    if (post.type == PostType.question) icon = Icons.help_outline;

    return Center(
      child: Icon(icon, color: Colors.white54, size: 64),
    );
  }

  Widget _buildTypeOverlay() {
    Color color = Colors.grey;
    IconData icon = Icons.article;
    String label = 'Article';

    if (post.type == PostType.video) {
      color = Colors.red;
      icon = Icons.videocam;
      label = 'Vidéo';
    } else if (post.type == PostType.podcast) {
      color = Colors.purple;
      icon = Icons.podcasts;
      label = 'Podcast';
    } else if (post.type == PostType.question) {
      color = Colors.blue;
      icon = Icons.help_outline;
      label = 'Question';
    }

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionButtonText() {
    if (post.type == PostType.question) return "Répondre à la question";
    if (post.type == PostType.video) return "Lire la description complète";
    if (post.type == PostType.podcast) return "Lire la description complète";
    return "Lire l'article complet";
  }

  void _showFullContent(BuildContext context) {
    // TODO: Ouvrir la modale appropriée selon le type
  }

  Widget? _buildQuestionVoting() {
    if (post.type != PostType.question) return null;
    // TODO: Ajouter le widget de vote
    return null;
  }
}
