import 'package:flutter/material.dart';
class SearchFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  const SearchFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? (isDark ? Colors.white : Colors.black);
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
        : (isDark ? Colors.white70 : Colors.black87);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
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
                color: textColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
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
                    color: filter.color,
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
  final Color? color;
  const SearchFilterChipData({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });
}