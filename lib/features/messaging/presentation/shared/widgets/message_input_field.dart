import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
class MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onImage;
  final bool showAttachmentButtons;
  final String hintText;
  const MessageInputField({
    super.key,
    required this.controller,
    this.onSend,
    this.onAttach,
    this.onImage,
    this.showAttachmentButtons = false,
    this.hintText = 'Type a message...',
  });
  void _handleSend() {
    if (controller.text.trim().isNotEmpty && onSend != null) {
      onSend!();
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 8.0 : WebTheme.lg),
      decoration: BoxDecoration(
        color: isMobile ? Theme.of(context).cardColor : null,
        border: Border(
          top: BorderSide(
            color: isMobile
                ? Theme.of(context).dividerColor
                : colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showAttachmentButtons && onAttach != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAttach,
            ),
          if (showAttachmentButtons && onImage != null)
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: onImage,
            ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                filled: !isMobile,
                fillColor:
                    isMobile ? null : colorScheme.surfaceContainerHighest,
                border: isMobile
                    ? const OutlineInputBorder()
                    : OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(WebTheme.borderRadiusLarge),
                        borderSide: BorderSide.none,
                      ),
                contentPadding: isMobile
                    ? null
                    : const EdgeInsets.symmetric(
                        horizontal: WebTheme.md,
                        vertical: WebTheme.sm,
                      ),
              ),
              maxLines: isMobile ? null : 1,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          SizedBox(width: isMobile ? 8.0 : WebTheme.md),
          IconButton(
            icon: Icon(
              Icons.send,
              color: isMobile ? null : colorScheme.primary,
            ),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}