import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/profile/utils/follow_utils.dart';
import 'package:thot/shared/widgets/common/error_view.dart';
import 'package:thot/shared/widgets/common/empty_state.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/core/utils/safe_navigation.dart';
enum FollowersFilter { all, journalists, banned }
class FollowersScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;
  const FollowersScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });
  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}
class _FollowersScreenState extends State<FollowersScreen> {
  final _profileRepository = ServiceLocator.instance.profileRepository;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final _Debouncer _debouncer =
      _Debouncer(const Duration(milliseconds: 250));
  List<UserProfile>? _allFollowers;
  List<UserProfile>? _filteredFollowers;
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _processingIds = {};
  String _searchQuery = '';
  FollowersFilter _filter = FollowersFilter.all;
  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debouncer.dispose();
    super.dispose();
  }
  Future<void> _loadFollowers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _profileRepository.getFollowers(widget.userId);
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (followers) {
          setState(() {
            _allFollowers = followers;
            _applyFilters();
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  void _applyFilters() {
    final base = _allFollowers ?? <UserProfile>[];
    Iterable<UserProfile> out = base;
    switch (_filter) {
      case FollowersFilter.journalists:
        out = out.where((u) => u.isJournalist == true);
        break;
      case FollowersFilter.banned:
        out = out.where((u) => u.isBanned == true);
        break;
      case FollowersFilter.all:
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      out = out.where((user) {
        final displayName = (user.name ?? user.username).toLowerCase();
        return displayName.contains(q) ||
            (user.organization?.toLowerCase().contains(q) ?? false);
      });
    }
    _filteredFollowers = out.toList(growable: false);
  }
  void _onSearchChanged(String value) {
    _debouncer.run(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _applyFilters();
      });
    });
  }
  Future<void> _handleFollowToggle(UserProfile user) async {
    if (!mounted || _processingIds[user.id] == true) return;
    HapticFeedback.selectionClick();
    setState(() {
      _processingIds[user.id] = true;
    });
    try {
      await FollowUtils.handleFollowAction(
        user,
        (updatedUser) {
          if (!mounted) return;
          setState(() {
            final i = _allFollowers!.indexWhere((f) => f.id == user.id);
            if (i != -1) _allFollowers![i] = updatedUser;
            _applyFilters();
            _processingIds[user.id] = false;
          });
        },
        (error) {
          if (!mounted) return;
          FollowUtils.showErrorSnackBar(context, error);
          setState(() => _processingIds[user.id] = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      FollowUtils.showErrorSnackBar(context, e.toString());
      setState(() => _processingIds[user.id] = false);
    }
  }
  Future<void> _handleRemoveFollower(UserProfile follower) async {
    if (!mounted || _processingIds[follower.id] == true) return;
    final ok = await _confirmRemoveSheet(follower);
    if (ok != true) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _processingIds[follower.id] = true;
    });
    final previous = List<UserProfile>.from(_allFollowers ?? const []);
    try {
      final result = await _profileRepository.unfollowUser(follower.id);
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _processingIds[follower.id] = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${failure.message}')),
            );
          }
        },
        (_) {
          setState(() {
            _allFollowers!.removeWhere((f) => f.id == follower.id);
            _applyFilters();
            _processingIds[follower.id] = false;
          });
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Abonné retiré'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _allFollowers = previous;
                _applyFilters();
              });
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FollowUtils.showErrorSnackBar(context, e.toString());
      setState(() => _processingIds[follower.id] = false);
    }
  }
  Future<bool?> _confirmRemoveSheet(UserProfile follower) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _Avatar(follower: follower, size: 36),
                  title: Text(follower.name ?? follower.username,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('@${follower.username}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.errorContainer,
                    foregroundColor: cs.onErrorContainer,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Retirer cet abonné'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _navigateToProfile(UserProfile user) {
    if (!mounted) return;
    context.pushNamed(
      RouteNames.profile,
      extra: {'userId': user.id, 'forceReload': true},
    );
  }
  void _setFilter(FollowersFilter f) {
    setState(() {
      _filter = f;
      _applyFilters();
    });
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = _filteredFollowers?.length ?? 0;
    return GestureDetector(
      onTap: () => _searchFocus.unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: RefreshIndicator(
          onRefresh: _loadFollowers,
          child: Scrollbar(
            controller: _scrollController,
            interactive: true,
            child: CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverAppBar.large(
                  backgroundColor: cs.surface,
                  pinned: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => SafeNavigation.pop(context),
                  ),
                  title: const Text('Abonnés'),
                  actions: [
                    if (_allFollowers != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: _CountBadge(count: _allFollowers!.length),
                        ),
                      ),
                  ],
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeader(
                    height: 100,
                    child: Container(
                      color: cs.surface,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        children: [
                          _SearchField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                          ),
                          const SizedBox(height: 8),
                          _FilterBar(
                            selected: _filter,
                            onChanged: _setFilter,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  _SkeletonListSlivers(),
                ] else if (_error != null) ...[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: ErrorView(error: _error!, onRetry: _loadFollowers),
                    ),
                  ),
                ] else if (_filteredFollowers == null ||
                    _filteredFollowers!.isEmpty) ...[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.group,
                        title: 'Aucun abonné',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Aucun résultat pour "$_searchQuery"'
                            : 'Les personnes qui vous suivent apparaîtront ici',
                      ),
                    ),
                  ),
                ] else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final follower = _filteredFollowers![index];
                          final isProcessing =
                              _processingIds[follower.id] == true;
                          final tile = _FollowerTile(
                            follower: follower,
                            isProcessing: isProcessing,
                            isCurrentUser: widget.isCurrentUser,
                            searchQuery: _searchQuery,
                            onTap: () => _navigateToProfile(follower),
                            onFollowToggle: () => _handleFollowToggle(follower),
                            onRemove: () => _handleRemoveFollower(follower),
                          );
                          if (widget.isCurrentUser) {
                            return Dismissible(
                              key: ValueKey('dismiss_${follower.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) =>
                                  _confirmRemoveSheet(follower),
                              onDismissed: (_) =>
                                  _handleRemoveFollower(follower),
                              background: _DismissBackground(),
                              child: tile,
                            );
                          }
                          return tile;
                        },
                        childCount: count,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Rechercher…',
        prefixIcon: Icon(Icons.search),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
      ),
      textInputAction: TextInputAction.search,
    );
  }
}
class _FilterBar extends StatelessWidget {
  final FollowersFilter selected;
  final ValueChanged<FollowersFilter> onChanged;
  const _FilterBar({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final segments = <ButtonSegment<FollowersFilter>>[
      const ButtonSegment(
          value: FollowersFilter.all,
          label: Text('Tous'),
          icon: Icon(Icons.group)),
      const ButtonSegment(
          value: FollowersFilter.journalists,
          label: Text('Journalistes'),
          icon: Icon(Icons.verified)),
      const ButtonSegment(
          value: FollowersFilter.banned,
          label: Text('Bannis'),
          icon: Icon(Icons.block)),
    ];
    return SegmentedButton<FollowersFilter>(
      segments: segments,
      showSelectedIcon: false,
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text('$count', style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
class _FollowerTile extends StatelessWidget {
  final UserProfile follower;
  final bool isProcessing;
  final bool isCurrentUser;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;
  final VoidCallback onRemove;
  const _FollowerTile({
    required this.follower,
    required this.isProcessing,
    required this.isCurrentUser,
    required this.searchQuery,
    required this.onTap,
    required this.onFollowToggle,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = TextStyle(
      color: follower.isBanned
          ? cs.error
          : Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w600,
      decoration: follower.isBanned ? TextDecoration.lineThrough : null,
    );
    final subtitle = [
      '@${follower.username}',
      if (follower.organization?.isNotEmpty == true) follower.organization!,
    ].join(' • ');
    final title = _HighlightedText(
      text: follower.name ?? follower.username,
      query: searchQuery,
      baseStyle: titleStyle,
      highlightStyle: titleStyle.copyWith(
          backgroundColor: cs.tertiaryContainer.withOpacity(0.45)),
    );
    final trailing = isCurrentUser
        ? FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
            onPressed: isProcessing ? null : onRemove,
            child: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Retirer'),
          )
        : (follower.isJournalist
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isProcessing
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (follower.isFollowing
                        ? OutlinedButton(
                            key: const ValueKey('abonne'),
                            onPressed: onFollowToggle,
                            child: const Text('Abonné'),
                          )
                        : FilledButton(
                            key: const ValueKey('suivre'),
                            onPressed: onFollowToggle,
                            child: const Text('Suivre'),
                          )),
              )
            : null);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _Avatar(follower: follower),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: title),
                      if (follower.isBanned)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _BannedBadge(),
                        ),
                      if (follower.isJournalist && !follower.isBanned)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _RoleChip(label: 'Journaliste'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
class _Avatar extends StatelessWidget {
  final UserProfile follower;
  final double size;
  const _Avatar({required this.follower, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).colorScheme.outlineVariant;
    final heroTag = 'avatar_${follower.id}';
    return Hero(
      tag: heroTag,
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            shape: CircleBorder(side: BorderSide(color: border)),
          ),
          child: CircleAvatar(
            backgroundImage: follower.avatarUrl != null
                ? NetworkImage(ImageUtils.getAvatarUrl(follower.avatarUrl!))
                : null,
            child: follower.avatarUrl == null ? Icon(Icons.person) : null,
          ),
        ),
      ),
    );
  }
}
class _BannedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Utilisateur banni',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: cs.error.withOpacity(.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: cs.error.withOpacity(.4)),
        ),
        child: Text('BANNI',
            style: TextStyle(
                color: cs.error,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      ),
    );
  }
}
class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(label,
          style: TextStyle(
              color: cs.onSecondaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: cs.errorContainer,
      child: Icon(Icons.delete, color: cs.onErrorContainer),
    );
  }
}
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });
  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final start = lower.indexOf(q);
    if (start < 0) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final end = start + q.length;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: highlightStyle),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
class _SkeletonListSlivers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          height: 12,
                          width: 160,
                          decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                    width: 84,
                    height: 36,
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8))),
              ],
            ),
          );
        },
        childCount: 10,
      ),
    );
  }
}
class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _PinnedHeader({required this.height, required this.child});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) => false;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: overlapsContent ? 1 : 0,
      child: child,
    );
  }
}
class _Debouncer {
  final Duration duration;
  Timer? _timer;
  _Debouncer(this.duration);
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
  void dispose() => _timer?.cancel();
}