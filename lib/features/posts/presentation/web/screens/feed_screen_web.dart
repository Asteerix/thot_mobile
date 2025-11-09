import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/navigation/route_names.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
import '../../shared/widgets/post_card.dart';
import '../../../../../shared/widgets/common/loading_indicator.dart';
import '../../../../../shared/widgets/common/error_view.dart';
import '../../../../../features/posts/domain/entities/post.dart';
import '../../../../posts/data/repositories/post_repository_impl.dart';
import '../components/web_feed_sidebar.dart';
class FeedScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const FeedScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<FeedScreenWeb> createState() => _FeedScreenWebState();
}
class _FeedScreenWebState extends State<FeedScreenWeb> {
  final PostRepositoryImpl _postRepository =
      ServiceLocator.instance.postRepository;
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  PostType? _selectedType;
  String? _selectedCategory;
  String _selectedSort = 'recent';
  PoliticalOrientation? _selectedPoliticalOrientation;
  bool _isLoading = true;
  bool _hasMorePosts = true;
  int _currentPage = 1;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadPosts();
    }
  }
  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMorePosts)) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _posts = [];
        _currentPage = 1;
        _hasMorePosts = true;
      }
    });
    try {
      final response = await _postRepository.getPosts(
        page: _currentPage,
        type: _selectedType?.name ?? 'posts',
        domain: _selectedCategory,
        sort: _selectedSort,
        politicalView: _selectedPoliticalOrientation?.name,
      );
      final postsData = response['posts'] as List<dynamic>;
      final List<Post> newPosts = [];
      for (var postJson in postsData) {
        try {
          final post = Post.fromJson(postJson as Map<String, dynamic>);
          if (post.id.isNotEmpty && !post.id.startsWith('invalid_post_id_')) {
            if (!_posts.any((p) => p.id == post.id)) {
              newPosts.add(post);
            }
          }
        } catch (e) {
          // Silently skip invalid post
        }
      }
      final total = response['total'] as int;
      if (mounted) {
        setState(() {
          if (refresh) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _hasMorePosts = _posts.length < total;
          if (_hasMorePosts) _currentPage++;
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
  void _onFilterChanged(String filter) {
    PostType? newType;
    switch (filter.toLowerCase()) {
      case 'articles':
        newType = PostType.article;
        break;
      case 'shorts':
        newType = PostType.short;
        break;
      case 'questions':
        newType = PostType.question;
        break;
      case 'podcasts':
        newType = PostType.podcast;
        break;
      default:
        newType = null;
    }
    if (_selectedType != newType) {
      setState(() => _selectedType = newType);
      _loadPosts(refresh: true);
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      showRightSidebar: context.isDesktop,
      rightSidebar: WebFeedSidebar(
        onFilterChanged: _onFilterChanged,
      ),
      body: WebMultiColumnLayout(
        content: _buildContent(context, colorScheme),
        contentMaxWidth: WebTheme.maxFeedWidth,
      ),
    );
  }
  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    if (_error != null && _posts.isEmpty) {
      return Center(
        child: ErrorView(
          error: _error!,
          onRetry: () => _loadPosts(refresh: true),
        ),
      );
    }
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: WebTheme.lg),
            Text(
              'Aucun contenu disponible',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: WebTheme.md),
            OutlinedButton.icon(
              onPressed: () => _loadPosts(refresh: true),
              icon: Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: WebTheme.lg),
        itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(WebTheme.lg),
                child: LoadingIndicator(),
              ),
            );
          }
          final post = _posts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: WebTheme.feedItemSpacing),
            child: PostCard(
              post: post,
              onTap: () {
                context.pushNamed(
                  RouteNames.postDetail,
                  pathParameters: {'postId': post.id},
                );
              },
            ),
          );
        },
      ),
    );
  }
}