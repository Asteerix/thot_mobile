import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/features/app/profile/providers/follow_state_provider.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/shared/widgets/images/user_avatar.dart';
import 'package:thot/features/app/profile/widgets/follow_button.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;

  const FollowingScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _profileRepository = ServiceLocator.instance.profileRepository;

  List<UserProfile> _allFollowing = [];
  List<UserProfile> _filteredFollowing = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _processingFollows = {};

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterFollowing();
    });
  }

  void _filterFollowing() {
    if (_searchQuery.isEmpty) {
      _filteredFollowing = List.from(_allFollowing);
    } else {
      _filteredFollowing = _allFollowing.where((user) {
        final name = (user.name ?? '').toLowerCase();
        final username = user.username.toLowerCase();
        return name.contains(_searchQuery) || username.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadFollowing() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📥 [FOLLOWING] Loading following for userId: ${widget.userId}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    setState(() => _isLoading = true);

    try {
      print('📡 [FOLLOWING] Calling API...');
      final result = await _profileRepository.getFollowing(widget.userId);

      print('📦 [FOLLOWING] API response received');

      result.fold(
        (failure) {
          print('❌ [FOLLOWING] API failed: ${failure.message}');
          if (mounted) {
            setState(() => _isLoading = false);
            SafeNavigation.showSnackBar(
              context,
              SnackBar(
                content: Text('Erreur: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (following) {
          print(
              '✅ [FOLLOWING] Success! Received ${following.length} following');
          if (following.isNotEmpty) {
            print(
                '   First following: ${following[0].username} (${following[0].id})');
          }
          if (mounted) {
            setState(() {
              _allFollowing = following;
              _filterFollowing();
              _isLoading = false;
            });
            print(
                '✅ [FOLLOWING] State updated - displaying ${_filteredFollowing.length} following');
          }
        },
      );
    } catch (e, stackTrace) {
      print('❌ [FOLLOWING] Exception: $e');
      print('   Stack: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFollow(UserProfile user) async {
    if (_processingFollows.contains(user.id)) return;

    setState(() => _processingFollows.add(user.id));
    HapticFeedback.lightImpact();

    try {
      final profileRepository = ServiceLocator.instance.profileRepository;

      if (user.isFollowing) {
        final result = await profileRepository.unfollowUser(user.id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {
            if (mounted) {
              setState(() {
                final index = _allFollowing.indexWhere((u) => u.id == user.id);
                if (index != -1) {
                  _allFollowing[index] = _allFollowing[index].copyWith(
                    isFollowing: false,
                    followersCount: _allFollowing[index].followersCount - 1,
                  );
                }
                _filterFollowing();
              });
            }
          },
        );
      } else {
        final result = await profileRepository.followUser(user.id);
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) {
            if (mounted) {
              setState(() {
                final index = _allFollowing.indexWhere((u) => u.id == user.id);
                if (index != -1) {
                  _allFollowing[index] = _allFollowing[index].copyWith(
                    isFollowing: true,
                    followersCount: _allFollowing[index].followersCount + 1,
                  );
                }
                _filterFollowing();
              });
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingFollows.remove(user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Abonnements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Rechercher',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 15),
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : _filteredFollowing.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun abonnement'
                                  : 'Aucun résultat',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredFollowing.length,
                        itemBuilder: (context, index) {
                          final user = _filteredFollowing[index];
                          final isCurrentUser = currentUserId == user.id;
                          final isProcessing =
                              _processingFollows.contains(user.id);

                          return InkWell(
                            onTap: () {
                              context.pop();
                              if (isCurrentUser) {
                                context.go('/profile');
                              } else {
                                context.go('/profile/${user.id}');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    avatarUrl: user.avatarUrl,
                                    name: user.name ?? user.username,
                                    isJournalist: user.isJournalist,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user.username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (user.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isCurrentUser) ...[
                                    const SizedBox(width: 12),
                                    FollowButton(
                                      userId: user.id,
                                      isFollowing: user.isFollowing,
                                      compact: true,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
