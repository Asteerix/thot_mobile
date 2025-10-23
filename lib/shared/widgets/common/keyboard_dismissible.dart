// ═══════════════════════════════════════════════════════════════════════════════
// FICHIER INUTILISÉ - COMMENTÉ POUR ANALYSE
// ═══════════════════════════════════════════════════════════════════════════════
//
// Raison : Aucun usage détecté dans la codebase (recherche exhaustive dans mobile/lib/)
//
// Classes définies :
// - KeyboardDismissible : Widget wrapper qui ferme le clavier au tap
// - SafeTextField : Wrapper de TextField avec gestion clavier matériel
// - SafeTextFormField : Wrapper de TextFormField avec gestion clavier matériel
//
// Analyse d'usage :
// ✗ KeyboardDismissible : 0 usage
// ✗ SafeTextField : 0 usage
// ✗ SafeTextFormField : 0 usage
//
// Le fichier est exporté dans widgets.dart mais jamais importé/utilisé ailleurs.
// Les fonctionnalités de gestion clavier sont gérées directement via KeyboardService.
//
// Actions recommandées :
// 1. Supprimer ce fichier si non nécessaire à l'avenir
// 2. Retirer l'export de widgets.dart (ligne 10)
// 3. Ou décommenter si besoin d'utiliser ces wrappers dans le futur
//
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/utils/keyboard_service.dart';

/// Widget wrapper qui ferme automatiquement le clavier lors d'un tap
///
/// INUTILISÉ - Préférer GestureDetector + KeyboardService.dismissKeyboard()
// class KeyboardDismissible extends StatelessWidget {
//   final Widget child;
//   final bool dismissOnTap;
//
//   const KeyboardDismissible({
//     super.key,
//     required this.child,
//     this.dismissOnTap = true,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (!dismissOnTap) return child;
//
//     return GestureDetector(
//       onTap: () => KeyboardService.dismissKeyboard(context),
//       behavior: HitTestBehavior.translucent,
//       child: child,
//     );
//   }
// }

/// Wrapper sécurisé pour TextField avec gestion automatique du clavier matériel
///
/// INUTILISÉ - Utiliser TextField standard + KeyboardService si nécessaire
// class SafeTextField extends StatefulWidget {
//   final TextEditingController? controller;
//   final FocusNode? focusNode;
//   final InputDecoration? decoration;
//   final TextInputType? keyboardType;
//   final bool obscureText;
//   final TextInputAction? textInputAction;
//   final ValueChanged<String>? onChanged;
//   final ValueChanged<String>? onSubmitted;
//   final VoidCallback? onEditingComplete;
//   final int? maxLines;
//   final int? minLines;
//   final bool autofocus;
//   final bool enabled;
//   final TextStyle? style;
//   final TextAlign textAlign;
//   final TextCapitalization textCapitalization;
//   final bool autocorrect;
//   final List<TextInputFormatter>? inputFormatters;
//   final int? maxLength;
//   final MaxLengthEnforcement? maxLengthEnforcement;
//
//   const SafeTextField({
//     super.key,
//     this.controller,
//     this.focusNode,
//     this.decoration,
//     this.keyboardType,
//     this.obscureText = false,
//     this.textInputAction,
//     this.onChanged,
//     this.onSubmitted,
//     this.onEditingComplete,
//     this.maxLines = 1,
//     this.minLines,
//     this.autofocus = false,
//     this.enabled = true,
//     this.style,
//     this.textAlign = TextAlign.start,
//     this.textCapitalization = TextCapitalization.none,
//     this.autocorrect = true,
//     this.inputFormatters,
//     this.maxLength,
//     this.maxLengthEnforcement,
//   });
//
//   @override
//   State<SafeTextField> createState() => _SafeTextFieldState();
// }

// class _SafeTextFieldState extends State<SafeTextField>
//     with KeyboardHandlerMixin {
//   late FocusNode _focusNode;
//   late TextEditingController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _focusNode = widget.focusNode ?? FocusNode();
//     _controller = widget.controller ?? TextEditingController();
//     _focusNode.addListener(_handleFocusChange);
//   }
//
//   @override
//   void dispose() {
//     _focusNode.removeListener(_handleFocusChange);
//     if (widget.focusNode == null) _focusNode.dispose();
//     if (widget.controller == null) _controller.dispose();
//     super.dispose();
//   }
//
//   void _handleFocusChange() {
//     if (!_focusNode.hasFocus) {
//       KeyboardService().clearKeyboardState();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: _controller,
//       focusNode: _focusNode,
//       decoration: widget.decoration,
//       keyboardType: widget.keyboardType,
//       obscureText: widget.obscureText,
//       textInputAction: widget.textInputAction,
//       onChanged: widget.onChanged,
//       onSubmitted: (value) {
//         widget.onSubmitted?.call(value);
//         KeyboardService().clearKeyboardState();
//       },
//       onEditingComplete: () {
//         widget.onEditingComplete?.call();
//         KeyboardService().clearKeyboardState();
//       },
//       maxLines: widget.maxLines,
//       minLines: widget.minLines,
//       autofocus: widget.autofocus,
//       enabled: widget.enabled,
//       style: widget.style,
//       textAlign: widget.textAlign,
//       textCapitalization: widget.textCapitalization,
//       autocorrect: widget.autocorrect,
//       inputFormatters: widget.inputFormatters,
//       maxLength: widget.maxLength,
//       maxLengthEnforcement: widget.maxLengthEnforcement,
//     );
//   }
// }

