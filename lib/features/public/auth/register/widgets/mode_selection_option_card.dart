import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ModeSelectionOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWebStyle;
  const ModeSelectionOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.isWebStyle = false,
  });
  @override
  Widget build(BuildContext context) {
    if (isWebStyle) {
      return _WebOptionCard(
        icon: icon,
        title: title,
        description: description,
        isSelected: isSelected,
        onTap: onTap,
      );
    }
    return _MobileOptionCard(
      icon: icon,
      title: title,
      description: description,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

class _MobileOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  const _MobileOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surface.withOpacity(0.2)
              : theme.colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.surface.withOpacity(0.5)
                : theme.colorScheme.surface.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.surface.withOpacity(0.25)
                    : theme.colorScheme.surface.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.surface,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.surface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.surface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebOptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  const _WebOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_WebOptionCard> createState() => _WebOptionCardState();
}

class _WebOptionCardState extends State<_WebOptionCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? colorScheme.primary
                  : _isHovered
                      ? colorScheme.outline
                      : colorScheme.outlineVariant,
              width: widget.isSelected ? 3 : 2,
            ),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: widget.isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
