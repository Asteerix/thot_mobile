import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';

/// Widget de champ de texte personnalisé avec support de thème dark/light.
/// Utilisé dans les écrans de création de posts (articles, vidéos, podcasts).
///
/// Propriétés utilisées dans la codebase:
/// - controller, label, hint: Toujours utilisés
/// - focusNode, textInputAction, onFieldSubmitted: Gestion navigation formulaire
/// - maxLines, maxLength, counterText: Limites et compteurs
/// - keyboardType: Type de clavier (multiline pour descriptions/contenu)
/// - validator: Validation formulaire
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String hint;
  // DEAD CODE: Le paramètre 'icon' n'est jamais utilisé dans la codebase.
  // Conservé pour compatibilité future mais commenté pour documentation.
  // final IconData? icon;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? counterText;

  const CustomTextField({
    super.key,
    required this.controller,
    this.label,
    required this.hint,
    // this.icon,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputAction,
    this.counterText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: isDark ? AppColors.darkOnSurface : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDark ? AppColors.darkOnSurface : AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: _buildInputDecoration(isDark),
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }

  /// Construit la décoration du champ de texte selon le thème.
  InputDecoration _buildInputDecoration(bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fillColor = isDark ? AppColors.darkCard : AppColors.surface;
    final hintColor = isDark ? AppColors.darkOnSurface : AppColors.textSecondary;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 15,
      ),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      counterText: counterText,
      counterStyle: TextStyle(color: hintColor),
    );
  }
}
