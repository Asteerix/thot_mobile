import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
enum PoliticalView {
  all,
  extremelyConservative,
  conservative,
  neutral,
  progressive,
  extremelyProgressive;
  String get label {
    switch (this) {
      case PoliticalView.all:
        return 'Tous';
      case PoliticalView.extremelyConservative:
        return 'Très conservateur';
      case PoliticalView.conservative:
        return 'Conservateur';
      case PoliticalView.neutral:
        return 'Neutre';
      case PoliticalView.progressive:
        return 'Progressiste';
      case PoliticalView.extremelyProgressive:
        return 'Très progressiste';
    }
  }
  String get shortLabel {
    switch (this) {
      case PoliticalView.all:
        return 'Tous';
      case PoliticalView.extremelyConservative:
        return 'Très conservateur';
      case PoliticalView.conservative:
        return 'Conservateur';
      case PoliticalView.neutral:
        return 'Neutre';
      case PoliticalView.progressive:
        return 'Progressiste';
      case PoliticalView.extremelyProgressive:
        return 'Très progressiste';
    }
  }
  Color get color {
    switch (this) {
      case PoliticalView.extremelyConservative:
        return AppColors.extremelyConservative;
      case PoliticalView.conservative:
        return AppColors.conservative;
      case PoliticalView.progressive:
        return AppColors.progressive;
      case PoliticalView.extremelyProgressive:
        return AppColors.extremelyProgressive;
      case PoliticalView.neutral:
        return AppColors.neutral;
      case PoliticalView.all:
        return AppColors.neutral;
    }
  }
}
enum ContentCategory {
  politique,
  economie,
  science,
  technologie,
  international,
  societe,
  sport,
  philosophie,
  juridique,
  psychologie;

  String get label {
    switch (this) {
      case ContentCategory.politique:
        return 'Politique';
      case ContentCategory.economie:
        return 'Économie';
      case ContentCategory.science:
        return 'Science';
      case ContentCategory.technologie:
        return 'Technologie';
      case ContentCategory.international:
        return 'International';
      case ContentCategory.societe:
        return 'Société';
      case ContentCategory.sport:
        return 'Sport';
      case ContentCategory.philosophie:
        return 'Philosophie';
      case ContentCategory.juridique:
        return 'Juridique';
      case ContentCategory.psychologie:
        return 'Psychologie';
    }
  }

