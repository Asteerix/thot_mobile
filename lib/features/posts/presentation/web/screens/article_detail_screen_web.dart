import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class ArticleDetailScreenWeb extends StatefulWidget {
  final String postId;
  final String currentRoute;
  final Function(String route) onNavigate;
  const ArticleDetailScreenWeb({
    super.key,
    required this.postId,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<ArticleDetailScreenWeb> createState() => _ArticleDetailScreenWebState();
}
class _ArticleDetailScreenWebState extends State<ArticleDetailScreenWeb> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      showRightSidebar: context.isDesktop,
      rightSidebar: _buildTableOfContents(context, colorScheme),
      body: WebMultiColumnLayout(
        content: _buildArticleContent(context, colorScheme),
        contentMaxWidth: 800,
      ),
    );
  }
  Widget _buildArticleContent(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: WebTheme.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumbs(context, colorScheme),
          const SizedBox(height: WebTheme.xl),
          Text(
            'The Future of Web Development',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: WebTheme.md),
          Row(
            children: [
              CircleAvatar(
                radius: WebTheme.avatarSizeSmall / 2,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                  size: WebTheme.avatarSizeSmall / 2,
                ),
              ),
              const SizedBox(width: WebTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Published on Jan 15, 2024 · 10 min read',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.person_add, size: 18),
                label: const Text('Follow'),
              ),
            ],
          ),
          const SizedBox(height: WebTheme.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
            child: Image.network(
              'https://via.placeholder.com/800x400',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          Text(
            'Introduction',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.md),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris...',
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          Text(
            'The Evolution of Web Technologies',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.md),
          Text(
            'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident...',
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          Divider(color: colorScheme.outline),
          const SizedBox(height: WebTheme.md),
          Row(
            children: [
              _buildActionButton(
                  context, Icons.favorite, '125', colorScheme),
              const SizedBox(width: WebTheme.lg),
              _buildActionButton(
                  context, Icons.comment, '43', colorScheme),
              const SizedBox(width: WebTheme.lg),
              _buildActionButton(
                  context, Icons.share, '18', colorScheme),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.bookmark),
                onPressed: () {},
                tooltip: 'Save',
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildBreadcrumbs(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        InkWell(
          onTap: () => widget.onNavigate('/'),
          child: Text(
            'Home',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WebTheme.xs),
          child: Icon(
            Icons.chevron_right,
            size: 16,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        InkWell(
          onTap: () => widget.onNavigate('/'),
          child: Text(
            'Articles',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WebTheme.xs),
          child: Icon(
            Icons.chevron_right,
            size: 16,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          'Current Article',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  Widget _buildTableOfContents(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(WebTheme.lg),
      children: [
        Text(
          'Table of Contents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        _buildTocItem(context, 'Introduction', true),
        _buildTocItem(context, 'The Evolution of Web Technologies', false),
        _buildTocItem(context, 'Modern Frameworks', false),
        _buildTocItem(context, 'Performance Optimization', false),
        _buildTocItem(context, 'Conclusion', false),
        const SizedBox(height: WebTheme.xl),
        Divider(color: colorScheme.outline),
        const SizedBox(height: WebTheme.lg),
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        Wrap(
          spacing: WebTheme.sm,
          runSpacing: WebTheme.sm,
          children: [
            _buildTag(context, 'WebDev'),
            _buildTag(context, 'Technology'),
            _buildTag(context, 'Programming'),
          ],
        ),
      ],
    );
  }
  Widget _buildTocItem(BuildContext context, String title, bool isActive) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WebTheme.sm,
          vertical: WebTheme.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  Widget _buildTag(BuildContext context, String tag) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(
        tag,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelPadding: const EdgeInsets.symmetric(horizontal: WebTheme.sm),
      visualDensity: VisualDensity.compact,
    );
  }
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String count,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: WebTheme.xs),
            Text(
              count,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}