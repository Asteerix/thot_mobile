import 'package:flutter/material.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class AdminDialogUtils {
  AdminDialogUtils._();
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
    IconData? icon,
    Widget? content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor ?? AppColors.red),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: content ??
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? AppColors.red,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String itemType,
  }) {
    return showConfirmationDialog(
      context: context,
      title: 'Supprimer ce $itemType?',
      message: 'Cette action est irréversible.',
      confirmText: 'Supprimer',
      confirmColor: AppColors.red,
      icon: Icons.delete,
    );
  }
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required String confirmText,
    String cancelText = 'Annuler',
    Color? confirmColor,
    IconData? icon,
    String? message,
    bool required = true,
    int maxLines = 3,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        controller: controller,
        title: title,
        message: message,
        hint: hint,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        required: required,
        maxLines: maxLines,
      ),
    );
    controller.dispose();
    return result;
  }
}
class _InputDialog extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final String? message;
  final String hint;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final bool required;
  final int maxLines;
  const _InputDialog({
    required this.controller,
    required this.title,
    this.message,
    required this.hint,
    required this.confirmText,
    required this.cancelText,
    this.confirmColor,
    this.icon,
    required this.required,
    required this.maxLines,
  });
  @override
  State<_InputDialog> createState() => _InputDialogState();
}
class _InputDialogState extends State<_InputDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.confirmColor ?? AppColors.red),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: widget.controller,
            maxLines: widget.maxLines,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => SafeNavigation.pop(context),
          child: Text(widget.cancelText),
        ),
        TextButton(
          onPressed: () {
            final text = widget.controller.text.trim();
            if (widget.required && text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ce champ est obligatoire'),
                  backgroundColor: AppColors.orange,
                ),
              );
              return;
            }
            SafeNavigation.pop(context, text);
          },
          style: TextButton.styleFrom(
            foregroundColor: widget.confirmColor ?? AppColors.red,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}