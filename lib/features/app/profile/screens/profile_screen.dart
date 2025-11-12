import 'package:thot/core/presentation/theme/app_colors.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/app/content/shared/widgets/new_publication_screen.dart';
import 'package:thot/features/app/content/shorts/creation/new_short_screen.dart';
import 'package:thot/features/app/content/posts/questions/creation/new_question_screen.dart';
import 'package:thot/features/app/feed/shared/saved_content_screen.dart';
import 'package:thot/shared/widgets/layouts/app_header.dart';
import 'package:thot/shared/widgets/connectivity/connection_status_indicator.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/public/auth/shared/providers/auth_repository_impl.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/services/realtime/event_bus.dart';
import 'package:thot/features/app/profile/utils/follow_utils.dart';
import 'package:thot/core/services/storage/token_service.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/core/config/api_routes.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/features/app/content/shared/models/question.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/profile/widgets/profile_header.dart';
import 'package:thot/features/app/content/posts/questions/widgets/question_cards.dart';
import 'package:thot/features/app/content/posts/questions/widgets/question_card_with_voting.dart';
import 'package:thot/shared/media/utils/image_utils.dart';
import 'package:thot/shared/widgets/loading/loading_indicator.dart';
import 'package:thot/shared/widgets/errors/error_view.dart';
import 'package:thot/shared/widgets/empty/empty_state.dart' as common_widgets;
import 'package:thot/features/public/auth/shared/mixins/auth_aware_mixin.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/app/content/shared/providers/posts_state_provider.dart';
import 'package:thot/core/services/logging/logger_service.dart';

