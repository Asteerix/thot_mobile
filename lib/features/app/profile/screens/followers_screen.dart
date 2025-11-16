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

class FollowersScreen extends StatefulWidget {
  final String userId;

  const FollowersScreen({
    super.key,
    required this.userId,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _profileRepository = ServiceLocator.instance.profileRepository;

  List<UserProfile> _allFollowers = [];
  List<UserProfile> _filteredFollowers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFollowers();
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
      _filterFollowers();
    });
  }

  void _filterFollowers() {
    if (_searchQuery.isEmpty) {
      _filteredFollowers = List.from(_allFollowers);
    } else {
      _filteredFollowers = _allFollowers.where((user) {
        final name = (user.name ?? '').toLowerCase();
        final username = user.username.toLowerCase();
        return name.contains(_searchQuery) || username.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadFollowers() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📥 [FOLLOWERS] Loading followers for userId: ${widget.userId}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    setState(() => _isLoading = true);

    try {
      print('📡 [FOLLOWERS] Calling API...');
      final result = await _profileRepository.getFollowers(widget.userId);

      print('📦 [FOLLOWERS] API response received');

      result.fold(
        (failure) {
          print('❌ [FOLLOWERS] API failed: ${failure.message}');
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
        (followers) {
          print('✅ [FOLLOWERS] Success! Received ${followers.length} followers');
          if (followers.isNotEmpty) {
            print('   First follower: ${followers[0].username} (${followers[0].id})');
          }
          if (mounted) {
            setState(() {
              _allFollowers = followers;
              _filterFollowers();
              _isLoading = false;
            });
            print('✅ [FOLLOWERS] State updated - displaying ${_filteredFollowers.length} followers');
          }
        },
      );
    } catch (e, stackTrace) {
      print('❌ [FOLLOWERS] Exception: $e');
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
    final followProvider = context.read<FollowStateProvider>();

    HapticFeedback.lightImpact();

    try {
      await followProvider.toggleFollow(user.id);
    } catch (e) {
      if (mounted) {
        SafeNavigation.showSnackBar(
          context,
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userProfile?.id;
    final isOwnProfile = currentUserId == widget.userId;

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
          'Abonnés',
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
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                : _filteredFollowers.isEmpty
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
                                  ? 'Aucun abonné'
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
                        itemCount: _filteredFollowers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredFollowers[index];
                          final isCurrentUser = currentUserId == user.id;

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
