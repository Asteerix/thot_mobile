import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/presentation/shared/widgets/feed_filters.dart' as filters;
import 'package:thot/shared/widgets/common/error_view.dart';
import 'package:thot/features/authentication/presentation/mixins/auth_aware_mixin.dart';
import 'package:thot/core/utils/error_message_helper.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/features/posts/presentation/mobile/screens/feed_screen.dart';
import 'package:thot/features/posts/presentation/shared/widgets/feed_app_header.dart';
import 'package:thot/shared/widgets/common/filters_header_delegate.dart';
import 'package:thot/shared/widgets/common/empty_content_view.dart';
import 'package:thot/core/storage/search_history_service.dart';
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}
class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with AuthAwareMixin {
  PostType? _selectedType;
  String? _selectedSort = 'recent';
  PoliticalOrientation? _selectedPoliticalOrientation;
  filters.ContentCategory? _selectedCategory;
  ViewMode _viewMode = ViewMode.feed;
  bool _isLoading = true;
  String? _error;
  int _refreshKey = 0;
  late StreamSubscription<PostCreatedEvent> _postCreatedSubscription;
  late PostRepositoryImpl _postRepository;
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _loadUserData();
    _postCreatedSubscription =
        EventBus().on<PostCreatedEvent>().listen((event) {
      debugPrint('Post created event received in SubscriptionsScreen');
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
  }
  @override
  void dispose() {
    _postCreatedSubscription.cancel();
    super.dispose();
  }
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = false;
      _error = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : cs.surfaceContainerHighest,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _isLoading
              ? Center(
                  key: const ValueKey('loading'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement de vos abonnements...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : _error != null
                  ? ErrorView(
                      key: const ValueKey('error'),
                      error: _error!,
                      onRetry: _loadUserData,
                    )
                  : _buildContent(context),
        ),
      ),
    );
  }
  filters.PoliticalView _mapToFilterPoliticalView(
      PoliticalOrientation? orientation) {
    if (orientation == null) return filters.PoliticalView.all;
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return filters.PoliticalView.extremelyConservative;
      case PoliticalOrientation.conservative:
        return filters.PoliticalView.conservative;
      case PoliticalOrientation.neutral:
        return filters.PoliticalView.neutral;
      case PoliticalOrientation.progressive:
        return filters.PoliticalView.progressive;
      case PoliticalOrientation.extremelyProgressive:
        return filters.PoliticalView.extremelyProgressive;
    }
  }
  PoliticalOrientation? _mapFromFilterPoliticalView(
      filters.PoliticalView? view) {
    if (view == null || view == filters.PoliticalView.all) return null;
    switch (view) {
      case filters.PoliticalView.extremelyConservative:
        return PoliticalOrientation.extremelyConservative;
      case filters.PoliticalView.conservative:
        return PoliticalOrientation.conservative;
      case filters.PoliticalView.neutral:
        return PoliticalOrientation.neutral;
      case filters.PoliticalView.progressive:
        return PoliticalOrientation.progressive;
      case filters.PoliticalView.extremelyProgressive:
        return PoliticalOrientation.extremelyProgressive;
      default:
        return null;
    }
  }
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: NestedScrollView(
        key: const ValueKey('subscriptions'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        headerSliverBuilder: (context, inner) => [
          FeedAppHeader(
            title: 'Abonnements',
            iconData: Icons.subscriptions,
            showViewToggle: true,
            viewModeIcon: _viewMode == ViewMode.feed
                ? Icons.view_list
                : Icons.grid_view,
            onViewToggle: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.feed
                    ? ViewMode.list
                    : ViewMode.feed;
              });
            },
            onSearch: () async {
              final result = await showSearch<String?>(
                context: context,
                delegate: YouTubeSearchDelegate(
                  postService: _postRepository,
                  viewMode: _viewMode,
                  selectedType: _selectedType,
                  selectedPoliticalView: _selectedPoliticalOrientation,
                  suggestions: [
                    'Vidéos de mes journalistes',
                    'Articles récents abonnements',
                    'Débats mes abonnés',
                    'Analyses politiques',
                    'Actualités France',
                    'Économie et business',
                    'Tech et innovation',
                    'Société et culture',
                  ],
                ),
              );
              if (result != null && mounted) {
                context.pushNamed(
                  RouteNames.postDetail,
                  pathParameters: {'postId': result},
                );
              }
            },
            onNotifications: () {
              context.pushNamed(RouteNames.notifications);
            },
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: FiltersHeaderDelegate(
              minHeight: 48,
              maxHeight: 84,
              child: filters.FeedFilters(
                selectedType: _selectedType,
                selectedSort: _selectedSort ?? 'recent',
                selectedPoliticalView:
                    _mapToFilterPoliticalView(_selectedPoliticalOrientation),
                selectedCategory: _selectedCategory,
                onTypeChanged: (type) {
                  setState(() => _selectedType = type);
                },
                onSortChanged: (sort) {
                  setState(() => _selectedSort = sort);
                },
                onPoliticalViewChanged: (view) {
                  setState(() {
                    _selectedPoliticalOrientation =
                        _mapFromFilterPoliticalView(view);
                  });
                },
                onCategoryChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
            ),
          ),
        ],
        body: _SubscriptionsFeedList(
          key: ValueKey(
              '$_selectedType $_selectedCategory $_selectedSort $_selectedPoliticalOrientation $_refreshKey $_viewMode'),
          selectedType: _selectedType,
          selectedCategory: _selectedCategory?.name,
          selectedSort: _selectedSort,
          selectedPoliticalOrientation: _selectedPoliticalOrientation,
          viewMode: _viewMode,
        ),
      ),
    );
  }
}
class _SubscriptionsFeedList extends StatefulWidget {
  final PostType? selectedType;
  final String? selectedCategory;
  final String? selectedSort;
  final PoliticalOrientation? selectedPoliticalOrientation;
  final ViewMode viewMode;
  const _SubscriptionsFeedList({
    super.key,
    this.selectedType,
    this.selectedCategory,
    this.selectedSort,
    this.selectedPoliticalOrientation,
    required this.viewMode,
  });
  @override
  State<_SubscriptionsFeedList> createState() => _SubscriptionsFeedListState();
}
class _SubscriptionsFeedListState extends State<_SubscriptionsFeedList>
    with AutomaticKeepAliveClientMixin {
  final _logger = LoggerService.instance;
  final _postRepository = ServiceLocator.instance.postRepository;
  final _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMorePosts = true;
  bool _hasError = false;
  String? _errorMessage;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }
  @override
  void didUpdateWidget(_SubscriptionsFeedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedType != widget.selectedType ||
        oldWidget.selectedCategory != widget.selectedCategory ||
        oldWidget.selectedSort != widget.selectedSort ||
        oldWidget.selectedPoliticalOrientation !=
            widget.selectedPoliticalOrientation) {
      _loadPosts(refresh: true);
    }
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMorePosts)) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        _posts = [];
        _currentPage = 1;
        _hasMorePosts = true;
        _hasError = false;
        _errorMessage = null;
      }
    });
    try {
      final posts = await _postRepository.getSubscriptionsPosts(
        page: _currentPage,
        limit: 20,
      );
      List<Post> filteredPosts = posts;
      if (widget.selectedType != null) {
        filteredPosts = filteredPosts
            .where((post) => post.type == widget.selectedType)
            .toList();
      }
      if (widget.selectedCategory != null) {
        filteredPosts = filteredPosts
            .where((post) =>
                post.domain.toString().split('.').last.toLowerCase() ==
                widget.selectedCategory!.toLowerCase())
            .toList();
      }
      if (widget.selectedPoliticalOrientation != null) {
        filteredPosts = filteredPosts
            .where((post) =>
                post.politicalOrientation.displayOrientation ==
                widget.selectedPoliticalOrientation)
            .toList();
      }
      if (widget.selectedSort == 'popular') {
        filteredPosts.sort((a, b) => b.stats.views.compareTo(a.stats.views));
      } else if (widget.selectedSort == 'trending') {
        filteredPosts
            .sort((a, b) => b.stats.engagement.compareTo(a.stats.engagement));
      } else {
        filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      if (mounted) {
        setState(() {
          if (refresh) {
            _posts = filteredPosts;
          } else {
            _posts.addAll(filteredPosts);
          }
          _hasMorePosts =
              posts.length >= 20;
          if (_hasMorePosts) _currentPage++;
          _isLoading = false;
          _hasError = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = ErrorMessageHelper.getUserFriendlyMessage(e);
      });
    }
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadPosts();
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_posts.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_posts.isEmpty && !_isLoading) {
      return EmptyContentView(
        icon: Icons.subscriptions,
        title: 'Aucun contenu dans vos abonnements',
        subtitle: 'Abonnez-vous à des journalistes pour voir leurs posts ici',
        actionLabel: 'Actualiser',
        onAction: () => _loadPosts(refresh: true),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () => _loadPosts(refresh: true),
      child: _buildLayout(),
    );
  }
  Widget _buildLayout() {
    switch (widget.viewMode) {
      case ViewMode.feed:
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return ModernFeedCard(
              post: _posts[index],
              onTap: () => _navigateToPost(_posts[index]),
            );
          },
        );
      case ViewMode.list:
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return YouTubeListItem(
              post: _posts[index],
              onTap: () => _navigateToPost(_posts[index]),
            );
          },
        );
    }
  }
  void _navigateToPost(Post post) {
    if (post.id.isEmpty || post.id.startsWith('invalid_post_id_')) return;
    try {
      if (post.type == PostType.question) {
        GoRouter.of(context).push(
          RouteNames.question,
          extra: {
            'questionId': post.id,
            'isFromFeed': true,
          },
        );
      } else if (post.type == PostType.video) {
        GoRouter.of(context).push(
          RouteNames.videoDetail,
          extra: {
            'postId': post.id,
            'isFromFeed': true,
          },
        );
      } else {
        GoRouter.of(context).push(
          '/post/${post.id}',
          extra: {'postId': post.id},
        );
      }
    } catch (e) {
      _logger.error('Navigation error: $e');
    }
  }
}