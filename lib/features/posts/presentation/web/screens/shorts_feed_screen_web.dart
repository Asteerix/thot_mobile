import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/core/themes/app_colors.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/navigation/route_names.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
import '../../../../../shared/widgets/common/loading_indicator.dart';
import '../../../../../shared/widgets/common/error_view.dart';
import '../../../../../features/posts/domain/entities/short.dart';
import '../../../../posts/data/repositories/post_repository_impl.dart';
class ShortsFeedScreenWeb extends ConsumerStatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const ShortsFeedScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  ConsumerState<ShortsFeedScreenWeb> createState() =>
      _ShortsFeedScreenWebState();
}
class _ShortsFeedScreenWebState extends ConsumerState<ShortsFeedScreenWeb> {
  final PostRepositoryImpl _postRepository =
      ServiceLocator.instance.postRepository;
  final ScrollController _scrollController = ScrollController();
  List<Short> _shorts = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _hasMoreShorts = true;
  int _currentPage = 1;
  String? _error;
  final List<String> _categories = [
    'politique',
    'economie',
    'culture',
    'science',
    'sport',
    'international',
  ];
  @override
  void initState() {
    super.initState();
    _loadShorts();
    _scrollController.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadShorts();
    }
  }
  Future<void> _loadShorts({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMoreShorts)) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _shorts = [];
        _currentPage = 1;
        _hasMoreShorts = true;
      }
    });
    try {
      final response = await _postRepository.getPosts(
        page: _currentPage,
        type: 'short',
        domain: _selectedCategory,
      );
      final shortsData = response['posts'] as List<dynamic>;
      final List<Short> newShorts = [];
      for (var shortJson in shortsData) {
        try {
          final short = Short.fromJson(shortJson as Map<String, dynamic>);
          if (!_shorts.any((s) => s.id == short.id)) {
            newShorts.add(short);
          }
        } catch (e) {
          // Silently skip invalid short
        }
      }
      if (mounted) {
        setState(() {
          _shorts.addAll(newShorts);
          _currentPage++;
          _hasMoreShorts = newShorts.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: _buildContent(context, colorScheme),
    );
  }
  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildHeader(context, colorScheme),
        Expanded(
          child: _buildShortsGrid(context, colorScheme),
        ),
      ],
    );
  }
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isDesktop ? WebTheme.xxl : WebTheme.lg,
        vertical: WebTheme.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Shorts',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Créer un short'),
              ),
            ],
          ),
          const SizedBox(height: WebTheme.lg),
          _buildCategoryFilters(colorScheme),
        ],
      ),
    );
  }
  Widget _buildCategoryFilters(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tous',
            isSelected: _selectedCategory == null,
            onTap: () {
              setState(() => _selectedCategory = null);
              _loadShorts(refresh: true);
            },
            colorScheme: colorScheme,
          ),
          const SizedBox(width: WebTheme.sm),
          ..._categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: WebTheme.sm),
              child: _buildFilterChip(
                label: category[0].toUpperCase() + category.substring(1),
                isSelected: _selectedCategory == category,
                onTap: () {
                  setState(() => _selectedCategory = category);
                  _loadShorts(refresh: true);
                },
                colorScheme: colorScheme,
              ),
            );
          }),
        ],
      ),
    );
  }
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WebTheme.lg,
          vertical: WebTheme.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusLarge),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  Widget _buildShortsGrid(BuildContext context, ColorScheme colorScheme) {
    if (_error != null && _shorts.isEmpty) {
      return ErrorView(
        message: _error!,
        onRetry: () => _loadShorts(refresh: true),
      );
    }
    if (_isLoading && _shorts.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (_shorts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: WebTheme.lg),
            Text(
              'Aucun short disponible',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount;
    if (screenWidth >= WebTheme.largeDesktopBreakpoint) {
      crossAxisCount = 5;
    } else if (screenWidth >= WebTheme.desktopBreakpoint) {
      crossAxisCount = 4;
    } else if (screenWidth >= WebTheme.tabletBreakpoint) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(
        context.isDesktop ? WebTheme.xxl : WebTheme.lg,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: WebTheme.lg,
        mainAxisSpacing: WebTheme.lg,
      ),
      itemCount: _shorts.length + (_hasMoreShorts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _shorts.length) {
          return const Center(child: LoadingIndicator());
        }
        final short = _shorts[index];
        return _buildShortCard(short, colorScheme);
      },
    );
  }
  Widget _buildShortCard(Short short, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {
      },
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(WebTheme.borderRadiusMedium),
                    ),
                    child: Container(
                      color: AppColors.darkBackground,
                      child: Center(
                        child: Image.network(
                          short.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: AppColors.textPrimary.withOpacity(0.8),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.darkBackground.withOpacity(0.5),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          size: 56,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (short.metadata?['duration'] != null)
                    Positioned(
                      bottom: WebTheme.sm,
                      right: WebTheme.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WebTheme.sm,
                          vertical: WebTheme.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(
                            WebTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Text(
                          '${short.metadata!['duration']}s',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WebTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    short.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: WebTheme.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: WebTheme.xs),
                      Text(
                        '${short.stats.views} vues',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: WebTheme.sm),
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: WebTheme.xs),
                      Text(
                        '${short.stats.likes}',
                        style: TextStyle(
                          fontSize: 12,
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