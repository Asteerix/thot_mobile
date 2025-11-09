import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class SearchScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const SearchScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<SearchScreenWeb> createState() => _SearchScreenWebState();
}
enum SearchFilter { all, posts, articles, shorts, users, tags }
class _SearchScreenWebState extends State<SearchScreenWeb> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SearchFilter _selectedFilter = SearchFilter.all;
  bool _isLoading = false;
  final List<String> _recentSearches = [
    'Flutter development',
    'Web design',
    'UI/UX trends',
  ];
  final List<String> _trendingTags = [
    '#flutter',
    '#webdev',
    '#design',
    '#programming',
    '#ai',
  ];
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });
    try {
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: ResponsiveLayout(
        builder: (context, deviceType) {
          if (deviceType == DeviceType.mobile) {
            return _buildMobileLayout(context, colorScheme);
          }
          return _buildDesktopLayout(context, colorScheme, deviceType);
        },
      ),
    );
  }
  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(WebTheme.md),
          child: Column(
            children: [
              _buildSearchBar(context, colorScheme),
              const SizedBox(height: WebTheme.md),
              _buildFilterChips(context, colorScheme),
            ],
          ),
        ),
        Expanded(
          child: _buildSearchResults(context, colorScheme, DeviceType.mobile),
        ),
      ],
    );
  }
  Widget _buildDesktopLayout(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    final isLargeScreen = deviceType == DeviceType.largeDesktop;
    final maxWidth = isLargeScreen ? 1600.0 : WebTheme.maxContentWidth;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(
          isLargeScreen ? WebTheme.xxxl : WebTheme.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.xl),
            _buildAdvancedSearchBar(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildFilterChips(context, colorScheme),
            const SizedBox(height: WebTheme.xl),
            Expanded(
              child: _buildSearchResults(context, colorScheme, deviceType),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: WebTheme.inputHeightLarge,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search posts, articles, users...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(Icons.search, size: 28, color: colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WebTheme.lg,
            vertical: WebTheme.md,
          ),
        ),
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
  Widget _buildAdvancedSearchBar(
      BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search posts, articles, users, tags...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  prefixIcon:
                      Icon(Icons.search, size: 28, color: colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: WebTheme.md,
                    vertical: WebTheme.md,
                  ),
                ),
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: WebTheme.lg),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text),
              icon: Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: WebTheme.xl,
                  vertical: WebTheme.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFilterChips(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SearchFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: WebTheme.sm),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget _buildSearchResults(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    if (_searchQuery.isEmpty) {
      return _buildSuggestions(context, colorScheme, deviceType);
    }
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    return _buildResultsGrid(context, colorScheme, deviceType);
  }
  Widget _buildSuggestions(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        deviceType == DeviceType.mobile ? WebTheme.md : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.md),
            ..._recentSearches.map((search) => ListTile(
                  leading: Icon(Icons.history,
                      color: colorScheme.onSurface.withOpacity(0.6)),
                  title: Text(
                    search,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                    onPressed: () {
                    },
                  ),
                  onTap: () => _selectSuggestion(search),
                )),
            const SizedBox(height: WebTheme.xl),
          ],
          Text(
            'Trending Tags',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.md),
          Wrap(
            spacing: WebTheme.sm,
            runSpacing: WebTheme.sm,
            children: _trendingTags.map((tag) {
              return ActionChip(
                label: Text(tag),
                backgroundColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: () => _selectSuggestion(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: WebTheme.xl),
          Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.md),
          _buildPopularSearchCard(
            context,
            colorScheme,
            'Web Development',
            '2.5K posts',
            Icons.trending_up,
            AppColors.blue,
          ),
          const SizedBox(height: WebTheme.sm),
          _buildPopularSearchCard(
            context,
            colorScheme,
            'UI Design',
            '1.8K posts',
            Icons.trending_up,
            AppColors.purple,
          ),
          const SizedBox(height: WebTheme.sm),
          _buildPopularSearchCard(
            context,
            colorScheme,
            'Machine Learning',
            '1.2K posts',
            Icons.trending_up,
            AppColors.success
          ),
        ],
      ),
    );
  }
  Widget _buildPopularSearchCard(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String count,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        onTap: () => _selectSuggestion(title),
        child: Padding(
          padding: const EdgeInsets.all(WebTheme.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(WebTheme.sm),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(WebTheme.borderRadiusSmall),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: WebTheme.md),
              Expanded(
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
                    ),
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
              Icon(
                Icons.chevron_right,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildResultsGrid(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    final results = List.generate(12, (index) => index);
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: WebTheme.md),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: WebTheme.sm),
            Text(
              'Try different keywords or filters',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }
    return ResponsiveGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: deviceType == DeviceType.largeDesktop ? 4 : 3,
      childAspectRatio: 1.3,
      children: results.map((index) {
        return _buildResultCard(context, colorScheme, index);
      }).toList(),
    );
  }
  Widget _buildResultCard(
    BuildContext context,
    ColorScheme colorScheme,
    int index,
  ) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: colorScheme.primaryContainer,
                child: Center(
                  child: Icon(
                    _getFilterIcon(_selectedFilter),
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
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
                    'Result ${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WebTheme.xs),
                  Text(
                    _getFilterLabel(_selectedFilter),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _getFilterLabel(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.all:
        return 'All';
      case SearchFilter.posts:
        return 'Posts';
      case SearchFilter.articles:
        return 'Articles';
      case SearchFilter.shorts:
        return 'Shorts';
      case SearchFilter.users:
        return 'Users';
      case SearchFilter.tags:
        return 'Tags';
    }
  }
  IconData _getFilterIcon(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.all:
        return Icons.grid_on;
      case SearchFilter.posts:
        return Icons.note_add;
      case SearchFilter.articles:
        return Icons.article;
      case SearchFilter.shorts:
        return Icons.videocam;
      case SearchFilter.users:
        return Icons.group;
      case SearchFilter.tags:
        return Icons.tag;
    }
  }
}