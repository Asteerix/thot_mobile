import 'package:flutter/material.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:thot/core/config/app_config.dart';

// ============================================================================
// LAYOUT PRINCIPAL - ÉCRANS DE CRÉATION DE CONTENU
// ============================================================================
// Utilisé par: new_article_screen.dart, new_video_screen.dart, new_podcast_screen.dart
// Fournit une structure cohérente pour tous les écrans de création

/// Layout unifié pour les écrans de création de contenu
///
/// Offre une interface cohérente avec:
/// - AppBar personnalisée avec titre et sous-titre
/// - Bouton d'aperçu optionnel
/// - Bottom bar avec bouton de soumission
/// - Support du mode sombre/clair
class CreationScreenLayout extends StatelessWidget {
  /// Titre principal affiché dans l'AppBar
  final String title;

  /// Sous-titre optionnel (ex: domaine, durée)
  final String? subtitle;

  /// Contenu principal de l'écran
  final Widget child;

  /// Callback pour le bouton d'aperçu (optionnel)
  final VoidCallback? onPreview;

  /// Callback pour le bouton de soumission
  final VoidCallback? onSubmit;

  /// Indique si la soumission est en cours
  final bool isSubmitting;

  /// Indique si la soumission est possible
  final bool canSubmit;

  /// Label du bouton de soumission
  final String submitLabel;

  /// Contrôleur de scroll optionnel
  final ScrollController? scrollController;

  const CreationScreenLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onPreview,
    required this.onSubmit,
    this.isSubmitting = false,
    this.canSubmit = true,
    this.submitLabel = 'Publier',
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(bgColor),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(false),
    );
  }

  // --------------------------------------------------------------------------
  // AppBar avec titre et bouton fermer
  // --------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(Color bgColor) {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: _buildAppBarTitle(),
      actions: onPreview != null ? [_buildPreviewIconButton()] : null,
    );
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewIconButton() {
    return IconButton(
      icon: Icon(Icons.visibility, color: Colors.white),
      onPressed: onPreview,
      tooltip: 'Aperçu',
    );
  }

  // --------------------------------------------------------------------------
  // Corps de l'écran avec scroll
  // --------------------------------------------------------------------------

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(16.0),
      child: child,
    );
  }

  // --------------------------------------------------------------------------
  // Barre inférieure avec boutons d'action
  // --------------------------------------------------------------------------

  Widget _buildBottomBar(bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: _buildBottomBarDecoration(),
        child: Row(
          children: [
            if (onPreview != null) ...[
              Expanded(child: _buildPreviewButton()),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: onPreview != null ? 1 : 2,
              child: _buildSubmitButton(),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBottomBarDecoration() {
    return BoxDecoration(
      color: Colors.black,
      border: Border(
        top: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bouton d'aperçu (optionnel)
  // --------------------------------------------------------------------------

  Widget _buildPreviewButton() {
    return _ActionButton(
      onTap: onPreview,
      backgroundColor: Colors.transparent,
      borderColor: Colors.white.withOpacity(0.1),
      icon: Icons.visibility,
      label: 'Aperçu',
      textColor: Colors.white,
    );
  }

  // --------------------------------------------------------------------------
  // Bouton de soumission
  // --------------------------------------------------------------------------

  Widget _buildSubmitButton() {
    final isEnabled = canSubmit && !isSubmitting;

    return _ActionButton(
      onTap: isEnabled ? onSubmit : null,
      backgroundColor: isEnabled ? Colors.white : Colors.white.withOpacity(0.3),
      icon: isSubmitting ? null : Icons.check,
      label: submitLabel,
      textColor: Colors.black,
      isLoading: isSubmitting,
    );
  }
}

// ============================================================================
// COMPOSANT INTERNE - BOUTON D'ACTION
// ============================================================================

/// Bouton d'action réutilisable pour la bottom bar
class _ActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? icon;
  final String label;
  final Color textColor;
  final bool isLoading;

  const _ActionButton({
    required this.onTap,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    required this.label,
    required this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION DE CRÉATION
// ============================================================================
// Utilisé par: new_article_screen.dart, new_video_screen.dart, new_podcast_screen.dart
// Container stylisé pour organiser les sections de contenu

/// Card de section pour organiser le contenu de création
///
/// Affiche un titre optionnel et un contenu dans un container stylisé
/// avec bordures et couleurs adaptées au thème
class CreationSection extends StatelessWidget {
  /// Titre optionnel de la section
  final String? title;

  /// Contenu de la section
  final Widget child;

  /// Padding personnalisé (par défaut: 16.0)
  final EdgeInsetsGeometry? padding;

  const CreationSection({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          _buildSectionTitle(),
          const SizedBox(height: 12),
        ],
        _buildSectionContent(),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Text(
      title!,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSectionContent() {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: child,
    );
  }
}
