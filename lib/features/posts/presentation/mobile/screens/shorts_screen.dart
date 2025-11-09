import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/storage/token_service.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/authentication/presentation/mixins/auth_aware_mixin.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/posts/presentation/shared/widgets/short_video_player.dart';
import 'package:thot/shared/widgets/common/empty_content_view.dart';
class ShortsScreen extends StatefulWidget {
  final String? initialDomain;
  const ShortsScreen({
    super.key,
    this.initialDomain,
  });
  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}
class _ShortsScreenState extends State<ShortsScreen>
    with AuthAwareMixin, SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  PostRepositoryImpl? _postRepository;
  List<Post> _shorts = [];
  final Map<String, List<Post>> _shortsByDomain = {};
  List<String> _availableDomains = [];
  String? _currentDomain;
  int _currentDomainIndex = 0;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _currentDomain = widget.initialDomain;
    _initializeAndLoadShorts();
  }
  Future<void> _initializeAndLoadShorts() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('Token is null, cannot load shorts');
        if (mounted) {
          setState(() {
            _error = 'Authentication required';
            _isLoading = false;
          });
        }
        return;
      }
      debugPrint('Initializing PostRepository with token');
      _postRepository = ServiceLocator.instance.postRepository;
      debugPrint('Fetching shorts from service');
      final shorts = await _postRepository!.getShorts();
      debugPrint('Received ${shorts.length} shorts from service');
      _shortsByDomain.clear();
      for (var post in shorts) {
        final domain = post.domain.toString().split('.').last;
        _shortsByDomain[domain] ??= [];
        _shortsByDomain[domain]!.add(post);
      }
      _availableDomains = _shortsByDomain.keys.toList();
      if (_currentDomain == null && _availableDomains.isNotEmpty) {
        _currentDomain = _availableDomains.first;
      }
      _currentDomainIndex = _availableDomains.indexOf(_currentDomain ?? '');
      if (_currentDomainIndex == -1) _currentDomainIndex = 0;
      if (mounted) {
        setState(() {
          _shorts = _currentDomain != null
              ? (_shortsByDomain[_currentDomain] ?? [])
              : shorts;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading shorts: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (_isLoading || _postRepository == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!mounted) return;
                              setState(() {
                                _error = null;
                                _isLoading = true;
                              });
                              await _initializeAndLoadShorts();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        disabledBackgroundColor: Colors.white12,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Loading...' : 'Retry',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ));
    }
    if (_shorts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: EmptyContentView(
          icon: Icons.movie_filter,
          title: 'Pas de shorts disponibles',
          subtitle: _error,
          actionLabel: _isLoading ? 'Chargement...' : 'Actualiser',
          onAction: _isLoading
              ? null
              : () async {
                  if (!mounted) return;
                  setState(() {
                    _isLoading = true;
                  });
                  await _initializeAndLoadShorts();
                },
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        controller: PageController(initialPage: _currentDomainIndex),
        itemCount: _availableDomains.length,
        onPageChanged: (index) {
          if (!mounted) return;
          setState(() {
            _currentDomainIndex = index;
            _currentDomain = _availableDomains[index];
            _shorts = _shortsByDomain[_currentDomain] ?? [];
          });
        },
        itemBuilder: (context, domainIndex) {
          final domain = _availableDomains[domainIndex];
          final domainShorts = _shortsByDomain[domain] ?? [];
          return PageView.builder(
            scrollDirection:
                Axis.vertical,
            itemCount: domainShorts.length,
            itemBuilder: (context, shortIndex) {
              final post = domainShorts[shortIndex];
              return ShortVideoPlayer(
                post: post,
                shortsService: _postRepository!,
                onLike: () {},
                onDislike: () {},
                onComment: () {},
              );
            },
          );
        },
      ),
    );
  }
}