/// Wrapper sécurisé pour TextFormField avec gestion automatique du clavier matériel
///
/// INUTILISÉ - Utiliser TextFormField standard + KeyboardService si nécessaire
// class SafeTextFormField extends StatefulWidget {
//   final TextEditingController? controller;
//   final FocusNode? focusNode;
//   final InputDecoration? decoration;
//   final TextInputType? keyboardType;
//   final bool obscureText;
//   final TextInputAction? textInputAction;
//   final ValueChanged<String>? onChanged;
//   final ValueChanged<String>? onFieldSubmitted;
//   final FormFieldValidator<String>? validator;
//   final FormFieldSetter<String>? onSaved;
//   final VoidCallback? onEditingComplete;
//   final int? maxLines;
//   final int? minLines;
//   final bool autofocus;
//   final bool enabled;
//   final TextStyle? style;
//   final TextAlign textAlign;
//   final TextCapitalization textCapitalization;
//   final bool autocorrect;
//   final List<TextInputFormatter>? inputFormatters;
//   final int? maxLength;
//   final MaxLengthEnforcement? maxLengthEnforcement;
//   final bool autovalidateMode;
//
//   const SafeTextFormField({
//     super.key,
//     this.controller,
//     this.focusNode,
//     this.decoration,
//     this.keyboardType,
//     this.obscureText = false,
//     this.textInputAction,
//     this.onChanged,
//     this.onFieldSubmitted,
//     this.validator,
//     this.onSaved,
//     this.onEditingComplete,
//     this.maxLines = 1,
//     this.minLines,
//     this.autofocus = false,
//     this.enabled = true,
//     this.style,
//     this.textAlign = TextAlign.start,
//     this.textCapitalization = TextCapitalization.none,
//     this.autocorrect = true,
//     this.inputFormatters,
//     this.maxLength,
//     this.maxLengthEnforcement,
//     this.autovalidateMode = false,
//   });
//
//   @override
//   State<SafeTextFormField> createState() => _SafeTextFormFieldState();
// }

// class _SafeTextFormFieldState extends State<SafeTextFormField>
//     with KeyboardHandlerMixin {
//   late FocusNode _focusNode;
//   late TextEditingController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _focusNode = widget.focusNode ?? FocusNode();
//     _controller = widget.controller ?? TextEditingController();
//     _focusNode.addListener(_handleFocusChange);
//   }
//
//   @override
//   void dispose() {
//     _focusNode.removeListener(_handleFocusChange);
//     if (widget.focusNode == null) _focusNode.dispose();
//     if (widget.controller == null) _controller.dispose();
//     super.dispose();
//   }
//
//   void _handleFocusChange() {
//     if (!_focusNode.hasFocus) {
//       KeyboardService().clearKeyboardState();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: _controller,
//       focusNode: _focusNode,
//       decoration: widget.decoration,
//       keyboardType: widget.keyboardType,
//       obscureText: widget.obscureText,
//       textInputAction: widget.textInputAction,
//       onChanged: widget.onChanged,
//       onFieldSubmitted: (value) {
//         widget.onFieldSubmitted?.call(value);
//         KeyboardService().clearKeyboardState();
//       },
//       validator: widget.validator,
//       onSaved: widget.onSaved,
//       onEditingComplete: () {
//         widget.onEditingComplete?.call();
//         KeyboardService().clearKeyboardState();
//       },
//       maxLines: widget.maxLines,
//       minLines: widget.minLines,
//       autofocus: widget.autofocus,
//       enabled: widget.enabled,
//       style: widget.style,
//       textAlign: widget.textAlign,
//       textCapitalization: widget.textCapitalization,
//       autocorrect: widget.autocorrect,
//       inputFormatters: widget.inputFormatters,
//       maxLength: widget.maxLength,
//       maxLengthEnforcement: widget.maxLengthEnforcement,
//       autovalidateMode: widget.autovalidateMode
//           ? AutovalidateMode.onUserInteraction
//           : AutovalidateMode.disabled,
//     );
//   }
// }
