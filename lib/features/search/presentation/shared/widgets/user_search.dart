import 'package:thot/core/themes/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/shared/widgets/common/loading_indicator.dart';
import 'package:thot/shared/widgets/common/error_view.dart';
import 'package:thot/shared/widgets/common/empty_state.dart';
import 'package:thot/features/profile/utils/follow_utils.dart';
import 'package:thot/core/utils/number_formatter.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
class UserSection {
  final String title;
  final List<UserProfile> users;
  UserSection({required this.title, required this.users});
}
class _UserListItemStyles {
  final double radius;
  final double fontSize;
  final double subtitleSize;
  final double iconSize;
  final double buttonHeight;
  const _UserListItemStyles({
    required this.radius,
    required this.fontSize,
    required this.subtitleSize,
    required this.iconSize,
    required this.buttonHeight,
  });
}
class UserSearch extends StatefulWidget {
  final List<UserProfile> users;
  final bool isLoading;
  final String? error;
  final Function(String) onSearch;
  final VoidCallback onRetry;
  final String emptyStateMessage;
  const UserSearch({
    super.key,
    required this.users,
    required this.isLoading,
    this.error,
    required this.onSearch,
    required this.onRetry,
    required this.emptyStateMessage,
  });
  @override
  State<UserSearch> createState() => _UserSearchState();
}
class _UserSearchState extends State<UserSearch> {
  Timer? _debounceTimer;
  List<UserSection> _sections = [];
  final Set<String> _loadingUserIds = {};
  String _currentSearchText = '';
  @override
  void initState() {
    super.initState();
    _updateSections();
  }
  void _onSearchChanged(String value) {
    if (_currentSearchText != value) {
      _currentSearchText = value;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onSearch(value);
        }
      });
    }
  }
  @override
  void didUpdateWidget(UserSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _updateSections();
    }
  }
  void _updateSections() {
    List<UserProfile> users = List.from(widget.users);
    if (_currentSearchText.isEmpty) {
      final followedJournalists =
          users.where((u) => u.isJournalist && u.isFollowing).toList();
      final popularJournalists = users
          .where((u) => u.isJournalist && !u.isFollowing)
          .toList()
        ..sort((a, b) => b.followersCount.compareTo(a.followersCount));
      final popularUsers = users
          .where((u) => !u.isJournalist && !u.isFollowing)
          .toList()
        ..sort((a, b) => b.followersCount.compareTo(a.followersCount));
      setState(() {
        _sections = [
          if (followedJournalists.isNotEmpty)
            UserSection(title: 'Vos abonnements', users: followedJournalists),
          if (popularJournalists.isNotEmpty)
            UserSection(
                title: 'Journalistes populaires',
                users: popularJournalists.take(5).toList()),
          if (popularUsers.isNotEmpty)
            UserSection(
                title: 'Utilisateurs populaires',
                users: popularUsers.take(5).toList()),
        ];
      });
    } else {
      final followedJournalists = users
          .where((u) => u.isJournalist && u.isFollowing && _matchesSearch(u))
          .toList();
      final otherJournalists = users
          .where((u) => u.isJournalist && !u.isFollowing && _matchesSearch(u))
          .toList();
      final regularUsers =
          users.where((u) => !u.isJournalist && _matchesSearch(u)).toList();
      setState(() {
        _sections = [
          if (followedJournalists.isNotEmpty)
            UserSection(title: 'Abonnements', users: followedJournalists),
          if (otherJournalists.isNotEmpty)
            UserSection(title: 'Journalistes', users: otherJournalists),
          if (regularUsers.isNotEmpty)
            UserSection(title: 'Utilisateurs', users: regularUsers),
        ];
      });
    }
  }
  bool _matchesSearch(UserProfile user) {
    final query = _currentSearchText.toLowerCase();
    final displayName = (user.name ?? user.username).toLowerCase();
    return displayName.contains(query) ||
        (user.organization?.toLowerCase().contains(query) ?? false);
  }
  Future<void> _handleFollowAction(UserProfile user) async {
    if (_loadingUserIds.contains(user.id)) return;
    setState(() {
      _loadingUserIds.add(user.id);
    });
    try {
      await FollowUtils.handleFollowAction(
        user,
        (updatedUser) {
          if (mounted) {
            setState(() {
              List<UserSection> newSections = [];
              for (var section in _sections) {
                var updatedUsers =
                    section.users.where((u) => u.id != user.id).toList();
                if (_currentSearchText.isEmpty) {
                  if (section.title == 'Vos abonnements' &&
                      updatedUser.isFollowing) {
                    updatedUsers.add(updatedUser);
                  } else if (section.title == 'Journalistes populaires' &&
                      !updatedUser.isFollowing) {
                    updatedUsers.add(updatedUser);
                    updatedUsers.sort(
                        (a, b) => b.followersCount.compareTo(a.followersCount));
                    updatedUsers = updatedUsers.take(5).toList();
                  }
                } else {
                  if (section.title == 'Abonnements' &&
                      updatedUser.isFollowing) {
                    updatedUsers.add(updatedUser);
                  } else if (section.title == 'Journalistes' &&
                      !updatedUser.isFollowing) {
                    updatedUsers.add(updatedUser);
                  }
                }
                if (updatedUsers.isNotEmpty) {
                  newSections.add(
                      UserSection(title: section.title, users: updatedUsers));
                }
              }
              if (_currentSearchText.isEmpty) {
                if (updatedUser.isFollowing &&
                    !newSections.any((s) => s.title == 'Vos abonnements')) {
                  newSections.insert(
                      0,
                      UserSection(
                          title: 'Vos abonnements', users: [updatedUser]));
                }
              } else {
                if (updatedUser.isFollowing &&
                    !newSections.any((s) => s.title == 'Abonnements')) {
                  newSections.insert(0,
                      UserSection(title: 'Abonnements', users: [updatedUser]));
                } else if (!updatedUser.isFollowing &&
                    !newSections.any((s) => s.title == 'Journalistes')) {
                  var insertIndex = newSections.isEmpty ? 0 : 1;
                  newSections.insert(insertIndex,
                      UserSection(title: 'Journalistes', users: [updatedUser]));
                }
              }
              _sections = newSections;
              _loadingUserIds.remove(user.id);
            });
          }
        },
        (error) {
          if (mounted) {
            FollowUtils.showErrorSnackBar(context, error);
            setState(() {
              _loadingUserIds.remove(user.id);
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        FollowUtils.showErrorSnackBar(context, e.toString());
        setState(() {
          _loadingUserIds.remove(user.id);
        });
      }
    }
  }
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }
  Widget _buildContent() {
    if (widget.error != null) {
      return ErrorView(
        error: widget.error!,
        onRetry: widget.onRetry,
      );
    }
    if (widget.isLoading) {
      return const Center(child: LoadingIndicator());
    }
    if (widget.users.isEmpty || _sections.isEmpty) {
      return EmptyState(
        icon: Icons.personSearch,
        title: 'Aucun utilisateur trouvé',
        subtitle: widget.emptyStateMessage,
      );
    }
    return ListView.builder(
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    section.title.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[800]!,
                            Colors.grey[800]!.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...section.users.map((user) => _buildUserListItem(user)),
            if (index < _sections.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.grey[900]!,
                      Colors.grey[800]!,
                      Colors.grey[900]!,
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  static const _regularStyles = _UserListItemStyles(
    radius: 28.0,
    fontSize: 14.0,
    subtitleSize: 12.0,
    iconSize: 20.0,
    buttonHeight: 36.0,
  );
  Widget _buildUserListItem(UserProfile user) {
    final styles = _regularStyles;
    final isLoading = _loadingUserIds.contains(user.id);
    return InkWell(
      onTap: () {
        if (mounted) {
          context.replaceNamed(
            RouteNames.profile,
            extra: {'userId': user.id, 'forceReload': true},
          );
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              widget.onSearch(_currentSearchText);
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: styles.radius,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(ImageUtils.getAvatarUrl(user.avatarUrl!))
                      : AssetImage(
                              'assets/images/defaults/${user.isJournalist ? "default_journalist_avatar.png" : "default_user_avatar.png"}')
                          as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
                if (user.isJournalist && user.pressCard != null && user.pressCard!.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: VerificationBadge(size: styles.iconSize),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.isJournalist
                        ? (user.name ?? user.username)
                        : '@${user.username}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: styles.fontSize,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.isJournalist
                        ? (user.organization ?? user.journalistRole ?? 'Journaliste')
                        : (user.name ?? ''),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: styles.subtitleSize,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${NumberFormatter.formatCompact(user.followersCount)} abonnés',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: styles.subtitleSize - 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (user.isJournalist)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: isLoading ? null : () => _handleFollowAction(user),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: styles.buttonHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: user.isFollowing
                          ? Colors.grey[900]
                          : Theme.of(context).primaryColor,
                      border: user.isFollowing
                          ? Border.all(color: Colors.grey[700]!, width: 1)
                          : null,
                      borderRadius:
                          BorderRadius.circular(styles.buttonHeight / 2),
                      gradient: user.isFollowing
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.8),
                              ],
                            ),
                      boxShadow: user.isFollowing
                          ? null
                          : [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: styles.iconSize,
                            height: styles.iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                user.isFollowing
                                    ? Colors.grey[400]!
                                    : Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isFollowing ? Icons.check : Icons.add,
                                color: user.isFollowing
                                    ? Colors.grey[400]
                                    : Colors.white,
                                size: styles.iconSize,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.isFollowing ? 'Abonné' : 'Suivre',
                                style: TextStyle(
                                  color: user.isFollowing
                                      ? Colors.grey[400]
                                      : Colors.white,
                                  fontSize: styles.subtitleSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}