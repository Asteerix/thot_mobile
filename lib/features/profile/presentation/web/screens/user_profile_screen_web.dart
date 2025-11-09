import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../features/profile/domain/entities/user_profile.dart';
import '../../../../../features/media/utils/url_helper.dart';
class UserProfileScreenWeb extends ConsumerStatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  final UserProfile userProfile;
  const UserProfileScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.userProfile,
  });
  @override
  ConsumerState<UserProfileScreenWeb> createState() =>
      _UserProfileScreenWebState();
}
class _UserProfileScreenWebState extends ConsumerState<UserProfileScreenWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = widget.userProfile;
    if (user.isBanned) {
      return WebScaffold(
        currentRoute: widget.currentRoute,
        onNavigate: widget.onNavigate,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(WebTheme.xxl),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(WebTheme.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 64, color: AppColors.error),
                    const SizedBox(height: WebTheme.lg),
                    Text(
                      'Compte banni',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: WebTheme.md),
                    if (user.banReason != null)
                      Text(
                        user.banReason!,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: WebTheme.xl),
                    FilledButton(
                      onPressed: () => widget.onNavigate('/feed'),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => widget.onNavigate('/feed'),
              ),
              const SizedBox(height: WebTheme.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: user.profilePicture != null
                        ? NetworkImage(
                            UrlHelper.getImageUrl(user.profilePicture!))
                        : null,
                    child: user.profilePicture == null
                        ? Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const SizedBox(width: WebTheme.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name ?? user.username,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user.isVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.verified,
                                    size: 24, color: AppColors.blue),
                              ),
                          ],
                        ),
                        const SizedBox(height: WebTheme.xs),
                        if (user.username.isNotEmpty && user.name != user.username)
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (user.bio != null) ...[
                          const SizedBox(height: WebTheme.md),
                          Text(
                            user.bio!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: WebTheme.lg),
                        Row(
                          children: [
                            _buildStat(
                              context,
                              'Posts',
                              user.postsCount?.toString() ?? '0',
                            ),
                            const SizedBox(width: WebTheme.xl),
                            InkWell(
                              onTap: () => widget
                                  .onNavigate('/profile/${user.id}/followers'),
                              child: _buildStat(
                                context,
                                'Abonnés',
                                user.followersCount?.toString() ?? '0',
                              ),
                            ),
                            const SizedBox(width: WebTheme.xl),
                            InkWell(
                              onTap: () => widget
                                  .onNavigate('/profile/${user.id}/following'),
                              child: _buildStat(
                                context,
                                'Abonnements',
                                user.followingCount?.toString() ?? '0',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: WebTheme.lg),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.person_add),
                          label: const Text('Suivre'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WebTheme.xxl),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Articles'),
                  Tab(text: 'Shorts'),
                ],
              ),
              const SizedBox(height: WebTheme.lg),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmptyState(context, 'Aucun post'),
                    _buildEmptyState(context, 'Aucun article'),
                    _buildEmptyState(context, 'Aucun short'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: WebTheme.md),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}