class TabItemData {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  TabItemData({
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;
  final bool forceReload;
  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = false,
    this.forceReload = false,
  });
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin, AuthAwareMixin {
  final _logger = LoggerService.instance;
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<TabItemData> _tabItems = [];
  late final _profileRepository = ServiceLocator.instance.profileRepository;
  late final _postRepository = ServiceLocator.instance.postRepository;
  UserProfile? _userProfile;
  List<Post>? _posts;
  List<dynamic>? _shorts;
  List<Map<String, dynamic>>? _questions;
  final Map<String, Post> _questionPosts = {};
  final Map<String, Map<String, dynamic>> _questionsRawData = {};
  bool _isLoading = true;
  String? _error;
  bool _isProcessingFollow = false;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<PostCreatedEvent>? _postCreatedSubscription;
  StreamSubscription<PostUpdatedEvent>? _postUpdatedSubscription;
  StreamSubscription<PostDeletedEvent>? _postDeletedSubscription;
  StreamSubscription<PostBookmarkedEvent>? _postBookmarkedSubscription;
  bool _hasLoaded = false;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupScrollListener();
    _setupEventListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded && widget.forceReload) {
      _logger.info('Force reload requested');
      _loadProfile();
    }
    _hasLoaded = true;
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) {
            _fadeController.forward();
          }
        });
      }
    });
  }

  void _setupEventListeners() {
    _postCreatedSubscription =
        EventBus().on<PostCreatedEvent>().listen((event) {
      if (!mounted) return;
      if (widget.isCurrentUser ||
          (event.journalistId != null && event.journalistId == widget.userId)) {
        _logger.info('ProfileScreen received PostCreatedEvent');
        if (event.postType == PostType.question) {
          _logger.info('Calling _loadQuestions() from ProfileScreen');
          _loadQuestions();
        } else if (event.postType == PostType.short) {
          _logger.info('Calling _loadShorts() from ProfileScreen');
          _loadShorts();
        } else {
          _logger.info('Calling _loadPosts() from ProfileScreen');
          _loadPosts();
        }
      }
    });
    EventBus().on<PostBookmarkedEvent>().listen((event) {
      if (!mounted) return;
      if (_posts != null) {
        final postIndex = _posts!.indexWhere((post) => post.id == event.postId);
        if (postIndex != -1) {
          setState(() {
            _posts![postIndex] = _posts![postIndex].copyWith(
              interactions: _posts![postIndex].interactions.copyWith(
                    isSaved: event.isBookmarked,
                    bookmarks: event.isBookmarked
                        ? _posts![postIndex].interactions.bookmarks + 1
                        : _posts![postIndex].interactions.bookmarks - 1,
                  ),
            );
          });
        }
      }
    });
    _postUpdatedSubscription =
        EventBus().on<PostUpdatedEvent>().listen((event) {
      if (!mounted) return;
    });
    _postDeletedSubscription =
        EventBus().on<PostDeletedEvent>().listen((event) {
      if (!mounted) return;
      if (_posts != null) {
        setState(() {
          _posts!.removeWhere((post) => post.id == event.postId);
        });
      }
    });
    _postBookmarkedSubscription =
        EventBus().on<PostBookmarkedEvent>().listen((event) {
      if (!mounted) return;
      if (_posts != null) {
        setState(() {
          final index = _posts!.indexWhere((post) => post.id == event.postId);
          if (index != -1) {
            _posts![index] = _posts![index].copyWith(
              interactions: _posts![index].interactions.copyWith(
                    isSaved: event.isBookmarked,
                  ),
            );
          }
        });
      }
      if (!(_userProfile?.isJournalist ?? true) &&
          widget.isCurrentUser &&
          !event.isBookmarked) {
        setState(() {
          _posts?.removeWhere((post) => post.id == event.postId);
        });
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        _loadMoreContent();
      }
    });
  }

  Future<void> _loadMoreContent() async {}
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _checkAuthenticationStatus();
      await _fetchProfileData();
      _fadeController.forward();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    if (widget.isCurrentUser) {
      final isLoggedIn = await TokenService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          GoRouter.of(context).replace(RouteNames.login);
        }
        throw Exception('Please log in to view your profile');
      }
    }
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    _logger.info(
        '📱 [ProfileScreen] Starting profile fetch - userId: ${widget.userId}, isCurrentUser: ${widget.isCurrentUser}');
    setState(() => _isLoading = true);
    try {
      if (widget.forceReload) {
        _logger
            .info('🔄 [ProfileScreen] Force reload requested - clearing cache');
        setState(() {
          _userProfile = null;
          _posts = null;
          _shorts = null;
          _questions = null;
        });
        if (_userProfile?.avatarUrl != null) {
          await ImageUtils.evictFromCache(_userProfile!.avatarUrl);
        }
        if (_userProfile?.coverUrl != null) {
          await ImageUtils.evictFromCache(_userProfile!.coverUrl);
        }
      }
      Map<String, dynamic>? profileData;
      if (widget.isCurrentUser) {
        _logger.info('👤 [ProfileScreen] Loading current user profile');
        final authRepository = ServiceLocator.instance.authRepository;
        try {
          final response = await ServiceLocator.instance.apiService
              .get(ApiRoutes.authProfile);
          _logger.info(
              '✅ [ProfileScreen] API response received - status: ${response.statusCode}');
          dynamic responseData = response.data;
          if (responseData is String) {
            _logger.info('📝 [ProfileScreen] Response is String, parsing JSON');
            try {
              responseData = jsonDecode(responseData);
            } catch (e) {
              _logger.error('❌ [ProfileScreen] Failed to parse JSON: $e');
              throw Exception('Invalid response format from API');
            }
          }
          if (responseData != null && responseData is Map) {
            if (responseData['user'] != null && responseData['user'] is Map) {
              profileData = Map<String, dynamic>.from(responseData['user']);
              _logger.info(
                  '✅ [ProfileScreen] Profile data extracted from user key');
            } else if (responseData['data'] != null) {
              if (responseData['data'] is Map) {
                if (responseData['data']['user'] != null &&
                    responseData['data']['user'] is Map) {
                  profileData =
                      Map<String, dynamic>.from(responseData['data']['user']);
                  _logger.info(
                      '✅ [ProfileScreen] Profile data extracted from data.user key');
                } else {
                  profileData = Map<String, dynamic>.from(responseData['data']);
                  _logger.info(
                      '✅ [ProfileScreen] Profile data extracted from data key');
                }
              } else {
                _logger.error(
                    '❌ [ProfileScreen] Invalid data type: ${responseData['data'].runtimeType}');
                throw Exception(
                    'Invalid response format: data field is ${responseData['data'].runtimeType} instead of Map');
              }
            } else {
              profileData = Map<String, dynamic>.from(responseData);
              _logger
                  .info('✅ [ProfileScreen] Profile data extracted from root');
            }
          } else {
            _logger.error(
                '❌ [ProfileScreen] Invalid response type: ${responseData.runtimeType}');
            throw Exception(
                'Invalid response format: expected Map but got ${responseData.runtimeType}');
          }
        } catch (e) {
          _logger.error(
              '❌ [ProfileScreen] API call failed: $e - trying cache fallback');
          try {
            final user = await authRepository.getProfile();
            profileData = user.toJson();
            _logger.info('✅ [ProfileScreen] Profile loaded from cache');
          } catch (profileError) {
            _logger.error(
                '❌ [ProfileScreen] Cache fallback also failed: $profileError');
            throw Exception('Failed to get current user: $profileError');
          }
        }
      } else {
        if (widget.userId == null) {
          _logger.warning(
              '⚠️ [ProfileScreen] No userId provided for other user profile, treating as current user');
          final authRepository = ServiceLocator.instance.authRepository;
          try {
            final user = await authRepository.getProfile();
            profileData = user.toJson();
            _logger.info(
                '✅ [ProfileScreen] Profile loaded as current user (fallback)');
          } catch (e) {
            _logger.error(
                '❌ [ProfileScreen] Failed to load current user (fallback): $e');
            throw Exception('Failed to load profile: $e');
          }
        } else {
          _logger.info(
              '👤 [ProfileScreen] Loading other user profile - userId: ${widget.userId}');
          try {
            final result =
                await _profileRepository.getUserProfile(widget.userId!);
            result.fold(
              (failure) {
                _logger.error(
                    '❌ [ProfileScreen] Failed to load other user profile: ${failure.message}');
                throw Exception('Failed to load profile: ${failure.message}');
              },
              (userData) {
                profileData = userData;
                _logger
                    .info('✅ [ProfileScreen] Other user profile data loaded');
              },
            );
          } catch (e) {
            _logger.error(
                '❌ [ProfileScreen] Exception loading other user profile: $e');
            throw Exception('Failed to load profile: $e');
          }
        }
      }
      if (profileData == null) {
        _logger.error('❌ [ProfileScreen] Profile data is null after loading');
        throw Exception('Failed to load profile: No profile data available');
      }
      _logger.info('🔄 [ProfileScreen] Creating UserProfile from JSON data');
      final userProfile = UserProfile.fromJson(profileData!);
      _logger.info(
          '✅ [ProfileScreen] UserProfile created - id: ${userProfile.id}, name: ${userProfile.name}, isJournalist: ${userProfile.isJournalist}');
      if (!mounted) {
        _logger
            .info('⚠️ [ProfileScreen] Widget unmounted after profile creation');
        return;
      }
      _updateTabController(userProfile.isJournalist);
      if (!mounted) {
        _logger.info(
            '⚠️ [ProfileScreen] Widget unmounted after tab controller update');
        return;
      }
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
      _logger.info(
          '🔄 [ProfileScreen] Loading profile content (posts, shorts, questions)');
      await _loadProfileContent();
      _logger.info('✅ [ProfileScreen] Profile loaded successfully');
    } catch (e, stackTrace) {
      _logger.error('❌ [ProfileScreen] CRITICAL ERROR: $e');
      _logger.error('📍 [ProfileScreen] Stack trace: $stackTrace');
      _handleError(e.toString());
    }
  }

  void _updateTabController(bool isJournalist) {
    if (_tabController.length != 3) {
      _tabController.removeListener(_handleTabChange);
      _tabController.dispose();
      _tabController = TabController(
        length: 3,
        vsync: this,
      );
      _tabController.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging && mounted) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          _fadeController.forward();
        }
      });
    }
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileContent() async {
    if (_userProfile == null) {
      return;
    }
    await Future.wait([
      _loadPosts(),
      _loadShorts(),
      _loadQuestions(),
    ]);
  }

  Future<void> _loadPosts() async {
    try {
      List<dynamic> response;
      if (_userProfile == null) {
        response = [];
      } else if (_userProfile!.isJournalist) {
        final postsResult = await _postRepository.getPosts(
          page: 1,
          userId: widget.userId ?? _userProfile!.id,
          status: 'published',
        );
        response = postsResult['posts'] ?? [];
      } else {
        try {
          final result = await _profileRepository.getUserPublicContent(
            widget.userId ?? _userProfile!.id,
            contentType: 'posts',
          );
          final publicContent = result.fold(
            (failure) => throw Exception(
                'Failed to load public content: ${failure.message}'),
            (data) => data,
          );
          response = publicContent['posts'] ?? [];
        } catch (e) {
          response = [];
        }
      }
      if (mounted) {
        setState(() {
          if (!(_userProfile?.isJournalist ?? true)) {
            _posts = response
                .map((item) {
                  try {
                    final transformedItem = _postRepository.transformPost(item);
                    final post = Post.fromJson(transformedItem);
                    return post;
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<Post>()
                .toList();
          } else {
            _posts = response
                .map((item) {
                  try {
                    final post = Post.fromJson(item);
                    return post;
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<Post>()
                .where((post) {
                  final isValid = post.id.isNotEmpty &&
                      !post.id.startsWith('invalid_post_id_') &&
                      post.type != PostType.short &&
                      post.type != PostType.question;
                  if (!isValid) {}
                  return isValid;
                })
                .toList();
          }
        });
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> _loadShorts() async {
    _logger.info('🎬 [ProfileScreen] Starting to load shorts');
    if (_userProfile == null) {
      _logger.warning(
          '⚠️ [ProfileScreen] User profile is null, cannot load shorts');
      setState(() => _shorts = []);
      return;
    }
    try {
      List<dynamic> response;
      if (_userProfile!.isJournalist) {
        _logger.info(
            '📰 [ProfileScreen] Loading shorts for journalist: ${_userProfile!.id}');
        final shortsResult = await _postRepository.getPosts(
          page: 1,
          userId: widget.userId ?? _userProfile!.id,
          type: PostType.short.name,
          status: 'published',
        );
        response = shortsResult['posts'] ?? [];
        _logger.info(
            '✅ [ProfileScreen] Loaded ${response.length} shorts for journalist');
      } else {
        _logger.info(
            '👤 [ProfileScreen] Loading public shorts for reader: ${_userProfile!.id}');
        try {
          final result = await _profileRepository.getUserPublicContent(
            widget.userId ?? _userProfile!.id,
            contentType: 'shorts',
          );
          final publicContent = result.fold(
            (failure) {
              _logger.error(
                  '❌ [ProfileScreen] Failed to load public shorts: ${failure.message}');
              throw Exception(
                  'Failed to load public content: ${failure.message}');
            },
            (data) {
              _logger.info('✅ [ProfileScreen] Public shorts data received');
              return data;
            },
          );
          response = publicContent['shorts'] ?? [];
          _logger.info(
              '✅ [ProfileScreen] Loaded ${response.length} public shorts');
        } catch (e) {
          _logger
              .error('❌ [ProfileScreen] Exception loading public shorts: $e');
          response = [];
        }
      }
      if (mounted) {
        setState(() {
          if (!(_userProfile?.isJournalist ?? true)) {
            _shorts = response;
            _logger.info(
                '✅ [ProfileScreen] Set ${_shorts!.length} shorts (reader)');
          } else {
            _shorts = response
                .where((item) =>
                    item['type'] == PostType.short &&
                    item['metadata'] != null &&
                    item['metadata']['short'] != null)
                .toList();
            _logger.info(
                '✅ [ProfileScreen] Set ${_shorts!.length} shorts (journalist, filtered)');
          }
        });
      } else {
        _logger.warning(
            '⚠️ [ProfileScreen] Widget unmounted, not setting shorts state');
      }
    } catch (e, stackTrace) {
      _logger.error('❌ [ProfileScreen] CRITICAL ERROR loading shorts: $e');
      _logger.error('📍 [ProfileScreen] Stack trace: $stackTrace');
      _handleError(e.toString());
    }
  }

  Future<void> _loadQuestions() async {
    if (_userProfile == null) {
      setState(() => _questions = []);
      return;
    }
    try {
      List<dynamic> response;
      if (_userProfile!.isJournalist) {
        final questionsResult = await _postRepository.getPosts(
          page: 1,
          userId: widget.userId ?? _userProfile!.id,
          type: PostType.question.name,
          status: 'published',
        );
        response = questionsResult['posts'] ?? [];
      } else {
        try {
          final result = await _profileRepository.getUserPublicContent(
            widget.userId ?? _userProfile!.id,
            contentType: 'questions',
          );
          final publicContent = result.fold(
            (failure) => throw Exception(
                'Failed to load public content: ${failure.message}'),
            (data) => data,
          );
          response = publicContent['questions'] ?? [];
        } catch (e) {
          response = [];
        }
      }
      if (!mounted) return;
      List<dynamic> validQuestions;
      if (!(_userProfile?.isJournalist ?? true)) {
        validQuestions = response;
      } else {
        validQuestions = response
            .where((item) =>
                item['type'] == PostType.question &&
                item['metadata'] != null &&
                item['metadata']['question'] != null)
            .toList();
      }
      setState(() {
        _questions = List<Map<String, dynamic>>.from(validQuestions);
      });
      await _loadQuestionPosts();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> _loadQuestionPosts() async {
    if (_questions == null || _questions!.isEmpty) return;
    try {
      final postsStateProvider = context.read<PostsStateProvider>();
      for (final questionData in _questions!) {
        final questionId = questionData['id']?.toString() ??
            questionData['_id']?.toString() ??
            '';
        if (questionId.isNotEmpty) {
          try {
            final post = await postsStateProvider.loadPost(questionId);
            if (post != null) {
              _questionPosts[questionId] = post;
            }
            final rawData = await _postRepository.getPost(questionId);
            _questionsRawData[questionId] = rawData;
          } catch (e) {
            // Silently skip failed question load
          }
        }
      }
    } catch (e) {
      // Silently skip failed questions fetch
    }
  }

  Future<void> _handleFollowToggle(UserProfile user) async {
    setState(() => _isProcessingFollow = true);
    try {
      await FollowUtils.handleFollowAction(
        user,
        (updatedUser) {
          if (mounted) {
            setState(() {
              _userProfile = updatedUser;
              _isProcessingFollow = false;
            });
          }
        },
        (error) {
          if (mounted) {
            FollowUtils.showErrorSnackBar(context, error);
            setState(() => _isProcessingFollow = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        FollowUtils.showErrorSnackBar(context, e.toString());
        setState(() => _isProcessingFollow = false);
      }
    }
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: AppHeader(
        username: _userProfile?.username,
        showSettingsIcon: widget.isCurrentUser,
        isProfileScreen: true,
      ),
    );
  }

  Widget _buildTabBar() {
    _tabItems = [
      TabItemData(
        title: 'Publications',
        icon: Icons.article,
        activeIcon: Icons.article,
      ),
      TabItemData(
        title: 'Shorts',
        icon: Icons.videocam,
        activeIcon: Icons.videocam,
      ),
      TabItemData(
        title: 'Questions',
        icon: Icons.help_outline,
        activeIcon: Icons.help_outline,
      ),
    ];
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          tabs: _tabItems.map((item) => _buildTab(item)).toList(),
          onTap: (index) {
            _fadeController.reverse().then((_) {
              _fadeController.forward();
            });
          },
        ),
      ),
    );
  }

  Widget _buildTab(TabItemData item) {
    final index = _tabItems.indexOf(item);
    return Row(
      children: [
        if (index > 0)
          VerticalDivider(
            color: Colors.white.withOpacity(0.2),
            width: 1,
            thickness: 0.5,
            indent: 12,
            endIndent: 12,
          ),
        Expanded(
          child: Tab(
            height: 46,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == index;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return TabBarView(
          controller: _tabController,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildPostsSection(),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildShortsSection(),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildQuestionsSection(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostsSection() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadPosts();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: _posts == null
            ? SizedBox(
                height: 200,
                child: Center(child: LoadingIndicator()),
              )
            : _posts!.isEmpty
                ? SizedBox(
                    height: 400,
                    child: _buildEmptyState('publications'),
                  )
                : _buildPostsGrid(),
      ),
    );
  }

  Widget _buildShortsSection() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadShorts();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: _shorts == null
            ? SizedBox(
                height: 200,
                child: Center(child: LoadingIndicator()),
              )
            : _shorts!.isEmpty
                ? SizedBox(
                    height: 400,
                    child: _buildEmptyState('shorts'),
                  )
                : Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: _buildShortsGrid(),
                  ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadQuestions();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: _questions == null
            ? SizedBox(
                height: 200,
                child: Center(child: LoadingIndicator()),
              )
            : _questions!.isEmpty
                ? SizedBox(
                    height: 400,
                    child: _buildEmptyState('questions'),
                  )
                : _buildQuestionsGrid(),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title = type == 'publications'
        ? 'Aucune publication'
        : type == 'shorts'
            ? 'Aucun short'
            : type == 'questions'
                ? 'Aucune question'
                : 'Aucun contenu';
    String? subtitle;
    if (widget.isCurrentUser) {
      if (_userProfile?.isJournalist == true) {
        subtitle = 'Commencez à publier du contenu pour votre audience';
      } else {
        subtitle =
            'Sélectionnez du contenu enregistré à afficher sur votre profil';
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        common_widgets.EmptyState(
          icon: Icons.inbox,
          title: title,
          subtitle: subtitle,
        ),
        if (widget.isCurrentUser) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddContentMenu,
            icon: Icon(_userProfile?.isJournalist == true
                ? Icons.add
                : Icons.bookmark_add),
            label: Text(_userProfile?.isJournalist == true
                ? 'Ajouter du contenu'
                : 'Gérer le contenu public'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPostsGrid() {
    final isJournalist = _userProfile?.isJournalist ?? false;
    final showAddContent = widget.isCurrentUser;
    final itemCount = showAddContent ? _posts!.length + 1 : _posts!.length;
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showAddContent && index == 0) {
          return _buildAddContentTile();
        }
        final postIndex = showAddContent ? index - 1 : index;
        final post = _posts![postIndex];
        return GestureDetector(
          onTap: (post.id.isNotEmpty && !post.id.startsWith('invalid_post_id_'))
              ? () {
                  _navigateToPost(post.id,
                      isSaved: !isJournalist && widget.isCurrentUser);
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              (post.type == PostType.video && post.thumbnailUrl != null)
                  ? Image.network(
                      post.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/default_user_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : post.imageUrl != null
                      ? Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/images/default_user_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/default_user_avatar.png',
                          fit: BoxFit.cover,
                        ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  post.type == PostType.video
                      ? Icons.play_circle
                      : post.type == PostType.podcast
                          ? Icons.headphones
                          : Icons.article,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (!isJournalist && widget.isCurrentUser)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddContentMenu() {
    final isJournalist = _userProfile?.isJournalist ?? false;
    if (!isJournalist) {
      int targetTab = _tabController.index;
      SafeNavigation.push(
        context,
        MaterialPageRoute(
          builder: (context) => SavedContentScreen(
            initialTabIndex: targetTab,
            startInSelectionMode: true,
          ),
        ),
      ).then((_) {
        _loadProfileContent();
      });
      return;
    }
  }

  Widget _buildAddContentTile({double aspectRatio = 1.0}) {
    final isJournalist = _userProfile?.isJournalist ?? false;
    final currentTab = _tabController.index;
    IconData icon;
    String label;
    if (isJournalist) {
      switch (currentTab) {
        case 0:
          icon = Icons.add;
          label = 'Nouveau';
          break;
        case 1:
          icon = Icons.videocam;
          label = 'Nouveau';
          break;
        case 2:
          icon = Icons.add_circle_outline;
          label = 'Nouvelle';
          break;
        default:
          icon = Icons.add;
          label = 'Nouveau';
      }
    } else {
      icon = Icons.bookmark_add;
      label = 'Ajouter';
    }
    return GestureDetector(
      onTap: _showAddContentMenu,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortsGrid() {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 0.6,
      ),
      itemCount: widget.isCurrentUser ? _shorts!.length + 1 : _shorts!.length,
      itemBuilder: (context, index) {
        if (widget.isCurrentUser && index == 0) {
          return _buildAddContentTile(aspectRatio: 0.6);
        }
        final short = _shorts![widget.isCurrentUser ? index - 1 : index];
        final shortId = short['_id'] ?? short['id'];
        return GestureDetector(
          onTap: shortId != null && shortId.toString().isNotEmpty
              ? () => _navigateToShort(shortId.toString())
              : null,
          child: Hero(
            tag: 'short-${shortId ?? 'unknown'}',
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  short['thumbnailUrl'] ??
                      short['imageUrl'] ??
                      'assets/images/default_journalist_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/default_journalist_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionsGrid() {
    if (_questions == null) return const LoadingIndicator();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount:
            widget.isCurrentUser ? _questions!.length + 1 : _questions!.length,
        itemBuilder: (context, index) {
          if (widget.isCurrentUser && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 16),
              child: Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: _showAddContentMenu,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _userProfile!.isJournalist
                              ? Icons.add_circle_outline
                              : Icons.bookmark_add,
                          color: Colors.white.withOpacity(0.9),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _userProfile!.isJournalist
                              ? 'Nouvelle question'
                              : 'Ajouter du contenu',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final actualIndex = widget.isCurrentUser ? index - 1 : index;
          final questionData = _questions![actualIndex];
          final questionId = questionData['id']?.toString() ??
              questionData['_id']?.toString() ??
              '';
          final questionPost = _questionPosts[questionId];
          final rawData = _questionsRawData[questionId];
          if (questionPost != null && rawData != null) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: 16,
                  top: index ==
                          (_userProfile!.isJournalist && widget.isCurrentUser
                              ? 1
                              : 0)
                      ? 16
                      : 0),
              child: GestureDetector(
                onTap: () =>
                    _navigateToQuestion(Question.fromJson(questionData)),
                child: QuestionCardWithVoting(
                  questionPost: questionPost,
                  rawQuestionData: rawData,
                  isFromProfile: true,
                  onVoteCompleted: () {
                    _loadQuestionPosts();
                  },
                ),
              ),
            );
          }
          final question = Question.fromJson(questionData);
          return Padding(
            padding: EdgeInsets.only(
                bottom: 16,
                top: index ==
                        (_userProfile!.isJournalist && widget.isCurrentUser
                            ? 1
                            : 0)
                    ? 16
                    : 0),
            child: GestureDetector(
              onTap: () => _navigateToQuestion(question),
              child: QuestionCard(
                question: question,
                onVote: (optionId, optionText) {},
                isExpanded: false,
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToPost(String postId, {bool isSaved = false}) {
    final effectiveUserId = widget.userId ?? _userProfile?.id;
    if (postId.isEmpty || postId.startsWith('invalid_post_id_')) {
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Impossible d\'ouvrir cet article'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final post = _posts?.firstWhereOrNull((p) => p.id == postId);
    if (post != null && post.type == PostType.question) {
      GoRouter.of(context).push(
        RouteNames.question,
        extra: {
          'questionId': postId,
          'isFromProfile': true,
          'userId': effectiveUserId,
        },
      ).then((_) {
        _loadProfileContent();
      });
    } else if (post?.type == PostType.video) {
      GoRouter.of(context).push(
        RouteNames.videoDetail,
        extra: {
          'postId': postId,
          'isFromProfile': true,
          'userId': widget.userId ?? _userProfile?.id,
          if (isSaved) 'isSaved': true,
        },
      ).then((_) {
        _loadProfileContent();
      });
    } else {
      GoRouter.of(context).push(
        '/post/$postId',
        extra: {
          'postId': postId,
          'isFromProfile': true,
          'userId': widget.userId ?? _userProfile?.id,
          if (isSaved) 'isSaved': true,
        },
      ).then((_) {
        _loadProfileContent();
      });
    }
  }

  void _navigateToShort(String shortId) {
    if (shortId.isEmpty || shortId.startsWith('invalid_post_id_')) {
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Impossible d\'ouvrir ce short'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    GoRouter.of(context).push(
      RouteNames.short,
      extra: {
        'initialShortId': shortId,
        'isLiveMode': false,
      },
    ).then((_) {
      _loadProfileContent();
    });
  }

  void _navigateToQuestion(Question question) {
    final journalistId = question.journalist;
    GoRouter.of(context).push(
      RouteNames.question,
      extra: {
        'questionId': question.id,
        'journalistId': journalistId,
        'isFromProfile': true,
        'userId': widget.userId ?? _userProfile?.id,
      },
    ).then((_) {
      _loadProfileContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement du profil...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (_error != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: ErrorView(
                error: _error!,
                onRetry: _loadProfile,
              ),
            ),
          );
        }
        if (_userProfile == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profil non trouvé',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ce profil n\'existe pas ou a été supprimé',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            extendBody: true,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                Column(
                  children: [
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.black.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: ConnectionStatusIndicator(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: NestedScrollView(
                        physics: BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          _buildAppBar(),
                          SliverToBoxAdapter(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ProfileHeader(
                                userProfile: _userProfile!,
                                onLoadProfile: _loadProfile,
                                isCurrentUser: widget.isCurrentUser,
                                isProcessingFollow: _isProcessingFollow,
                                onFollowToggle: _handleFollowToggle,
                              ),
                            ),
                          ),
                          _buildTabBar(),
                        ],
                        body: _buildContent(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    _postCreatedSubscription?.cancel();
    _postUpdatedSubscription?.cancel();
    _postDeletedSubscription?.cancel();
    _postBookmarkedSubscription?.cancel();
    super.dispose();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: overlapsContent ? 10 : 0,
          sigmaY: overlapsContent ? 10 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: overlapsContent ? 0.9 : 1.0),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            boxShadow: overlapsContent
                ? [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: _tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
