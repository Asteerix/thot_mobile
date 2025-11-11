import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/core/utils/debouncer.dart';
import 'package:thot/features/posts/application/providers/posts_state_provider.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/article_post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/video_post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/podcast_post.dart';
import 'package:thot/features/posts/presentation/shared/widgets/question_card_with_voting.dart';
import 'package:thot/features/posts/presentation/shared/widgets/post_header.dart';
import 'package:thot/features/posts/presentation/shared/widgets/post_actions.dart';
import 'package:thot/features/comments/presentation/shared/widgets/comment_sheet.dart';
import 'package:thot/features/posts/presentation/shared/widgets/full_article_dialog.dart';
import 'package:thot/shared/widgets/common/connection_status_indicator.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class PostDetailScreen extends StatefulWidget {
  final String initialPostId;
  final bool isFromProfile;
  final String? userId;
  final PostType? filterType;
  final bool isFromFeed;
  const PostDetailScreen({
    super.key,
    required this.initialPostId,
    this.isFromProfile = false,
    this.userId,
    this.filterType,
    this.isFromFeed = false,
  });
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}
class _PostDetailScreenState extends State<PostDetailScreen>
    with SingleTickerProviderStateMixin {
  final _postRepository = ServiceLocator.instance.postRepository;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  final _actionDebouncer = ActionDebouncer(defaultDelay: 500);
  List<Post> _posts = [];
  final Map<String, Map<String, dynamic>> _rawPostData = {};
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePosts = true;
  bool _isVideoPlaying = false;
  int? _totalPosts;
  @override
  void initState() {
    super.initState();
    debugPrint('🎬 POST_DETAIL_SCREEN - initState | postId: ${widget.initialPostId} | isFromFeed: ${widget.isFromFeed}');
    developer.log(
      '🎬 POST DETAIL SCREEN - Init State',
      name: 'PostDetailScreen_INIT',
      error: {
        'initialPostId': widget.initialPostId,
        'isFromProfile': widget.isFromProfile,
        'userId': widget.userId,
        'filterType': widget.filterType?.toString(),
        'isFromFeed': widget.isFromFeed,
      },
    );
    _pageController.addListener(_onScroll);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPost();
    });
  }
  Future<void> _loadInitialPost() async {
    if (!mounted) return;
    debugPrint('🚀 POST_DETAIL_SCREEN - _loadInitialPost | postId: ${widget.initialPostId}');
    developer.log(
      '🚀 LOAD INITIAL POST - Starting',
      name: 'PostDetailScreen_LOAD',
      error: {
        'initialPostId': widget.initialPostId,
        'postId_length': widget.initialPostId.length,
        'postId_isEmpty': widget.initialPostId.isEmpty,
        'postId_invalid': widget.initialPostId.startsWith('invalid_post_id_'),
        'isFromProfile': widget.isFromProfile,
        'userId': widget.userId,
        'filterType': widget.filterType?.toString(),
        'isFromFeed': widget.isFromFeed,
      },
    );
    if (widget.initialPostId.isEmpty ||
        widget.initialPostId.startsWith('invalid_post_id_')) {
      developer.log(
        '❌ LOAD INITIAL POST - Invalid post ID',
        name: 'PostDetailScreen_ERROR',
        error: {
          'postId': widget.initialPostId,
          'reason':
              widget.initialPostId.isEmpty ? 'Empty ID' : 'Invalid ID pattern',
        },
      );
      setState(() {
        _error = 'ID du post invalide';
        _isInitialLoading = false;
      });
      return;
    }
    setState(() {
      _isInitialLoading = true;
      _error = null;
    });
    try {
      developer.log(
        '📡 LOAD INITIAL POST - Calling API',
        name: 'PostDetailScreen_API',
        error: {'postId': widget.initialPostId},
      );
      final postsStateProvider = context.read<PostsStateProvider>();
      final initialPost =
          await postsStateProvider.loadPost(widget.initialPostId);
      final rawResponse = await _postRepository.getPost(widget.initialPostId);
      _rawPostData[widget.initialPostId] = rawResponse;
      if (initialPost == null) {
        throw Exception('Post not found');
      }
      developer.log(
        '✅ LOAD INITIAL POST - Success',
        name: 'PostDetailScreen_SUCCESS',
        error: {
          'postId': initialPost.id,
          'postTitle': initialPost.title,
          'postType': initialPost.type.toString(),
          'hasValidId': initialPost.id.isNotEmpty &&
              !initialPost.id.startsWith('invalid_post_id_'),
        },
      );
      if (!mounted) return;
      setState(() {
        _posts = [initialPost];
        _currentPage = 1;
        _isInitialLoading = false;
      });
      if (widget.isFromProfile &&
          widget.userId != null &&
          widget.userId!.isNotEmpty) {
        _loadAllPostsAndJumpToInitial();
      } else {
        _loadMorePosts();
      }
    } catch (e) {
      developer.log(
        '❌ LOAD INITIAL POST - API Error',
        name: 'PostDetailScreen_API_ERROR',
        error: {
          'error': e.toString(),
          'postId': widget.initialPostId,
        },
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitialLoading = false;
      });
    }
  }
  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMorePosts || _error != null || _posts.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      String? validUserId;
      if (widget.isFromProfile &&
          widget.userId != null &&
          widget.userId != 'undefined' &&
          widget.userId != 'null') {
        validUserId = widget.userId;
        developer.log(
          '📋 Loading MORE posts from profile user',
          name: 'PostDetailScreen_LOAD_MORE',
          error: {
            'userId': validUserId,
            'source': 'profile',
            'isFromProfile': widget.isFromProfile
          },
        );
      }
      else if (!widget.isFromProfile &&
          _posts.isNotEmpty &&
          _posts.first.journalist != null) {
        validUserId = _posts.first.journalist!.id;
        developer.log(
          '📋 Loading posts from same journalist only',
          name: 'PostDetailScreen_LOAD_MORE',
          error: {'journalistId': validUserId, 'source': 'post_journalist'},
        );
      }
      if (validUserId == null) {
        developer.log(
          '📋 Loading all posts (no specific user filter)',
          name: 'PostDetailScreen_LOAD_MORE',
          error: {'source': 'all_posts'},
        );
      }
      final response = await _postRepository.getPosts(
        page: _currentPage,
        userId: validUserId,
        type: widget.filterType?.name,
      );
      if (!mounted) return;
      var postsData = (response['posts'] as List);
      var newPosts = <Post>[];
      for (var postJson in postsData) {
        var post = Post.fromJson(postJson);
        if (!_posts.any((p) => p.id == post.id)) {
          newPosts.add(post);
          _rawPostData[post.id] = postJson;
        }
      }
      int total = response['total'] as int? ?? 0;
      setState(() {
        if (newPosts.isNotEmpty) {
          _posts.addAll(newPosts);
          _currentPage++;
        }
        _totalPosts = total;
        _hasMorePosts = _posts.length < total;
        _isLoading = false;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMorePosts = false;
        _error = e.toString();
        _isInitialLoading = false;
      });
    }
  }
  void _onScroll() {
    if (_pageController.position.pixels >=
        _pageController.position.maxScrollExtent - 500) {
      _loadMorePosts();
    }
  }
  Future<void> _loadAllPostsAndJumpToInitial() async {
    if (_isLoading || widget.userId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      developer.log(
        '📋 Loading posts from user profile to find initial post',
        name: 'PostDetailScreen_LOAD_ALL',
        error: {
          'userId': widget.userId,
          'initialPostId': widget.initialPostId,
          'filterType': widget.filterType?.name
        },
      );
      List<Post> allPosts = [];
      int page = 1;
      bool hasMore = true;
      int initialIndex = -1;
      int totalCount = 0;
      while (hasMore && initialIndex == -1) {
        final response = await _postRepository.getPosts(
          page: page,
          userId: widget.userId,
          type: widget.filterType?.name,
        );
        var postsData = (response['posts'] as List);
        var newPosts = <Post>[];
        for (var postJson in postsData) {
          var post = Post.fromJson(postJson);
          newPosts.add(post);
          _rawPostData[post.id] = postJson;
        }
        totalCount = response['total'] as int? ?? 0;
        if (newPosts.isEmpty) {
          hasMore = false;
        } else {
          allPosts.addAll(newPosts);
          initialIndex =
              allPosts.indexWhere((post) => post.id == widget.initialPostId);
          page++;
        }
        if (allPosts.length > 100 && initialIndex == -1) {
          developer.log(
            '⚠️ Initial post not found in first 100 posts, continuing search',
            name: 'PostDetailScreen_LOAD_ALL',
            error: {'postsLoaded': allPosts.length},
          );
        }
        if (allPosts.length > 500) break;
      }
      if (!mounted) return;
      final foundIndex =
          allPosts.indexWhere((post) => post.id == widget.initialPostId);
      if (foundIndex == -1) {
        developer.log(
          '⚠️ Initial post not found in user posts',
          name: 'PostDetailScreen_LOAD_ALL',
          error: {
            'postId': widget.initialPostId,
            'totalPosts': allPosts.length
          },
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _posts = allPosts;
        _totalPosts = totalCount > 0 ? totalCount : allPosts.length;
        _hasMorePosts = allPosts.length < totalCount;
        _isLoading = false;
        _currentPage = page;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients && foundIndex >= 0) {
          _pageController.jumpToPage(foundIndex);
        }
      });
      developer.log(
        '✅ Loaded all posts and jumping to index',
        name: 'PostDetailScreen_LOAD_ALL',
        error: {'totalPosts': allPosts.length, 'initialIndex': foundIndex},
      );
    } catch (e) {
      developer.log(
        '❌ Error loading all posts',
        name: 'PostDetailScreen_LOAD_ALL_ERROR',
        error: e,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _handleLike(Post post) async {
    developer.log(
      '❤️ HANDLE LIKE - Starting',
      name: 'PostDetailScreen_LIKE',
      error: {
        'postId': post.id,
        'postTitle': post.title,
        'currentIsLiked': post.isLiked,
        'currentLikesCount': post.likesCount,
        'hasValidId': !post.id.startsWith('invalid_post_id_'),
      },
    );
    if (post.id.startsWith('invalid_post_id_')) {
      developer.log(
        '❌ HANDLE LIKE - Invalid ID',
        name: 'PostDetailScreen_LIKE_ERROR',
        error: {
          'postId': post.id,
          'reason': 'Invalid post ID pattern',
        },
      );
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: const Text('Impossible d\'interagir avec ce post'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    final debounceKey = 'like_${post.id}';
    if (_actionDebouncer.isDebouncing(debounceKey)) {
      developer.log(
        '⏱️ HANDLE LIKE - Already debouncing',
        name: 'PostDetailScreen_LIKE',
        error: {'postId': post.id},
      );
      return;
    }
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;
    final originalPost = _posts[index];
    final wasLiked = originalPost.isLiked;
    final originalLikesCount = originalPost.likesCount;
    final optimisticPost = originalPost.copyWith(
      interactions: originalPost.interactions.copyWith(
        isLiked: !wasLiked,
        likes: wasLiked ? originalLikesCount - 1 : originalLikesCount + 1,
      ),
    );
    setState(() {
      _posts[index] = optimisticPost;
    });
    HapticFeedback.mediumImpact();
    _actionDebouncer.debounce(debounceKey, () async {
      try {
        developer.log(
          '📡 HANDLE LIKE - Using PostsStateProvider',
          name: 'PostDetailScreen_LIKE_API',
          error: {'postId': post.id, 'action': wasLiked ? 'unlike' : 'like'},
        );
        final postsStateProvider = context.read<PostsStateProvider>();
        await postsStateProvider.toggleLike(post.id);
        final updatedPost = postsStateProvider.getPost(post.id);
        if (updatedPost == null) {
          throw Exception('Failed to get updated post');
        }
        developer.log(
          '✅ HANDLE LIKE - Success',
          name: 'PostDetailScreen_LIKE_SUCCESS',
          error: {
            'postId': updatedPost.id,
            'newIsLiked': updatedPost.isLiked,
            'newLikesCount': updatedPost.likesCount,
            'oldIsLiked': wasLiked,
            'oldLikesCount': originalLikesCount,
          },
        );
        if (mounted && _posts[index].id == post.id) {
          setState(() {
            _posts[index] = updatedPost;
          });
          EventBus().fire(PostLikedEvent(
            postId: updatedPost.id,
            isLiked: updatedPost.isLiked,
            likeCount: updatedPost.likesCount,
          ));
        }
      } catch (e, stackTrace) {
        developer.log(
          '❌ HANDLE LIKE - Error',
          name: 'PostDetailScreen_LIKE_ERROR',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted && _posts[index].id == post.id) {
          setState(() {
            _posts[index] = originalPost;
          });
        }
        if (mounted) {
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    });
  }
  Future<void> _handleSave(Post post) async {
    developer.log(
      '🔖 HANDLE SAVE - Starting',
      name: 'PostDetailScreen_SAVE',
      error: {
        'postId': post.id,
        'postTitle': post.title,
        'currentIsSaved': post.isSaved,
        'hasValidId': !post.id.startsWith('invalid_post_id_'),
      },
    );
    if (post.id.startsWith('invalid_post_id_')) {
      developer.log(
        '❌ HANDLE SAVE - Invalid ID',
        name: 'PostDetailScreen_SAVE_ERROR',
        error: {
          'postId': post.id,
          'reason': 'Invalid post ID pattern',
        },
      );
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: const Text('Impossible de sauvegarder ce post'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    final debounceKey = 'save_${post.id}';
    if (_actionDebouncer.isDebouncing(debounceKey)) {
      developer.log(
        '⏱️ HANDLE SAVE - Already debouncing',
        name: 'PostDetailScreen_SAVE',
        error: {'postId': post.id},
      );
      return;
    }
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;
    final originalPost = _posts[index];
    final wasSaved = originalPost.isSaved;
    final optimisticPost = originalPost.copyWith(
      interactions: originalPost.interactions.copyWith(
        isSaved: !wasSaved,
      ),
    );
    setState(() {
      _posts[index] = optimisticPost;
    });
    HapticFeedback.lightImpact();
    if (mounted) {
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text(wasSaved ? 'Retiré des favoris' : 'Ajouté aux favoris'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    _actionDebouncer.debounce(debounceKey, () async {
      try {
        developer.log(
          '📡 HANDLE SAVE - Using PostsStateProvider',
          name: 'PostDetailScreen_SAVE_API',
          error: {'postId': post.id, 'action': wasSaved ? 'unsave' : 'save'},
        );
        final postsStateProvider = context.read<PostsStateProvider>();
        await postsStateProvider.toggleBookmark(post.id);
        final updatedPost = postsStateProvider.getPost(post.id);
        if (updatedPost == null) {
          throw Exception('Failed to get updated post');
        }
        developer.log(
          '✅ HANDLE SAVE - Success',
          name: 'PostDetailScreen_SAVE_SUCCESS',
          error: {
            'postId': updatedPost.id,
            'newIsSaved': updatedPost.isSaved,
            'oldIsSaved': wasSaved,
          },
        );
        EventBus().fire(PostBookmarkedEvent(
          postId: updatedPost.id,
          isBookmarked: updatedPost.isSaved,
          bookmarkCount: updatedPost.interactions.bookmarks,
        ));
      } catch (e, stackTrace) {
        developer.log(
          '❌ HANDLE SAVE - Error',
          name: 'PostDetailScreen_SAVE_ERROR',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted && _posts[index].id == post.id) {
          setState(() {
            _posts[index] = originalPost;
          });
        }
        if (mounted) {
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    });
  }
  void _showCommentsSheet(String postId) {
    developer.log(
      '💬 SHOW COMMENTS - Opening sheet',
      name: 'PostDetailScreen_COMMENTS',
      error: {
        'postId': postId,
        'hasValidId': !postId.startsWith('invalid_post_id_'),
      },
    );
    if (postId.startsWith('invalid_post_id_')) {
      developer.log(
        '❌ SHOW COMMENTS - Invalid ID',
        name: 'PostDetailScreen_COMMENTS_ERROR',
        error: {
          'postId': postId,
          'reason': 'Invalid post ID pattern',
        },
      );
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: const Text('Impossible d\'afficher les commentaires'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    SafeNavigation.showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => CommentsBottomSheet(postId: postId),
    );
  }
  void _showFullArticle(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => FullArticleDialog(post: post),
    );
  }
  Widget _buildPostContent(Post post) {
    switch (post.type) {
      case PostType.article:
        return ArticlePost(
          post: post,
          onReadMore: () => _showFullArticle(post),
        );
      case PostType.video:
        return VideoPost(
          post: post,
          isVideoPlaying: _isVideoPlaying,
          onVideoPlayingChanged: (value) =>
              setState(() => _isVideoPlaying = value),
        );
      case PostType.podcast:
        return PodcastPost(post: post);
      case PostType.question:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: QuestionCardWithVoting(
            questionPost: post,
            rawQuestionData: _rawPostData[post.id] ?? {},
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
  Widget _buildPost(Post post) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostHeader(
                    post: post,
                    onBack: () {
                      if (GoRouter.of(context).canPop()) {
                        SafeNavigation.pop(context);
                      } else {
                        GoRouter.of(context).go('/feed');
                      }
                    },
                    isVideoPost: post.type == PostType.video,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Hero(
                          tag: 'post-${post.id}',
                          child: _buildPostContent(post),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
                  child: PostActions(
                    post: post,
                    onLike: () => _handleLike(post),
                    onComment: () => _showCommentsSheet(post.id),
                    onSave: () => _handleSave(post),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Impossible de charger le post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Ce post n\'existe plus ou a été supprimé',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Retour au feed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.6)),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const ConnectionStatusIndicator(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _posts.length && _hasMorePosts) {
                  return SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          if (_totalPosts != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_posts.length} / $_totalPosts',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return _buildPost(_posts[index]);
              },
              onPageChanged: (index) {
                setState(() {
                  _isVideoPlaying = false;
                });
                HapticFeedback.lightImpact();
                if (index > 0 && index == _posts.length - 1) {
                  _loadMorePosts();
                }
                _animationController.forward(from: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _animationController.dispose();
    _actionDebouncer.dispose();
    super.dispose();
  }
}