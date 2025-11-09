import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class EditorToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onHeading;
  final VoidCallback onLink;
  final VoidCallback onImage;
  final VoidCallback onQuote;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;
  const EditorToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onHeading,
    required this.onLink,
    required this.onImage,
    required this.onQuote,
    required this.onBulletList,
    required this.onNumberedList,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WebTheme.md,
        vertical: WebTheme.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Wrap(
        spacing: WebTheme.sm,
        runSpacing: WebTheme.sm,
        children: [
          _buildToolbarButton(
            context: context,
            icon: Icons.format_bold,
            tooltip: 'Gras (Ctrl+B)',
            onPressed: onBold,
            colorScheme: colorScheme,
          ),
          _buildToolbarButton(
            context: context,
            icon: Icons.format_italic,
            tooltip: 'Italique (Ctrl+I)',
            onPressed: onItalic,
            colorScheme: colorScheme,
          ),
          _buildDivider(colorScheme),
          _buildToolbarButton(
            context: context,
            icon: Icons.title,
            tooltip: 'Titre',
            onPressed: onHeading,
            colorScheme: colorScheme,
          ),
          _buildDivider(colorScheme),
          _buildToolbarButton(
            context: context,
            icon: Icons.link,
            tooltip: 'Insérer un lien',
            onPressed: onLink,
            colorScheme: colorScheme,
          ),
          _buildToolbarButton(
            context: context,
            icon: Icons.image,
            tooltip: 'Insérer une image',
            onPressed: onImage,
            colorScheme: colorScheme,
          ),
          _buildDivider(colorScheme),
          _buildToolbarButton(
            context: context,
            icon: Icons.format_quote,
            tooltip: 'Citation',
            onPressed: onQuote,
            colorScheme: colorScheme,
          ),
          _buildDivider(colorScheme),
          _buildToolbarButton(
            context: context,
            icon: Icons.list,
            tooltip: 'Liste à puces',
            onPressed: onBulletList,
            colorScheme: colorScheme,
          ),
          _buildToolbarButton(
            context: context,
            icon: Icons.format_list_numbered,
            tooltip: 'Liste numérotée',
            onPressed: onNumberedList,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
  Widget _buildToolbarButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        child: Container(
          padding: const EdgeInsets.all(WebTheme.sm),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: WebTheme.xs),
      color: colorScheme.outline.withOpacity(0.3),
    );
  }
}