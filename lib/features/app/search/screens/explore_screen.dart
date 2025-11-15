import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/shared/widgets/layouts/app_header.dart';
import 'package:thot/features/app/profile/utils/follow_utils.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/features/app/search/widgets/search_bar_widget.dart';
import 'package:thot/features/app/search/widgets/search_filter_chip.dart';
import 'package:thot/features/app/search/widgets/journalist_card.dart';
import 'package:thot/features/app/search/widgets/journalist_list_item.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _logger = LoggerService.instance;
  final _profileRepository = ServiceLocator.instance.profileRepository;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  late AnimationController _animationController;
  List<UserProfile> _popularJournalists = [];
  bool _isLoadingPopular = true;
  List<UserProfile> _allJournalists = [];
  List<UserProfile> _filteredJournalists = [];
  bool _isLoadingAll = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  String _searchQuery = '';
  String? _selectedOrientation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
    _loadJournalists();
    _loadPopularJournalists();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingAll &&
        _hasMorePages &&
        _searchQuery.isEmpty) {
      _loadMoreJournalists();
    }
  }

  Future<void> _loadPopularJournalists() async {
    if (!mounted) return;
    _logger.info('🌟 [ExploreScreen] Starting to load popular journalists');
    setState(() {
      _isLoadingPopular = true;
    });
    try {
      _logger.info('🔍 [ExploreScreen] Fetching suggested users');
      final result = await _profileRepository.getSuggestedUsers();
      List<UserProfile> journalists = [];
      result.fold(
        (failure) {
          _logger.warning(
              '⚠️ [ExploreScreen] Failed to get suggested users: ${failure.message}');
          journalists = [];
        },
        (users) {
          _logger.info('✅ [ExploreScreen] Got ${users.length} suggested users');
          journalists = users;
        },
      );
      if (journalists.isEmpty) {
        _logger.info(
            '🔍 [ExploreScreen] No suggested users, fetching all journalists');
        final allResult =
            await _profileRepository.searchUsers(query: '', page: 1);
        allResult.fold(
          (failure) {
            _logger.error(
                '❌ [ExploreScreen] Failed to search users: ${failure.message}');
            journalists = [];
          },
          (data) {
            journalists = (data['users'] as List?)?.cast<UserProfile>() ?? [];
            _logger.info(
                '✅ [ExploreScreen] Got ${journalists.length} journalists from search');
          },
        );
      }
      if (!mounted) {
        _logger.warning(
            '⚠️ [ExploreScreen] Widget unmounted after loading journalists');
        return;
      }
      setState(() {
        var popularList = journalists;
        popularList
            .sort((a, b) => b.followersCount.compareTo(a.followersCount));
        _popularJournalists = popularList.take(5).toList();
        if (_popularJournalists.isEmpty && popularList.isNotEmpty) {
          _popularJournalists = [popularList.first];
        }
        _logger.info(
            '✅ [ExploreScreen] Set ${_popularJournalists.length} popular journalists');
        _isLoadingPopular = false;
      });
    } catch (e, stackTrace) {
      _logger.error(
          '❌ [ExploreScreen] CRITICAL ERROR loading popular journalists: $e');
      _logger.error('📍 [ExploreScreen] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoadingPopular = false;
        if (_allJournalists.isNotEmpty) {
          _logger.info(
              '🔄 [ExploreScreen] Using fallback from all journalists list');
          var sortedAll = List<UserProfile>.from(_allJournalists);
          sortedAll
              .sort((a, b) => b.followersCount.compareTo(a.followersCount));
          _popularJournalists = sortedAll.take(5).toList();
        }
      });
    }
  }

  Future<void> _loadJournalists({String? search}) async {
    if (!mounted) return;
    _logger.info(
        '🔍 [ExploreScreen] Loading journalists - search: "${search ?? ""}"');
    setState(() {
      _isLoadingAll = true;
      _error = null;
      _currentPage = 1;
      _searchQuery = search ?? '';
      _allJournalists.clear();
    });
    try {
      final result = await _profileRepository.searchUsers(
        query: search ?? '',
        page: 1,
      );
      if (!mounted) {
        _logger.warning('⚠️ [ExploreScreen] Widget unmounted after search');
        return;
      }
      result.fold(
        (failure) {
          _logger.error('❌ [ExploreScreen] Search failed: ${failure.message}');
          setState(() {
            _error = failure.message;
            _isLoadingAll = false;
          });
        },
        (data) {
          final users = (data['users'] as List?)?.cast<UserProfile>() ?? [];
          _logger.info(
              '✅ [ExploreScreen] Search returned ${users.length} journalists');
          setState(() {
            _allJournalists = users;
            _hasMorePages = data['hasMore'] ?? false;
            _isLoadingAll = false;
          });
          _applyFilters();
        },
      );
    } catch (e, stackTrace) {
      _logger
          .error('❌ [ExploreScreen] CRITICAL ERROR searching journalists: $e');
      _logger.error('📍 [ExploreScreen] Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _loadMoreJournalists() async {
    if (!mounted || _isLoadingAll || !_hasMorePages) return;
    setState(() {
      _isLoadingAll = true;
    });
    try {
      final result = await _profileRepository.searchUsers(
        query: _searchQuery,
        page: _currentPage + 1,
      );
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _isLoadingAll = false;
          });
        },
        (data) {
          setState(() {
            _allJournalists
                .addAll((data['users'] as List?)?.cast<UserProfile>() ?? []);
            _currentPage++;
            _hasMorePages = data['hasMore'] ?? false;
            _isLoadingAll = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadJournalists(search: query);
    });
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      if (_selectedOrientation == null) {
        _filteredJournalists = List.from(_allJournalists);
      } else {
        _filteredJournalists = _allJournalists.where((journalist) {
          final politicalViews = journalist.politicalViews;
          if (politicalViews?.isEmpty ?? true) {
            return _selectedOrientation == 'neutral';
          }
          final orientation = politicalViews['orientation'] as String?;
          if (orientation == null || orientation.isEmpty) {
            return _selectedOrientation == 'neutral';
          }
          return orientation.toLowerCase() ==
              _selectedOrientation!.toLowerCase();
        }).toList();
      }
    });
  }

  void _handleFollow(UserProfile user, int index, bool isPopular) {
    FollowUtils.handleFollowAction(
      user,
      (updatedUser) {
        setState(() {
          if (isPopular) {
            _popularJournalists[index] = updatedUser;
          } else {
            final allIndex = _allJournalists.indexWhere((u) => u.id == user.id);
            if (allIndex != -1) {
              _allJournalists[allIndex] = updatedUser;
            }
            final filteredIndex =
                _filteredJournalists.indexWhere((u) => u.id == user.id);
            if (filteredIndex != -1) {
              _filteredJournalists[filteredIndex] = updatedUser;
            }
          }
          final popularIndex =
              _popularJournalists.indexWhere((u) => u.id == user.id);
          if (popularIndex != -1) {
            _popularJournalists[popularIndex] = updatedUser;
          }
        });
      },
      (error) => FollowUtils.showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadJournalists();
                await _loadPopularJournalists();
              },
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SearchBarWidget(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      hintText: 'Rechercher des journalistes...',
                      showClearButton: _searchQuery.isNotEmpty,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SearchFilterBar(
                      filters: const [
                        SearchFilterChipData(
                          label: 'Tous',
                          value: '',
                          color: AppColors.neutral,
                        ),
                        SearchFilterChipData(
                          label: 'Neutres',
                          value: 'neutral',
                          icon: Icons.remove,
                          color: AppColors.neutral,
                        ),
                        SearchFilterChipData(
                          label: 'Conservateurs',
                          value: 'conservative',
                          icon: Icons.chevron_left,
                          color: AppColors.conservative,
                        ),
                        SearchFilterChipData(
                          label: 'Très conservateurs',
                          value: 'extremelyConservative',
                          icon: Icons.keyboard_double_arrow_left,
                          color: AppColors.extremelyConservative,
                        ),
                        SearchFilterChipData(
                          label: 'Progressistes',
                          value: 'progressive',
                          icon: Icons.chevron_right,
                          color: AppColors.progressive,
                        ),
                        SearchFilterChipData(
                          label: 'Très progressistes',
                          value: 'extremelyProgressive',
                          icon: Icons.keyboard_double_arrow_right,
                          color: AppColors.extremelyProgressive,
                        ),
                      ],
                      selectedFilter: _selectedOrientation,
                      onFilterSelected: (filter) {
                        setState(() {
                          _selectedOrientation = filter.isEmpty ? null : filter;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'Résultats pour "$_searchQuery"',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_isLoadingAll)
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_searchQuery.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(
                          'Journalistes populaires',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_isLoadingPopular)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 150,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      )
                    else if (_popularJournalists.isNotEmpty)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _popularJournalists.length,
                            itemBuilder: (context, index) {
                              final journalist = _popularJournalists[index];
                              return JournalistCard(
                                journalist: journalist,
                                onFollow: () =>
                                    _handleFollow(journalist, index, true),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Container(
                          height: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun journaliste disponible pour l\'instant',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _loadPopularJournalists,
                                  child: const Text(
                                    'Réessayer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Text(
                          'Tous les journalistes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.withOpacity(0.8), size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Une erreur est survenue',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _searchQuery.isEmpty
                                  ? _loadJournalists
                                  : () =>
                                      _loadJournalists(search: _searchQuery),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredJournalists.isEmpty && !_isLoadingAll)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.3),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucun journaliste trouvé'
                                  : _selectedOrientation != null
                                      ? 'Aucun journaliste avec cette orientation'
                                      : 'Aucun journaliste disponible',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _filteredJournalists.length) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _isLoadingAll
                                    ? const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }
                          final journalist = _filteredJournalists[index];
                          return JournalistListItem(
                            journalist: journalist,
                            onFollow: () =>
                                _handleFollow(journalist, index, false),
                          );
                        },
                        childCount: _filteredJournalists.length +
                            (_isLoadingAll ? 1 : 0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
