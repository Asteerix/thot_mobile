import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/profile/utils/follow_utils.dart';
import 'package:thot/shared/widgets/common/loading_indicator.dart';
import 'package:thot/shared/widgets/common/error_view.dart';
import 'package:thot/shared/widgets/common/empty_state.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class FollowingScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;
  const FollowingScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });
  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}
class _FollowingScreenState extends State<FollowingScreen> {
  final _profileRepository = ServiceLocator.instance.profileRepository;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 250);
  List<UserProfile>? _allFollowing;
  List<UserProfile>? _filteredFollowing;
  bool _isLoading = true;
  String? _error;
  final Map<String, bool> _processingIds = <String, bool>{};
  String _searchQuery = '';
  bool _showAppBarShadow = false;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFollowing();
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }
  void _onScroll() {
    final bool newShadow = _scrollController.positions.isNotEmpty &&
        _scrollController.offset > 1.0;
    if (newShadow != _showAppBarShadow && mounted) {
      setState(() => _showAppBarShadow = newShadow);
    }
    if (FocusManager.instance.primaryFocus?.hasFocus == true) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
  Future<void> _loadFollowing() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _profileRepository.getFollowing(widget.userId);
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (following) {
          setState(() {
            _allFollowing = following;
            _filteredFollowing = following;
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
  Future<void> _handleFollowToggle(UserProfile user) async {
    if (!mounted || _processingIds[user.id] == true) return;
    HapticFeedback.selectionClick();
    setState(() => _processingIds[user.id] = true);
    try {
      await FollowUtils.handleFollowAction(
        user,
        (updatedUser) {
          if (!mounted) return;
          setState(() {
            if (!updatedUser.isFollowing) {
              _allFollowing?.removeWhere((f) => f.id == user.id);
              _filteredFollowing?.removeWhere((f) => f.id == user.id);
            } else {
              final int iAll =
                  _allFollowing?.indexWhere((f) => f.id == user.id) ?? -1;
              if (iAll >= 0) _allFollowing![iAll] = updatedUser;
              final int iFilt =
                  _filteredFollowing?.indexWhere((f) => f.id == user.id) ?? -1;
              if (iFilt >= 0) _filteredFollowing![iFilt] = updatedUser;
            }
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
  void _navigateToProfile(UserProfile user) {
    if (!mounted) return;
    context.pushNamed(
      RouteNames.profile,
      extra: {'userId': user.id, 'forceReload': true},
    );
  }
  void _handleSearch(String query) {
    _debouncer.run(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = query.trim();
        if (_searchQuery.isEmpty) {
          _filteredFollowing = _allFollowing;
        } else {
          final q = _searchQuery.toLowerCase();
          _filteredFollowing = _allFollowing?.where((user) {
            final displayName = (user.name ?? user.username).toLowerCase();
            final o = user.organization?.toLowerCase() ?? '';
            return displayName.contains(q) || o.contains(q);
          }).toList();
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Scrollbar(
          controller: _scrollController,
          interactive: true,
          child: RefreshIndicator.adaptive(
            onRefresh: _loadFollowing,
            edgeOffset: 80,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: cs.surface,
                  elevation: _showAppBarShadow ? 1.0 : 0.0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => SafeNavigation.pop(context),
                    tooltip: 'Retour',
                  ),
                  title: Text(
                    'Abonnements',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  centerTitle: false,
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchHeaderDelegate(
                    height: 64,
                    child: _SearchField(
                      controller: _searchController,
                      onChanged: _handleSearch,
                      onClear: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                      placeholder: 'Rechercher des journalistes ou rédactions…',
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: LoadingIndicator()),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(error: _error!, onRetry: _loadFollowing),
                  )
                else if (_filteredFollowing == null ||
                    _filteredFollowing!.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'Aucun abonnement',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Aucun résultat pour "$_searchQuery"'
                          : widget.isCurrentUser
                              ? 'Vous n\'êtes abonné à aucun journaliste'
                              : 'Aucun abonnement disponible',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _filteredFollowing![index];
                        final isProcessing = _processingIds[user.id] == true;
                        return _FollowingTile(
                          key: ValueKey('following_${user.id}'),
                          user: user,
                          isLast: index == _filteredFollowing!.length - 1,
                          isProcessing: isProcessing,
                          searchQuery: _searchQuery,
                          onOpen: () => _navigateToProfile(user),
                          onToggle: () => _handleFollowToggle(user),
                        );
                      },
                      childCount: _filteredFollowing!.length,
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
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String placeholder;
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.placeholder,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 14,
          ),
          prefixIcon:
              Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    key: const ValueKey('clear'),
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: cs.onSurfaceVariant,
                    tooltip: 'Effacer la recherche',
                  ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
class _FollowingTile extends StatelessWidget {
  final UserProfile user;
  final bool isProcessing;
  final bool isLast;
  final String searchQuery;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  const _FollowingTile({
    super.key,
    required this.user,
    required this.isProcessing,
    required this.isLast,
    required this.searchQuery,
    required this.onOpen,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    final subStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      height: 1.2,
    );
    return Semantics(
      button: false,
      label: 'Utilisateur ${user.name ?? user.username}',
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Hero(
                tag: 'avatar_${user.id}',
                child: _Avatar(url: user.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightedText(
                        user.name ?? user.username, searchQuery, titleStyle),
                    const SizedBox(height: 2),
                    _secondaryLine(user, subStyle, searchQuery),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _FollowButton(
                isFollowing: user.isFollowing,
                isProcessing: isProcessing,
                onPressed: onToggle,
              ),
            ],
          ),
        ),
      ),
    ).withDivider(show: !isLast);
  }
  Widget _secondaryLine(UserProfile u, TextStyle? style, String q) {
    final handle = '@${u.username}';
    final org = u.organization?.trim();
    final text = (org == null || org.isEmpty) ? handle : '$handle · $org';
    return _highlightedText(text, q, style);
  }
  Widget _highlightedText(String text, String query, TextStyle? style) {
    if (query.isEmpty) {
      return Text(text,
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final i = lower.indexOf(q);
    if (i < 0) {
      return Text(text,
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
              text: text.substring(i, i + q.length),
              style: style?.copyWith(fontWeight: FontWeight.w800)),
          TextSpan(text: text.substring(i + q.length)),
        ],
      ),
    );
  }
}
class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = 22.0;
    if (url == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.person, color: cs.onSurfaceVariant),
      );
    }
    final resolved = ImageUtils.getAvatarUrl(url!);
    return ClipOval(
      child: Image.network(
        resolved,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: (radius * 2).toInt() * 3,
        cacheHeight: (radius * 2).toInt() * 3,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(Icons.person, color: cs.onSurfaceVariant),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return CircleAvatar(
              radius: radius, backgroundColor: cs.surfaceContainerHighest);
        },
      ),
    );
  }
}
class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isProcessing;
  final VoidCallback onPressed;
  const _FollowButton({
    required this.isFollowing,
    required this.isProcessing,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool showPrimary = !isFollowing;
    final ButtonStyle style = TextButton.styleFrom(
      backgroundColor: showPrimary ? cs.primary : cs.surfaceContainerHighest,
      foregroundColor: showPrimary ? cs.onPrimary : cs.onSurfaceVariant,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Semantics(
      button: true,
      label: isFollowing ? 'Abonné' : 'Suivre',
      child: TextButton(
        onPressed: isProcessing
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed();
              },
        style: style,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: isProcessing
              ? SizedBox(
                  key: const ValueKey('spinner'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(cs.onSurfaceVariant)),
                )
              : Row(
                  key: ValueKey(isFollowing ? 'abonne' : 'suivre'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isFollowing ? Icons.check_rounded : Icons.add_rounded,
                        size: 18),
                    const SizedBox(width: 6),
                    Text(isFollowing ? 'Abonné' : 'Suivre',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }
}
class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _SearchHeaderDelegate({required this.height, required this.child});
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
class _Debouncer {
  final int milliseconds;
  Timer? _timer;
  _Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
  void dispose() => _timer?.cancel();
}
extension _DividerX on Widget {
  Widget withDivider({required bool show}) {
    if (!show) return this;
    return Column(
      children: [
        this,
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }
}