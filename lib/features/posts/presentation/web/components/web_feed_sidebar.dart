import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class WebFeedSidebar extends StatelessWidget {
  final Function(String filter)? onFilterChanged;
  const WebFeedSidebar({
    super.key,
    this.onFilterChanged,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(WebTheme.lg),
      children: [
        _buildFiltersSection(context, colorScheme),
        const SizedBox(height: WebTheme.xl),
        _buildTrendingSection(context, colorScheme),
        const SizedBox(height: WebTheme.xl),
        _buildSuggestedUsersSection(context, colorScheme),
      ],
    );
  }
  Widget _buildFiltersSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        _buildFilterItem(context, 'All Posts', Icons.dashboard, true),
        _buildFilterItem(context, 'Articles', Icons.article_outlined, false),
        _buildFilterItem(
            context, 'Shorts', Icons.video_library_outlined, false),
        _buildFilterItem(context, 'Questions', Icons.help_outline, false),
        _buildFilterItem(context, 'Live', Icons.videocam_outlined, false),
      ],
    );
  }
  Widget _buildFilterItem(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      child: InkWell(
        onTap: () => onFilterChanged?.call(label.toLowerCase()),
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.sm,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: WebTheme.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTrendingSection(BuildContext context, ColorScheme colorScheme) {
    final mockTrendingTopics = [
      {'hashtag': '#WebDevelopment', 'count': '1.2K posts'},
      {'hashtag': '#AI', 'count': '890 posts'},
      {'hashtag': '#Flutter', 'count': '654 posts'},
      {'hashtag': '#OpenSource', 'count': '432 posts'},
      {'hashtag': '#TechNews', 'count': '301 posts'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Topics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        ...mockTrendingTopics.map((topic) => _buildTrendingItem(
              context,
              topic['hashtag']!,
              topic['count']!,
            )),
      ],
    );
  }
  Widget _buildTrendingItem(
    BuildContext context,
    String hashtag,
    String count,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
      },
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WebTheme.sm,
          vertical: WebTheme.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hashtag,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.trending_up,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSuggestedUsersSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final mockSuggestedUsers = [
      {'name': 'Sarah Wilson', 'username': '@sarahw', 'isFollowing': true},
      {'name': 'Mike Chen', 'username': '@mikechen', 'isFollowing': true},
      {'name': 'Emily Brown', 'username': '@emilybr', 'isFollowing': false},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested for You',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        ...mockSuggestedUsers.map((user) => _buildSuggestedUser(
              context,
              user['name'] as String,
              user['username'] as String,
              user['isFollowing'] as bool,
            )),
      ],
    );
  }
  Widget _buildSuggestedUser(
    BuildContext context,
    String name,
    String username,
    bool isFollowing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: WebTheme.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: WebTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: WebTheme.md,
                vertical: WebTheme.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}