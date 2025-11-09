import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class ExploreScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const ExploreScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<ExploreScreenWeb> createState() => _ExploreScreenWebState();
}
class _ExploreScreenWebState extends State<ExploreScreenWeb> {
  String _selectedCategory = 'all';
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
          padding: const EdgeInsets.all(WebTheme.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: WebTheme.lg),
              _buildCategories(context, colorScheme),
              const SizedBox(height: WebTheme.xl),
              Expanded(
                child: _buildExploreGrid(context, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildCategories(BuildContext context, ColorScheme colorScheme) {
    final categories = [
      {'label': 'All', 'value': 'all', 'icon': Icons.dashboard},
      {'label': 'Trending', 'value': 'trending', 'icon': Icons.trending_up},
      {'label': 'Technology', 'value': 'tech', 'icon': Icons.laptop},
      {'label': 'Science', 'value': 'science', 'icon': Icons.flask},
      {'label': 'Arts', 'value': 'arts', 'icon': Icons.palette},
      {'label': 'Business', 'value': 'business', 'icon': Icons.business},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category['value'];
          return Padding(
            padding: const EdgeInsets.only(right: WebTheme.md),
            child: FilterChip(
              avatar: Icon(
                category['icon'] as IconData,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
              label: Text(
                category['label'] as String,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(
                      () => _selectedCategory = category['value'] as String);
                }
              },
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildExploreGrid(BuildContext context, ColorScheme colorScheme) {
    return ResponsiveGrid(
      desktopColumns: 3,
      tabletColumns: 2,
      mobileColumns: 1,
      childAspectRatio: 0.8,
      children: List.generate(
        12,
        (index) => _buildExploreCard(
          context,
          colorScheme,
          'Explore Item ${index + 1}',
          'Category ${(index % 4) + 1}',
          '${(index + 1) * 10}K views',
        ),
      ),
    );
  }
  Widget _buildExploreCard(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String category,
    String views,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: colorScheme.primaryContainer,
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WebTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WebTheme.sm),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          category,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: WebTheme.sm,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        views,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}