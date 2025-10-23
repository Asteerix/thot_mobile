import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'comment_list.dart';
class CommentsSection extends StatelessWidget {
  final String postId;
  const CommentsSection({
    super.key,
    required this.postId,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: CommentList(postId: postId),
    );
  }
}