  IconData get icon {
    switch (this) {
      case ContentCategory.politique:
        return Icons.gavel;
      case ContentCategory.economie:
        return Icons.trending_up;
      case ContentCategory.science:
        return Icons.science;
      case ContentCategory.technologie:
        return Icons.laptop;
      case ContentCategory.international:
        return Icons.public;
      case ContentCategory.societe:
        return Icons.group;
      case ContentCategory.sport:
        return Icons.emoji_events;
      case ContentCategory.philosophie:
        return Icons.psychology;
      case ContentCategory.juridique:
        return Icons.balance;
      case ContentCategory.psychologie:
        return Icons.psychology;
    }
  }
}
class FeedFilters extends StatefulWidget {
  final PostType? selectedType;
  final String? selectedSort;
  final PoliticalView selectedPoliticalView;
  final ContentCategory? selectedCategory;
  final Function(PostType?) onTypeChanged;
  final Function(String?) onSortChanged;
  final Function(PoliticalView?) onPoliticalViewChanged;
  final Function(ContentCategory?) onCategoryChanged;
  const FeedFilters({
    super.key,
    this.selectedType,
    this.selectedSort,
    this.selectedPoliticalView = PoliticalView.all,
    this.selectedCategory,
    required this.onTypeChanged,
    required this.onSortChanged,
    required this.onPoliticalViewChanged,
    required this.onCategoryChanged,
  });
  @override
  State<FeedFilters> createState() => _FeedFiltersState();
}
class _FeedFiltersState extends State<FeedFilters> {
  late int _activeFilterCount;
  @override
  void initState() {
    super.initState();
    _updateActiveFilterCount();
  }
  @override
  void didUpdateWidget(FeedFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateActiveFilterCount();
  }
  void _updateActiveFilterCount() {
    _activeFilterCount = 0;
    if (widget.selectedType != null) _activeFilterCount++;
    if (widget.selectedCategory != null) _activeFilterCount++;
    if (widget.selectedPoliticalView != PoliticalView.all) {
      _activeFilterCount++;
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          physics: const BouncingScrollPhysics(),
          children: [
            _CompactChip(
              label: 'Tous les types',
              isSelected: widget.selectedType == null,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTypeChanged(null);
              },
            ),
            const SizedBox(width: 8),
            _CompactChip(
              label: 'Articles',
              icon: Icons.article,
              isSelected: widget.selectedType == PostType.article,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTypeChanged(widget.selectedType == PostType.article
                    ? null
                    : PostType.article);
              },
            ),
            const SizedBox(width: 8),
            _CompactChip(
              label: 'Vidéos',
              icon: Icons.play_circle,
              isSelected: widget.selectedType == PostType.video,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTypeChanged(widget.selectedType == PostType.video
                    ? null
                    : PostType.video);
              },
            ),
            const SizedBox(width: 8),
            _CompactChip(
              label: 'Podcasts',
              icon: Icons.podcasts,
              isSelected: widget.selectedType == PostType.podcast,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTypeChanged(widget.selectedType == PostType.podcast
                    ? null
                    : PostType.podcast);
              },
            ),
            const SizedBox(width: 8),
            _CompactChip(
              label: 'Questions',
              icon: Icons.help_outline,
              isSelected: widget.selectedType == PostType.question,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTypeChanged(widget.selectedType == PostType.question
                    ? null
                    : PostType.question);
              },
            ),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            _CompactChip(
              label: 'Tous les domaines',
              isSelected: widget.selectedCategory == null,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onCategoryChanged(null);
              },
            ),
            const SizedBox(width: 8),
            ..._buildQuickCategories(),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            _CompactChip(
              label: 'Toutes opinions',
              isSelected: widget.selectedPoliticalView == PoliticalView.all,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPoliticalViewChanged(PoliticalView.all);
              },
            ),
            const SizedBox(width: 8),
            ..._buildPoliticalChips(),
            const SizedBox(width: 12),
            _CompactChip(
              label: 'Plus de filtres',
              icon: Icons.tune,
              isAccent: true,
              badge:
                  _activeFilterCount > 0 ? _activeFilterCount.toString() : null,
              onTap: () => _showAdvancedFilters(context),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildQuickCategories() {
    const quickCategories = [
      ContentCategory.politique,
      ContentCategory.economie,
      ContentCategory.technologie,
      ContentCategory.science,
      ContentCategory.societe,
    ];
    return quickCategories
        .map((category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CompactChip(
                label: category.label,
                icon: category.icon,
                isSelected: widget.selectedCategory == category,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onCategoryChanged(
                      widget.selectedCategory == category ? null : category);
                },
              ),
            ))
        .toList();
  }
  List<Widget> _buildPoliticalChips() {
    const quickViews = [
      PoliticalView.extremelyConservative,
      PoliticalView.conservative,
      PoliticalView.neutral,
      PoliticalView.progressive,
      PoliticalView.extremelyProgressive,
    ];
    return quickViews
        .map((view) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CompactChip(
                label: view.shortLabel,
                color: view.color,
                isSelected: widget.selectedPoliticalView == view,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onPoliticalViewChanged(
                      widget.selectedPoliticalView == view
                          ? PoliticalView.all
                          : view);
                },
              ),
            ))
        .toList();
  }
  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedFiltersSheet(
        selectedType: widget.selectedType,
        selectedCategory: widget.selectedCategory,
        selectedPoliticalView: widget.selectedPoliticalView,
        onApply: (type, category, view) {
          widget.onTypeChanged(type);
          widget.onCategoryChanged(category);
          widget
              .onPoliticalViewChanged(view == PoliticalView.all ? null : view);
          Navigator.pop(context);
        },
      ),
    );
  }
}
class _CompactChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isAccent;
  final Color? color;
  final String? badge;
  final VoidCallback onTap;
  const _CompactChip({
    required this.label,
    this.icon,
    this.isSelected = false,
    this.isAccent = false,
    this.color,
    this.badge,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipColor = isAccent
        ? theme.colorScheme.primary
        : color ?? (isDark ? Colors.white : Colors.black);
    final backgroundColor = isSelected
        ? chipColor.withOpacity(0.12)
        : (isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03));
    final borderColor = isSelected
        ? chipColor.withOpacity(0.5)
        : (isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.08));
    final textColor = isSelected
        ? chipColor
        : (isAccent
            ? theme.colorScheme.primary
            : (isDark ? Colors.white70 : Colors.black87));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: chipColor.withOpacity(0.1),
              highlightColor: chipColor.withOpacity(0.05),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: icon != null ? 10 : 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 15, color: textColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
