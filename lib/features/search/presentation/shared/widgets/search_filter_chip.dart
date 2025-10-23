import 'package:flutter/material.dart';
class SearchFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  const SearchFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isDark ? Colors.black : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : (isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7)),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class SearchFilterBar extends StatelessWidget {
  final List<SearchFilterChipData> filters;
  final String? selectedFilter;
  final Function(String) onFilterSelected;
  const SearchFilterBar({
    super.key,
    required this.filters,
    this.selectedFilter,
    required this.onFilterSelected,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters
            .map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SearchFilterChip(
                    label: filter.label,
                    icon: filter.icon,
                    isSelected: selectedFilter == filter.value,
                    onTap: () => onFilterSelected(filter.value),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
class SearchFilterChipData {
  final String label;
  final String value;
  final IconData? icon;
  const SearchFilterChipData({
    required this.label,
    required this.value,
    this.icon,
  });
}