import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/domain/entities/short.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:thot/core/realtime/event_bus.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class SavedContentScreen extends StatefulWidget {
  final int? initialTabIndex;
  final bool startInSelectionMode;
  const SavedContentScreen({
    super.key,
    this.initialTabIndex,
    this.startInSelectionMode = false,
  });
  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}
class _SavedContentScreenState extends State<SavedContentScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _profileRepository = ServiceLocator.instance.profileRepository;
  late final PostRepositoryImpl _postRepository;
  late TabController _tabController;
  String _query = '';
  List<Post>? _allSavedPosts;
  List<Post>? _savedPosts;
  List<Post>? _savedQuestions;
  List<Short>? _savedShorts;
  bool _isLoadingPosts = true;
  bool _isLoadingShorts = true;
  String? _errorPosts;
  String? _errorShorts;
  final Set<String> _publicPostIds = {};
  final Set<String> _publicShortIds = {};
  final Set<String> _publicQuestionIds = {};
  bool _isSelectionMode = false;
  StreamSubscription<PostBookmarkedEvent>? _bookmarkSubscription;
  List<Post> get _filteredPosts => (_savedPosts ?? [])
      .where((p) => _matchesQuery(p.title) || _matchesQuery(p.journalist?.name))
      .toList();
  List<Short> get _filteredShorts =>
      (_savedShorts ?? []).where((s) => _matchesQuery(s.title)).toList();
  List<Post> get _filteredQuestions =>
      (_savedQuestions ?? []).where((q) => _matchesQuery(q.title)).toList();
  bool _matchesQuery(String? text) => _query.isEmpty
      ? true
      : (text ?? '').toLowerCase().contains(_query.toLowerCase());
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    WidgetsBinding.instance.addObserver(this);
    _isSelectionMode = widget.startInSelectionMode;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadSavedContent();
      }
    });
    _bookmarkSubscription =
        EventBus().on<PostBookmarkedEvent>().listen((event) {
      if (!event.isBookmarked && mounted) {
        _handleUnbookmarkedPost(event.postId);
      }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSavedContent();
    }
  }
  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }
  Future<void> _loadSavedContent() async {
    await Future.wait([_loadSavedPosts(), _loadSavedShorts()]);
    await _loadPublicContent();
  }
  Future<void> _loadSavedPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPosts = true;
      _errorPosts = null;
    });
    try {
      final result = await _profileRepository.getSavedPosts();
      final response = result.fold(
        (failure) =>
            throw Exception('Failed to load saved posts: ${failure.message}'),
        (data) => data,
      );
      if (!mounted) return;
      setState(() {
        final posts = response['posts'];
        if (posts != null && posts is List) {
          _allSavedPosts = [];
          _savedPosts = [];
          _savedQuestions = [];
          for (int i = 0; i < posts.length; i++) {
            try {
              final postData = posts[i];
              final transformedPostData =
                  _postRepository.transformPost(postData);
              final post = Post.fromJson(transformedPostData);
              _allSavedPosts!.add(post);
              if (post.type == PostType.question) {
                _savedQuestions!.add(post);
              } else {
                _savedPosts!.add(post);
              }
            } catch (parseError) {
              if (kDebugMode) {
                developer.log(
                  'Error parsing post at index $i',
                  name: 'SavedContentScreen',
                  error: parseError.toString(),
                );
              }
            }
          }
        } else {
          _allSavedPosts = [];
          _savedPosts = [];
          _savedQuestions = [];
        }
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error loading saved posts',
          name: 'SavedContentScreen',
          error: e.toString(),
        );
      }
      if (!mounted) return;
      setState(() {
        _errorPosts = e.toString();
        _isLoadingPosts = false;
      });
    }
  }
  Future<void> _loadSavedShorts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingShorts = true;
      _errorShorts = null;
    });
    try {
      final result = await _profileRepository.getSavedShorts();
      final response = result.fold(
        (failure) =>
            throw Exception('Failed to load saved shorts: ${failure.message}'),
        (data) => data,
      );
      if (!mounted) return;
      setState(() {
        final shorts = response['shorts'];
        if (shorts != null && shorts is List) {
          _savedShorts = [];
          for (int i = 0; i < shorts.length; i++) {
            try {
              final shortData = shorts[i];
              final short = Short.fromJson(shortData);
              _savedShorts!.add(short);
            } catch (parseError) {
              if (kDebugMode) {
                developer.log(
                  'Error parsing short at index $i',
                  name: 'SavedContentScreen',
                  error: parseError.toString(),
                );
              }
            }
          }
        } else {
          _savedShorts = [];
        }
        _isLoadingShorts = false;
      });
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error loading saved shorts',
          name: 'SavedContentScreen',
          error: e.toString(),
        );
      }
      if (!mounted) return;
      setState(() {
        _savedShorts = [];
        _isLoadingShorts = false;
      });
    }
  }
  Future<void> _loadPublicContent() async {
    try {
      final authRepository =
          AuthRepositoryImpl(apiService: ServiceLocator.instance.apiService);
      final profile = await authRepository.getProfile();
      if (profile.id.isNotEmpty) {
        final result = await _profileRepository.getUserPublicContent(
          profile.id,
          contentType: 'all',
        );
        final publicContent = result.fold(
          (failure) => throw Exception(
              'Failed to load public content: ${failure.message}'),
          (data) => data,
        );
        final savedPostIds = _savedPosts?.map((p) => p.id).toSet() ?? {};
        final savedShortIds = _savedShorts?.map((s) => s.id).toSet() ?? {};
        final savedQuestionIds =
            _savedQuestions?.map((q) => q.id).toSet() ?? {};
        setState(() {
          if (publicContent['posts'] != null) {
            for (final post in publicContent['posts']) {
              final id = post['_id'] ?? post['id'];
              if (id != null && savedPostIds.contains(id.toString())) {
                _publicPostIds.add(id.toString());
              }
            }
          }
          if (publicContent['shorts'] != null) {
            for (final short in publicContent['shorts']) {
              final id = short['_id'] ?? short['id'];
              if (id != null && savedShortIds.contains(id.toString())) {
                _publicShortIds.add(id.toString());
              }
            }
          }
          if (publicContent['questions'] != null) {
            for (final question in publicContent['questions']) {
              final id = question['_id'] ?? question['id'];
              if (id != null && savedQuestionIds.contains(id.toString())) {
                _publicQuestionIds.add(id.toString());
              }
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error loading public content',
          name: 'SavedContentScreen',
          error: e.toString(),
        );
      }
    }
  }
  Future<void> _savePublicSelection() async {
    try {
      final authRepository =
          AuthRepositoryImpl(apiService: ServiceLocator.instance.apiService);
      final profile = await authRepository.getProfile();
      if (profile.id.isEmpty) return;
      final result = await _profileRepository.getUserPublicContent(
        profile.id,
        contentType: 'all',
      );
      final currentPublicContent = result.fold(
        (failure) => throw Exception(
            'Failed to load public content: ${failure.message}'),
        (data) => data,
      );
      final currentPublicPostIds = <String>{};
      final currentPublicShortIds = <String>{};
      final currentPublicQuestionIds = <String>{};
      if (currentPublicContent['posts'] != null) {
        for (final post in currentPublicContent['posts']) {
          final id = post['_id'] ?? post['id'];
          if (id != null) currentPublicPostIds.add(id.toString());
        }
      }
      if (currentPublicContent['shorts'] != null) {
        for (final short in currentPublicContent['shorts']) {
          final id = short['_id'] ?? short['id'];
          if (id != null) currentPublicShortIds.add(id.toString());
        }
      }
      if (currentPublicContent['questions'] != null) {
        for (final question in currentPublicContent['questions']) {
          final id = question['_id'] ?? question['id'];
          if (id != null) currentPublicQuestionIds.add(id.toString());
        }
      }
      for (final postId in _publicPostIds) {
        if (!currentPublicPostIds.contains(postId)) {
          await _profileRepository.togglePublicContent(
            contentId: postId,
            contentType: 'posts',
            isPublic: true,
          );
        }
      }
      for (final postId in currentPublicPostIds) {
        if (!_publicPostIds.contains(postId)) {
          await _profileRepository.togglePublicContent(
            contentId: postId,
            contentType: 'posts',
            isPublic: false,
          );
        }
      }
      for (final shortId in _publicShortIds) {
        if (!currentPublicShortIds.contains(shortId)) {
          await _profileRepository.togglePublicContent(
            contentId: shortId,
            contentType: 'shorts',
            isPublic: true,
          );
        }
      }
      for (final shortId in currentPublicShortIds) {
        if (!_publicShortIds.contains(shortId)) {
          await _profileRepository.togglePublicContent(
            contentId: shortId,
            contentType: 'shorts',
            isPublic: false,
          );
        }
      }
      for (final questionId in _publicQuestionIds) {
        if (!currentPublicQuestionIds.contains(questionId)) {
          await _profileRepository.togglePublicContent(
            contentId: questionId,
            contentType: 'questions',
            isPublic: true,
          );
        }
      }
      for (final questionId in currentPublicQuestionIds) {
        if (!_publicQuestionIds.contains(questionId)) {
          await _profileRepository.togglePublicContent(
            contentId: questionId,
            contentType: 'questions',
            isPublic: false,
          );
        }
      }
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contenu public mis à jour'),
            backgroundColor: Colors.white.withOpacity(0.1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _publicPostIds.clear();
          _publicShortIds.clear();
          _publicQuestionIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  void _handleUnbookmarkedPost(String postId) async {
    try {
      if (_publicPostIds.contains(postId) ||
          _publicQuestionIds.contains(postId)) {
        await _profileRepository.togglePublicContent(
          contentId: postId,
          contentType:
              _publicQuestionIds.contains(postId) ? 'questions' : 'posts',
          isPublic: false,
        );
        setState(() {
          _publicPostIds.remove(postId);
          _publicQuestionIds.remove(postId);
          _savedPosts?.removeWhere((post) => post.id == postId);
          _savedQuestions?.removeWhere((q) => q.id == postId);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error handling unbookmarked post',
          name: 'SavedContentScreen',
          error: e.toString(),
        );
      }
    }
  }
  void _togglePostSelection(String id) => setState(() {
        _publicPostIds.contains(id)
            ? _publicPostIds.remove(id)
            : _publicPostIds.add(id);
      });
  void _toggleShortSelection(String id) => setState(() {
        _publicShortIds.contains(id)
            ? _publicShortIds.remove(id)
            : _publicShortIds.add(id);
      });
  void _toggleQuestionSelection(String id) => setState(() {
        _publicQuestionIds.contains(id)
            ? _publicQuestionIds.remove(id)
            : _publicQuestionIds.add(id);
      });
  void _openPost(Post p) {
    context.push('/post/${p.id}',
        extra: {'postId': p.id, 'isFromFeed': false});
  }
  void _openShort(Short s) =>
      context.pushNamed(RouteNames.short, extra: {'initialShortId': s.id});
  void _openQuestion(Post q) => context
      .push('/post/${q.id}', extra: {'postId': q.id, 'isFromFeed': false});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DefaultTabController(
        length: 3,
        initialIndex: widget.initialTabIndex ?? 0,
        child: NestedScrollView(
          headerSliverBuilder: (ctx, innerScrolled) => [
            SliverAppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              pinned: true,
              floating: true,
              snap: true,
              stretch: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => SafeNavigation.pop(context),
              ),
              title: Text(
                _isSelectionMode ? 'Sélection pour le profil' : 'Enregistrés',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              actions: [
                if (!_isSelectionMode)
                  IconButton(
                    icon: Icon(
                      Icons.public,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isSelectionMode = true);
                    },
                    tooltip: 'Gérer le contenu public',
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _SearchField(
                        onChanged: (q) => setState(() => _query = q.trim()),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        indicatorColor: Colors.white,
                        indicatorWeight: 2,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.5),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Shorts'),
                          Tab(text: 'Questions'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [
              _PostsTab(
                posts: _filteredPosts,
                isLoading: _isLoadingPosts,
                error: _errorPosts,
                onRefresh: _loadSavedPosts,
                isSelectionMode: _isSelectionMode,
                selectedIds: _publicPostIds,
                onToggleSelect: _togglePostSelection,
                onOpen: _openPost,
              ),
              _ShortsTab(
                shorts: _filteredShorts,
                isLoading: _isLoadingShorts,
                error: _errorShorts,
                onRefresh: _loadSavedShorts,
                isSelectionMode: _isSelectionMode,
                selectedIds: _publicShortIds,
                onToggleSelect: _toggleShortSelection,
                onOpen: _openShort,
              ),
              _QuestionsTab(
                questions: _filteredQuestions,
                isLoading: _isLoadingPosts,
                error: _errorPosts,
                onRefresh: _loadSavedPosts,
                isSelectionMode: _isSelectionMode,
                selectedIds: _publicQuestionIds,
                onToggleSelect: _toggleQuestionSelection,
                onOpen: _openQuestion,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isSelectionMode
          ? SelectionBar(
              count: _publicPostIds.length +
                  _publicShortIds.length +
                  _publicQuestionIds.length,
              onSave: _savePublicSelection,
              onCancel: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isSelectionMode = false;
                  _publicPostIds.clear();
                  _publicShortIds.clear();
                  _publicQuestionIds.clear();
                });
              },
            )
          : null,
    );
  }
}
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Rechercher',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withOpacity(0.5),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}
class _PostsTab extends StatefulWidget {
  const _PostsTab({
    required this.posts,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onOpen,
  });
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onToggleSelect;
  final void Function(Post p) onOpen;
  @override
  State<_PostsTab> createState() => _PostsTabState();
}
class _PostsTabState extends State<_PostsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isLoading) return const SkeletonGrid();
    if (widget.error != null) {
      return ErrorState(message: widget.error!, onRetry: widget.onRefresh);
    }
    if (widget.posts.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: 'Aucun post enregistré',
        subtitle: 'Enregistrez des posts pour les retrouver ici',
        action: TextButton.icon(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Actualiser', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      backgroundColor: Colors.white.withOpacity(0.1),
      color: Colors.white,
      child: AdaptiveGrid(
        itemCount: widget.posts.length,
        itemBuilder: (context, index) {
          final p = widget.posts[index];
          final selected = widget.selectedIds.contains(p.id);
          return SavedTile(
            id: p.id,
            imageUrl: p.imageUrl ?? p.videoUrl,
            typeLabel: p.type.name,
            selected: selected,
            badge: _MetaBadge(likes: p.likesCount, comments: p.commentsCount),
            onTap: () {
              if (widget.isSelectionMode) {
                HapticFeedback.selectionClick();
                widget.onToggleSelect(p.id);
              } else {
                widget.onOpen(p);
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onToggleSelect(p.id);
            },
          );
        },
      ),
    );
  }
}
class _ShortsTab extends StatefulWidget {
  const _ShortsTab({
    required this.shorts,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onOpen,
  });
  final List<Short> shorts;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onToggleSelect;
  final void Function(Short s) onOpen;
  @override
  State<_ShortsTab> createState() => _ShortsTabState();
}
class _ShortsTabState extends State<_ShortsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isLoading) return const SkeletonGrid(aspectRatio: 0.6);
    if (widget.error != null) {
      return ErrorState(message: widget.error!, onRetry: widget.onRefresh);
    }
    if (widget.shorts.isEmpty) {
      return EmptyState(
        icon: Icons.movie_outlined,
        title: 'Aucun short enregistré',
        subtitle: 'Enregistrez des shorts pour les retrouver ici',
        action: TextButton.icon(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Actualiser', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      backgroundColor: Colors.white.withOpacity(0.1),
      color: Colors.white,
      child: AdaptiveGrid(
        aspectRatio: 0.6,
        itemCount: widget.shorts.length,
        itemBuilder: (context, index) {
          final s = widget.shorts[index];
          final selected = widget.selectedIds.contains(s.id);
          return SavedTile(
            id: s.id,
            imageUrl: s.videoUrl,
            typeLabel: 'short',
            selected: selected,
            badge: _MetaBadge(likes: s.likes, comments: s.comments),
            onTap: () {
              if (widget.isSelectionMode) {
                HapticFeedback.selectionClick();
                widget.onToggleSelect(s.id);
              } else {
                widget.onOpen(s);
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onToggleSelect(s.id);
            },
          );
        },
      ),
    );
  }
}
class _QuestionsTab extends StatefulWidget {
  const _QuestionsTab({
    required this.questions,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onOpen,
  });
  final List<Post> questions;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String id) onToggleSelect;
  final void Function(Post q) onOpen;
  @override
  State<_QuestionsTab> createState() => _QuestionsTabState();
}
class _QuestionsTabState extends State<_QuestionsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.isLoading) return const SkeletonGrid();
    if (widget.error != null) {
      return ErrorState(message: widget.error!, onRetry: widget.onRefresh);
    }
    if (widget.questions.isEmpty) {
      return EmptyState(
        icon: Icons.help_outline,
        title: 'Aucune question enregistrée',
        subtitle: 'Enregistrez des questions pour les retrouver ici',
        action: TextButton.icon(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Actualiser', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      backgroundColor: Colors.white.withOpacity(0.1),
      color: Colors.white,
      child: AdaptiveGrid(
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          final selected = widget.selectedIds.contains(q.id);
          return SavedTile(
            id: q.id,
            imageUrl: q.imageUrl ?? q.videoUrl,
            typeLabel: 'question',
            selected: selected,
            badge: _MetaBadge(likes: q.likesCount, comments: q.commentsCount),
            onTap: () {
              if (widget.isSelectionMode) {
                HapticFeedback.selectionClick();
                widget.onToggleSelect(q.id);
              } else {
                widget.onOpen(q);
              }
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onToggleSelect(q.id);
            },
          );
        },
      ),
    );
  }
}
class SavedTile extends StatelessWidget {
  const SavedTile({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.typeLabel,
    required this.onTap,
    required this.onLongPress,
    required this.selected,
    this.badge,
  });
  final String id;
  final String? imageUrl;
  final String typeLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selected;
  final Widget? badge;
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'saved:$id',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _NetworkImageAdaptive(url: imageUrl),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (badge != null) Positioned(right: 8, bottom: 8, child: badge!),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.check, size: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.likes, required this.comments});
  final int likes;
  final int comments;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_border, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text('$likes', style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(width: 8),
        const Icon(Icons.mode_comment_outlined, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text('$comments', style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.onSave,
    required this.onCancel,
  });
  final int count;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Text(
              '$count sélectionné${count > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
              ),
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: count == 0 ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                disabledForegroundColor: Colors.black.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 1.0,
    this.padding = const EdgeInsets.all(8),
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double aspectRatio;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final max = width >= 600 ? 220.0 : 160.0;
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: max,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemBuilder: itemBuilder,
    );
  }
}
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.aspectRatio = 1.0, this.count = 12});
  final double aspectRatio;
  final int count;
  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      itemCount: count,
      aspectRatio: aspectRatio,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _NetworkImageAdaptive extends StatelessWidget {
  const _NetworkImageAdaptive({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final placeholderColor = Colors.white.withOpacity(0.05);
    if (url == null || url!.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        fit: BoxFit.cover,
        loadingBuilder: (c, w, p) {
          if (p == null) return w;
          return Container(
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
        errorBuilder: (c, e, s) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white.withOpacity(0.3),
              size: 32,
            ),
          );
        },
      ),
    );
  }
}