class _AdvancedFiltersSheet extends StatefulWidget {
  final PostType? selectedType;
  final ContentCategory? selectedCategory;
  final PoliticalView selectedPoliticalView;
  final Function(PostType?, ContentCategory?, PoliticalView) onApply;
  const _AdvancedFiltersSheet({
    required this.selectedType,
    required this.selectedCategory,
    required this.selectedPoliticalView,
    required this.onApply,
  });
  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}
class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PostType? _selectedType;
  late ContentCategory? _selectedCategory;
  late PoliticalView _selectedPoliticalView;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedType = widget.selectedType;
    _selectedCategory = widget.selectedCategory;
    _selectedPoliticalView = widget.selectedPoliticalView;
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filtres avancés',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _selectedCategory = null;
                      _selectedPoliticalView = PoliticalView.all;
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Type'),
              Tab(text: 'Catégories'),
              Tab(text: 'Orientation'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTypeTab(),
                _buildCategoryTab(),
                _buildPoliticalTab(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        _selectedType,
                        _selectedCategory,
                        _selectedPoliticalView,
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTypeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SelectionTile(
          title: 'Tous les types',
          subtitle: 'Afficher tous les types de contenus',
          icon: Icons.all_inclusive,
          isSelected: _selectedType == null,
          onTap: () => setState(() => _selectedType = null),
        ),
        const SizedBox(height: 8),
        _SelectionTile(
          title: 'Articles',
          subtitle: 'Articles écrits et analyses',
          icon: Icons.article,
          isSelected: _selectedType == PostType.article,
          onTap: () => setState(() => _selectedType =
              _selectedType == PostType.article ? null : PostType.article),
        ),
        const SizedBox(height: 8),
        _SelectionTile(
          title: 'Vidéos',
          subtitle: 'Contenus vidéo et reportages',
          icon: Icons.play_circle,
          isSelected: _selectedType == PostType.video,
          onTap: () => setState(() => _selectedType =
              _selectedType == PostType.video ? null : PostType.video),
        ),
        const SizedBox(height: 8),
        _SelectionTile(
          title: 'Podcasts',
          subtitle: 'Émissions audio et interviews',
          icon: Icons.podcasts,
          isSelected: _selectedType == PostType.podcast,
          onTap: () => setState(() => _selectedType =
              _selectedType == PostType.podcast ? null : PostType.podcast),
        ),
        const SizedBox(height: 8),
        _SelectionTile(
          title: 'Questions',
          subtitle: 'Questions et débats',
          icon: Icons.help_outline,
          isSelected: _selectedType == PostType.question,
          onTap: () => setState(() => _selectedType =
              _selectedType == PostType.question ? null : PostType.question),
        ),
      ],
    );
  }
  Widget _buildCategoryTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: ContentCategory.values.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CategoryCard(
            label: 'Toutes',
            icon: Icons.grid_on,
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          );
        }
        final category = ContentCategory.values[index - 1];
        return _CategoryCard(
          label: category.label,
          icon: category.icon,
          isSelected: _selectedCategory == category,
          onTap: () => setState(() => _selectedCategory =
              _selectedCategory == category ? null : category),
        );
      },
    );
  }
  Widget _buildPoliticalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: PoliticalView.values.map((view) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PoliticalCard(
            view: view,
            isSelected: _selectedPoliticalView == view,
            onTap: () => setState(() => _selectedPoliticalView = view),
          ),
        );
      }).toList(),
    );
  }
}
class _SelectionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white12 : Colors.black12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.white12 : Colors.black12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
IconData _getPoliticalIcon(PoliticalView view) {
  switch (view) {
    case PoliticalView.extremelyConservative:
      return Icons.keyboard_double_arrow_left;
    case PoliticalView.conservative:
      return Icons.arrow_back;
    case PoliticalView.neutral:
      return Icons.remove;
    case PoliticalView.progressive:
      return Icons.arrow_forward;
    case PoliticalView.extremelyProgressive:
      return Icons.keyboard_double_arrow_right;
    case PoliticalView.all:
      return Icons.public;
  }
}

class _PoliticalCard extends StatelessWidget {
  final PoliticalView view;
  final bool isSelected;
  final VoidCallback onTap;
  const _PoliticalCard({
    required this.view,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isSelected
          ? view.color.withOpacity(0.1)
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? view.color
                  : (isDark ? Colors.white12 : Colors.black12),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: view.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPoliticalIcon(view),
                  size: 18,
                  color: view.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  view.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? view.color
                        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: view.color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}