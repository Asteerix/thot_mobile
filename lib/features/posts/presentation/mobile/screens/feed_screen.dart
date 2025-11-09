import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:math' as math;
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/presentation/shared/widgets/feed_filters.dart'
    as filters;
import 'package:thot/shared/widgets/common/error_view.dart';
import 'package:thot/features/authentication/presentation/mixins/auth_aware_mixin.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
import 'package:thot/features/posts/presentation/shared/widgets/feed_app_header.dart';
import 'package:thot/shared/widgets/common/filters_header_delegate.dart';
import 'package:thot/shared/widgets/common/empty_content_view.dart';
import 'package:thot/core/storage/search_history_service.dart';

enum ViewMode { feed, list }

class YouTubeSearchDelegate extends SearchDelegate<String?> {
  final PostRepositoryImpl postService;
  List<String> recentSearches;
  final List<String> suggestions;
  final ViewMode viewMode;
  final void Function(String postId)? onPostTap;
  PostType? selectedType;
  PoliticalOrientation? selectedPoliticalView;
  filters.ContentCategory? selectedCategory;
  final List<Post> _searchResultPosts = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  YouTubeSearchDelegate({
    required this.postService,
    required this.viewMode,
    this.onPostTap,
    List<String>? recentSearches,
    this.suggestions = const [],
    this.selectedType,
    this.selectedPoliticalView,
    this.selectedCategory,
  }) : recentSearches = recentSearches ?? [] {
    _scrollController.addListener(_onScroll);
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    recentSearches = await SearchHistoryService.getRecentSearches();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _currentPage++;
    try {
      String? domainString;
      if (selectedCategory != null) {
        domainString = selectedCategory!.label.toLowerCase();
      }
      final searchResult = await postService.searchPostsWithRelevance(
        query,
        page: _currentPage,
        type: selectedType?.name,
        domain: domainString,
      );
      final newResults = (searchResult['posts'] as List? ?? [])
          .map((post) => Post.fromJson(post as Map<String, dynamic>))
          .toList();
      if (newResults.isEmpty) {
        _hasMore = false;
      } else {
        _searchResultPosts.addAll(newResults);
      }
    } catch (e) {
      developer.log('Error loading more search results: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<Post>> _searchPosts() async {
    try {
      String? domainString;
      if (selectedCategory != null) {
        domainString = selectedCategory!.label.toLowerCase();
      }
      final searchResult = await postService.searchPostsWithRelevance(
        query,
        page: 1,
        type: selectedType?.name,
        domain: domainString,
      );
      return (searchResult['posts'] as List? ?? [])
          .map((post) => Post.fromJson(post as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error searching posts: $e');
      return [];
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    final isDark = base.brightness == Brightness.dark;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.54) : Colors.black54,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  String? get searchFieldLabel => 'Rechercher';
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _searchResultPosts.clear();
    _currentPage = 1;
    _hasMore = true;

    if (query.trim().isNotEmpty) {
      SearchHistoryService.addRecentSearch(query.trim());
    }
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            filters.FeedFilters(
              selectedType: selectedType,
              selectedSort: 'recent',
              selectedPoliticalView:
                  _mapToFilterPoliticalView(selectedPoliticalView),
              selectedCategory: selectedCategory,
              onTypeChanged: (type) {
                setState(() {
                  selectedType = type;
                  _searchResultPosts.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                showResults(context);
              },
              onSortChanged: (_) {},
              onPoliticalViewChanged: (view) {
                setState(() {
                  selectedPoliticalView = _mapFromFilterPoliticalView(view);
                  _searchResultPosts.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                showResults(context);
              },
              onCategoryChanged: (category) {
                setState(() {
                  selectedCategory = category;
                  _searchResultPosts.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                showResults(context);
              },
            ),
            Expanded(
              child: FutureBuilder<List<Post>>(
                future: _searchPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _searchResultPosts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError && _searchResultPosts.isEmpty) {
                    return Center(
                      child: Text(
                        'Erreur de recherche',
                        style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black54),
                      ),
                    );
                  }
                  if (snapshot.hasData) {
                    _searchResultPosts.clear();
                    _searchResultPosts.addAll(snapshot.data!);
                  }
                  if (_searchResultPosts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: isDark
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black26,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun résultat pour "$query"',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (viewMode == ViewMode.list) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount:
                          _searchResultPosts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _searchResultPosts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final post = _searchResultPosts[index];
                        return YouTubeListItem(
                          post: post,
                          onTap: () => close(context, post.id),
                        );
                      },
                    );
                  } else {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount:
                          _searchResultPosts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _searchResultPosts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final post = _searchResultPosts[index];
                        return ModernFeedCard(
                          post: post,
                          onTap: () => close(context, post.id),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
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

  @override
  Widget buildSuggestions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<String>>(
      future: query.isEmpty
          ? SearchHistoryService.getRecentSearches()
          : SearchHistoryService.getSuggestions(query),
      builder: (context, snapshot) {
        final List<String> suggestionList = snapshot.data ?? [];
        final combinedList = query.isEmpty
            ? [...suggestionList, ...suggestions]
            : suggestionList.isEmpty
                ? suggestions
                    .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                    .toList()
                : suggestionList;

        if (combinedList.isEmpty && query.isNotEmpty) {
          return Center(
            child: Text(
              'Tapez pour rechercher',
              style: TextStyle(
                  color:
                      isDark ? Colors.white.withOpacity(0.54) : Colors.black45),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: combinedList.length +
              (query.isEmpty && combinedList.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (query.isEmpty && index == 0 && combinedList.isNotEmpty) {
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color:
                      isDark ? Colors.white.withOpacity(0.54) : Colors.black54,
                  size: 20,
                ),
                title: Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await SearchHistoryService.clearRecentSearches();
                    showSuggestions(context);
                  },
                  child: Text(
                    'Effacer',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? Colors.white.withOpacity(0.7) : Colors.blue,
                    ),
                  ),
                ),
              );
            }

            final actualIndex = query.isEmpty ? index - 1 : index;
            final suggestion = combinedList[actualIndex];
            final isRecent = suggestionList.contains(suggestion);

            return ListTile(
              leading: Icon(
                isRecent ? Icons.history : Icons.search,
                color: isDark ? Colors.white.withOpacity(0.54) : Colors.black54,
                size: 20,
              ),
              title: Text(
                suggestion,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              trailing: isRecent
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark
                            ? Colors.white.withOpacity(0.38)
                            : Colors.black38,
                      ),
                      onPressed: () async {
                        await SearchHistoryService.removeRecentSearch(
                            suggestion);
                        showSuggestions(context);
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.north_west,
                        size: 18,
                        color: isDark
                            ? Colors.white.withOpacity(0.38)
                            : Colors.black38,
                      ),
                      onPressed: () {
                        query = suggestion;
                        showSuggestions(context);
                      },
                    ),
              onTap: () {
                query = suggestion;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}

class FeedScreen extends StatefulWidget {
  final String? initialQuery;
  final bool shouldRefresh;
  const FeedScreen({
    super.key,
    this.initialQuery,
    this.shouldRefresh = false,
  });
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AuthAwareMixin {
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
      developer.log(
        'Post created event received in FeedScreen parent',
        name: 'FeedScreen',
      );
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

  List<String> _getSearchSuggestions() {
    final baseSuggestions = [
      'Politique France',
      'Économie mondiale',
      'Intelligence artificielle',
      'Changement climatique',
      'Élections 2027',
      'Technologies émergentes',
      'Réforme des retraites',
      'Union européenne',
      'Géopolitique Moyen-Orient',
      'Transition énergétique',
      'Santé publique',
      'Éducation nationale',
      'Sécurité sociale',
      'Budget 2025',
      'Immigration France',
    ];

    if (_selectedCategory != null) {
      switch (_selectedCategory!.name.toLowerCase()) {
        case 'politique':
          return [
            'Élections présidentielles',
            'Assemblée nationale',
            'Réformes gouvernement',
            'Partis politiques',
            'Débat public',
          ];
        case 'economie':
          return [
            'Inflation France',
            'Croissance économique',
            'Emploi chômage',
            'Fiscalité entreprises',
            'Bourse CAC 40',
          ];
        case 'technologie':
          return [
            'Intelligence artificielle',
            'ChatGPT',
            'Cybersécurité',
            'Start-ups françaises',
            '5G déploiement',
          ];
        case 'sport':
          return [
            'Jeux Olympiques Paris',
            'Équipe de France',
            'Ligue 1',
            'Roland-Garros',
            'Tour de France',
          ];
        case 'culture':
          return [
            'Cinéma français',
            'Festivals 2025',
            'Musées expositions',
            'Littérature prix',
            'Spectacles concerts',
          ];
        case 'science':
          return [
            'Recherche médicale',
            'Espace exploration',
            'Climat études',
            'Vaccins nouveaux',
            'Archéologie découvertes',
          ];
        default:
          break;
      }
    }

    if (_selectedType != null) {
      switch (_selectedType!) {
        case PostType.video:
          return baseSuggestions.map((s) => '$s vidéo').toList();
        case PostType.podcast:
          return baseSuggestions.map((s) => '$s podcast').toList();
        case PostType.question:
          return baseSuggestions.map((s) => '$s débat').toList();
        default:
          break;
      }
    }

    return baseSuggestions;
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
        backgroundColor: isDark
            ? Colors.black
            : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      SizedBox(height: 16),
                      Text(
                        'Chargement du fil d\'actualité...',
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
        key: const ValueKey('feed'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        headerSliverBuilder: (context, inner) => [
          FeedAppHeader(
            title: 'Thot',
            showViewToggle: true,
            viewModeIcon:
                _viewMode == ViewMode.feed ? Icons.view_list : Icons.grid_view,
            onViewToggle: () {
              setState(() {
                _viewMode =
                    _viewMode == ViewMode.feed ? ViewMode.list : ViewMode.feed;
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
                  suggestions: _getSearchSuggestions(),
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
                selectedSort: 'recent',
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
        body: _FeedList(
          key: ValueKey(
              '$_selectedType $_selectedCategory $_selectedSort $_selectedPoliticalOrientation $_refreshKey $_viewMode'),
          selectedType: _selectedType,
          selectedCategory: _selectedCategory?.label.toLowerCase(),
          selectedSort: _selectedSort,
          selectedPoliticalOrientation: _selectedPoliticalOrientation,
          viewMode: _viewMode,
        ),
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  final PostType? selectedType;
  final String? selectedCategory;
  final String? selectedSort;
  final PoliticalOrientation? selectedPoliticalOrientation;
  final ViewMode viewMode;
  const _FeedList({
    super.key,
    this.selectedType,
    this.selectedCategory,
    this.selectedSort,
    this.selectedPoliticalOrientation,
    required this.viewMode,
  });
  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList>
    with AutomaticKeepAliveClientMixin {
  final _logger = LoggerService.instance;
  final _postRepository = ServiceLocator.instance.postRepository;
  final _scrollController = ScrollController();
  List<Post> _posts = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMorePosts = true;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_FeedList oldWidget) {
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
      }
    });
    try {
      final response = await _postRepository.getPosts(
        page: _currentPage,
        type: widget.selectedType?.name ?? 'posts',
        domain: widget.selectedCategory,
        sort: widget.selectedSort,
        politicalView: widget.selectedPoliticalOrientation?.name,
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
          _logger.error('Error converting post: $e');
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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
        icon: Icons.inbox,
        title: 'Aucun contenu disponible',
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

class ModernFeedCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const ModernFeedCard({super.key, required this.post, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: post.thumbnailUrl != null || post.imageUrl != null
                          ? Image.network(
                              post.thumbnailUrl ?? post.imageUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: isDark
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.24)
                                      : Colors.black26,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                post.type == PostType.video
                                    ? Icons.play_circle
                                    : post.type == PostType.podcast
                                        ? Icons.podcasts
                                        : Icons.article,
                                size: 48,
                                color: isDark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.24)
                                    : Colors.black26,
                              ),
                            ),
                    ),
                  ),
                ),
                if (post.type == PostType.video)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: post.type == PostType.video
                          ? AppColors.red.withOpacity(0.95)
                          : post.type == PostType.podcast
                              ? AppColors.purple.withOpacity(0.95)
                              : post.type == PostType.question
                                  ? AppColors.blue.withOpacity(0.95)
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.type == PostType.video
                              ? Icons.videocam
                              : post.type == PostType.podcast
                                  ? Icons.podcasts
                                  : post.type == PostType.question
                                      ? Icons.help_outline
                                      : Icons.article,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          post.type == PostType.video
                              ? 'Vidéo'
                              : post.type == PostType.podcast
                                  ? 'Podcast'
                                  : post.type == PostType.question
                                      ? 'Question'
                                      : 'Article',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPoliticalColor(context,
                              post.politicalOrientation.displayOrientation)
                          .withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPoliticalIcon(
                              post.politicalOrientation.displayOrientation),
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getPoliticalLabel(
                              post.politicalOrientation.displayOrientation),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (post.opposingPosts != null &&
                    post.opposingPosts!.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.compare_arrows,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.opposingPosts!.length} oppositions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      ),
                      child: ClipOval(
                        child: post.journalist?.avatarUrl != null
                            ? Image.network(
                                post.journalist!.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    (post.journalist?.name ?? 'A')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  (post.journalist?.name ?? 'A')[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.journalist?.name ?? 'Anonyme',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (post.journalist?.isVerified ?? false) ...[
                                    SizedBox(width: 3),
                                    const VerificationBadge(size: 11),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black38,
                              ),
                            ),
                            Text(
                              '12.5K abonnés',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.54)
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${_formatNumber(post.stats.views)} vues',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black45,
                              ),
                            ),
                            if (post.interactions.likes > 0) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark ? Colors.white60 : Colors.black38,
                                ),
                              ),
                              Text(
                                '${_formatNumber(post.interactions.likes)} j\'aime',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isDark ? Colors.white70 : Colors.black45,
                                ),
                              ),
                            ],
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black38,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getDomainColor(context,
                                        post.domain.toString().split('.').last)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getDomainLabel(
                                    post.domain.toString().split('.').last),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _getDomainColor(context,
                                      post.domain.toString().split('.').last),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black38,
                              ),
                            ),
                            Text(
                              _formatTime(post.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.black45,
                              ),
                            ),
                          ],
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
    );
  }

  Color _getPoliticalColor(
      BuildContext context, PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return Colors.blue[900]!;
      case PoliticalOrientation.conservative:
        return Colors.blue[700]!;
      case PoliticalOrientation.neutral:
        return Theme.of(context).colorScheme.outline;
      case PoliticalOrientation.progressive:
        return Colors.red[700]!;
      case PoliticalOrientation.extremelyProgressive:
        return Colors.red[900]!;
    }
  }

  IconData _getPoliticalIcon(PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return Icons.keyboard_double_arrow_left;
      case PoliticalOrientation.conservative:
        return Icons.arrow_back;
      case PoliticalOrientation.neutral:
        return Icons.remove;
      case PoliticalOrientation.progressive:
        return Icons.arrow_forward;
      case PoliticalOrientation.extremelyProgressive:
        return Icons.keyboard_double_arrow_right;
    }
  }

  String _getPoliticalLabel(PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return 'T.CONSERV';
      case PoliticalOrientation.conservative:
        return 'CONSERV';
      case PoliticalOrientation.neutral:
        return 'NEUTRE';
      case PoliticalOrientation.progressive:
        return 'PROGRESS';
      case PoliticalOrientation.extremelyProgressive:
        return 'T.PROGRESS';
    }
  }

  Color _getDomainColor(BuildContext context, String domain) {
    switch (domain.toLowerCase()) {
      case 'politique':
        return AppColors.blue;
      case 'economie':
        return AppColors.success;
      case 'societe':
        return AppColors.orange;
      case 'culture':
        return AppColors.purple;
      case 'sport':
        return AppColors.red;
      case 'technologie':
      case 'tech':
        return AppColors.blue;
      case 'sante':
        return AppColors.red;
      case 'science':
        return AppColors.success;
      case 'international':
        return AppColors.purple;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _getDomainLabel(String domain) {
    return domain.substring(0, 1).toUpperCase() +
        domain.substring(1).toLowerCase();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes}min';
    return 'à l\'instant';
  }
}

class YouTubeListItem extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const YouTubeListItem({super.key, required this.post, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 160,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: post.thumbnailUrl != null || post.imageUrl != null
                        ? Image.network(
                            post.thumbnailUrl ?? post.imageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholder(context, post, isDark),
                          )
                        : _buildPlaceholder(context, post, isDark),
                  ),
                ),
                if (post.type == PostType.video)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: post.type == PostType.video
                          ? AppColors.red.withOpacity(0.9)
                          : post.type == PostType.podcast
                              ? AppColors.purple.withOpacity(0.9)
                              : post.type == PostType.question
                                  ? AppColors.blue.withOpacity(0.9)
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.type == PostType.video
                              ? Icons.videocam
                              : post.type == PostType.podcast
                                  ? Icons.podcasts
                                  : post.type == PostType.question
                                      ? Icons.help_outline
                                      : Icons.article,
                          size: 12,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          post.type == PostType.video
                              ? 'Vidéo'
                              : post.type == PostType.podcast
                                  ? 'Podcast'
                                  : post.type == PostType.question
                                      ? 'Question'
                                      : 'Article',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getPoliticalColor(context,
                              post.politicalOrientation.displayOrientation)
                          .withOpacity(0.95),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPoliticalIcon(
                              post.politicalOrientation.displayOrientation),
                          size: 11,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          _getPoliticalLabel(
                              post.politicalOrientation.displayOrientation),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (post.opposingPosts != null &&
                    post.opposingPosts!.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.compare_arrows,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${post.opposingPosts!.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                post.journalist?.name ?? 'Anonyme',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.journalist?.isVerified ?? false) ...[
                              SizedBox(width: 3),
                              const VerificationBadge(size: 11),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        ' • 12.5K abonnés',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.54)
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${_formatNumber(post.stats.views)} vues',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black45,
                        ),
                      ),
                      if (post.interactions.likes > 0) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black38,
                          ),
                        ),
                        Text(
                          '${_formatNumber(post.interactions.likes)} j\'aime',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black45,
                          ),
                        ),
                      ],
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.black38,
                        ),
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDomainColor(
                              context, post.domain.toString().split('.').last)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getDomainLabel(post.domain.toString().split('.').last),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getDomainColor(
                            context, post.domain.toString().split('.').last),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, Post post, bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Icon(
          post.type == PostType.video
              ? Icons.play_circle
              : post.type == PostType.podcast
                  ? Icons.podcasts
                  : Icons.article,
          size: 48,
          color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26,
        ),
      ),
    );
  }

  Color _getDomainColor(BuildContext context, String domain) {
    switch (domain.toLowerCase()) {
      case 'politique':
        return AppColors.blue;
      case 'economie':
        return AppColors.success;
      case 'societe':
        return AppColors.orange;
      case 'culture':
        return AppColors.purple;
      case 'sport':
        return AppColors.red;
      case 'technologie':
      case 'tech':
        return AppColors.blue;
      case 'sante':
        return AppColors.red;
      case 'science':
        return AppColors.success;
      case 'international':
        return AppColors.purple;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _getDomainLabel(String domain) {
    return domain.substring(0, 1).toUpperCase() +
        domain.substring(1).toLowerCase();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes}min';
    return 'à l\'instant';
  }

  Color _getPoliticalColor(
      BuildContext context, PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return Colors.blue[900]!;
      case PoliticalOrientation.conservative:
        return Colors.blue[700]!;
      case PoliticalOrientation.neutral:
        return Theme.of(context).colorScheme.outline;
      case PoliticalOrientation.progressive:
        return Colors.red[700]!;
      case PoliticalOrientation.extremelyProgressive:
        return Colors.red[900]!;
    }
  }

  IconData _getPoliticalIcon(PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return Icons.keyboard_double_arrow_left;
      case PoliticalOrientation.conservative:
        return Icons.arrow_back;
      case PoliticalOrientation.neutral:
        return Icons.remove;
      case PoliticalOrientation.progressive:
        return Icons.arrow_forward;
      case PoliticalOrientation.extremelyProgressive:
        return Icons.keyboard_double_arrow_right;
    }
  }

  String _getPoliticalLabel(PoliticalOrientation orientation) {
    switch (orientation) {
      case PoliticalOrientation.extremelyConservative:
        return 'T.CONSERV';
      case PoliticalOrientation.conservative:
        return 'CONSERV';
      case PoliticalOrientation.neutral:
        return 'NEUTRE';
      case PoliticalOrientation.progressive:
        return 'PROGRESS';
      case PoliticalOrientation.extremelyProgressive:
        return 'T.PROGRESS';
    }
  }
}
