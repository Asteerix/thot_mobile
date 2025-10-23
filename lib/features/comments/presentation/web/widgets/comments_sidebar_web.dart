import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../shared/widgets/comment_list.dart';
class CommentsSidebarWeb extends StatelessWidget {
  final String postId;
  final VoidCallback? onClose;
  const CommentsSidebarWeb({
    super.key,
    required this.postId,
    this.onClose,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: WebTheme.sidebarWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(WebTheme.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commentaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: onClose,
                    tooltip: 'Fermer',
                  ),
              ],
            ),
          ),
          Expanded(
            child: CommentList(postId: postId),
          ),
        ],
      ),
    );
  }
}