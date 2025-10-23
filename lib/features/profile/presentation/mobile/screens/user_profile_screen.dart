import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/profile/presentation/shared/widgets/badges.dart';
import 'package:thot/core/constants/app_constants.dart';
import 'package:thot/features/media/utils/url_helper.dart';
import 'package:thot/features/admin/presentation/shared/widgets/admin_moderation_actions.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/features/admin/presentation/shared/widgets/banned_user_overlay.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class UserProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  const UserProfileScreen({
    super.key,
    required this.userProfile,
  });
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}
class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  ImageProvider _getAvatarImage() {
    if (widget.userProfile.avatarUrl != null) {
      final url = UrlHelper.buildMediaUrl(widget.userProfile.avatarUrl);
      return NetworkImage(url ?? 'https://via.placeholder.com/150');
    }
    return AssetImage(widget.userProfile.isJournalist
        ? UIConstants.defaultJournalistAvatarPath
        : UIConstants.defaultUserAvatarPath);
  }
  @override
  Widget build(BuildContext context) {
    if (widget.userProfile.isBanned) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            widget.userProfile.username,
            style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Tailwind',
                decoration: TextDecoration.lineThrough,
                color: AppColors.red),
          ),
        ),
        body: BannedUserOverlay(
          banReason: widget.userProfile.banReason,
          bannedAt: widget.userProfile.bannedAt,
          child: const SizedBox.shrink(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Text(
              widget.userProfile.username,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Tailwind',
              ),
            ),
            if (widget.userProfile.isVerified) ...[
              const SizedBox(width: 4),
              const VerificationBadge(),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptionsBottomSheet(context);
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _getAvatarImage(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.userProfile.name != null)
                          Text(
                            widget.userProfile.name!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Tailwind',
                            ),
                          ),
                        if (widget.userProfile.isJournalist &&
                            widget.userProfile.journalistRole != null)
                          Text(
                            widget.userProfile.journalistRole!,
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 14,
                              fontFamily: 'Tailwind',
                            ),
                          ),
                        if (widget.userProfile.bio != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.userProfile.bio!,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Tailwind',
                            ),
                          ),
                        ],
                        if (widget.userProfile.isJournalist &&
                            widget.userProfile.organization != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.business,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                widget.userProfile.organization!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 14,
                                  fontFamily: 'Tailwind',
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      widget.userProfile.isFollowing
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                          : AppColors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  widget.userProfile.isFollowing
                                      ? 'Abonné'
                                      : "S'abonner",
                                  style: const TextStyle(
                                    fontFamily: 'Tailwind',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            if (authProvider.isAdmin) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: AdminModerationActions(
                                  userId: widget.userProfile.id,
                                  onBanned: () {
                                    SafeNavigation.pop(context);
                                  },
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  if (widget.userProfile.highlightedStories.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: widget.userProfile.highlightedStories.length,
                        itemBuilder: (context, index) {
                          return _buildStoryHighlight(
                              widget.userProfile.highlightedStories[index]);
                        },
                      ),
                    ),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.play_circle_outline)),
                    Tab(icon: Icon(Icons.format_quote)),
                  ],
                ),
              ),
            ),
          ];
        },
        body: IndexedStack(
          index: _tabController.index,
          children: [
            _buildGridView(),
            _buildGridView(),
            _buildGridView(),
          ],
        ),
      ),
    );
  }
  Widget _buildStoryHighlight(String story) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              image: DecorationImage(
                image: NetworkImage(UrlHelper.buildMediaUrl(story) ??
                    'https://via.placeholder.com/150'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Story',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Tailwind',
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(
            child: Icon(Icons.photo),
          ),
        );
      },
    );
  }
  void _showOptionsBottomSheet(BuildContext context) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Theme.of(context).colorScheme.onSurface,
          child: Wrap(
            children: [
              if (!widget.userProfile.isBlocked) ...[
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.red),
                  title: const Text(
                    'Bloquer',
                    style: TextStyle(
                      color: AppColors.red,
                      fontFamily: 'Tailwind',
                    ),
                  ),
                  onTap: () {
                    SafeNavigation.pop(context);
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.flag,
                    color: Theme.of(context).colorScheme.onSurface),
                title: Text(
                  'Signaler',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontFamily: 'Tailwind',
                  ),
                ),
                onTap: () {
                  SafeNavigation.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
    return Container(
      color: Theme.of(context).colorScheme.onSurface,
      child: _tabBar,
    );
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}