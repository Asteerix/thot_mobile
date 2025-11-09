import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/time_formatter.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class CommentCardDesktop extends StatefulWidget {
  final String commentId;
  final String authorName;
  final String authorUsername;
  final String? avatarUrl;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int replies;
  final bool isLiked;
  final bool canReply;
  final bool canReport;
  final bool canDelete;
  final List<CommentCardDesktop>? nestedReplies;
  final int nestingLevel;
  final Function(String commentId)? onLike;
  final Function(String commentId)? onReply;
  final Function(String commentId)? onReport;
  final Function(String commentId)? onDelete;
  const CommentCardDesktop({
    super.key,
    required this.commentId,
    required this.authorName,
    required this.authorUsername,
    this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.replies = 0,
    this.isLiked = false,
    this.canReply = true,
    this.canReport = true,
    this.canDelete = false,
    this.nestedReplies,
    this.nestingLevel = 0,
    this.onLike,
    this.onReply,
    this.onReport,
    this.onDelete,
  });
  @override
  State<CommentCardDesktop> createState() => _CommentCardDesktopState();
}
class _CommentCardDesktopState extends State<CommentCardDesktop> {
  bool _isHovered = false;
  bool _showReplies = false;
  bool _isReplying = false;
  final _replyController = TextEditingController();
  final _focusNode = FocusNode();
  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  String _getTimeAgo(DateTime timestamp) => TimeFormatter.formatTimeAgoEnglish(timestamp);
  void _handleReply() {
    if (_replyController.text.trim().isEmpty) return;
    widget.onReply?.call(widget.commentId);
    _replyController.clear();
    setState(() => _isReplying = false);
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indent = widget.nestingLevel * WebTheme.xl;
    final maxNestingLevel = 3;
    final canNest = widget.nestingLevel < maxNestingLevel;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isHovered
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                border: Border.all(
                  color: _isHovered
                      ? colorScheme.outline.withOpacity(0.2)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(WebTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: WebTheme.avatarSizeSmall / 2,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: widget.avatarUrl != null
                            ? NetworkImage(widget.avatarUrl!)
                            : null,
                        child: widget.avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: colorScheme.onPrimaryContainer,
                              )
                            : null,
                      ),
                      const SizedBox(width: WebTheme.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.authorName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: WebTheme.xs),
                                Text(
                                  '@${widget.authorUsername}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: WebTheme.xs),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(width: WebTheme.xs),
                                Text(
                                  _getTimeAgo(widget.timestamp),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: WebTheme.xs),
                            Text(
                              widget.content,
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.canDelete && _isHovered)
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20,
                            color: AppColors.red
                          ),
                          onPressed: () =>
                              widget.onDelete?.call(widget.commentId),
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                  const SizedBox(height: WebTheme.sm),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => widget.onLike?.call(widget.commentId),
                        borderRadius:
                            BorderRadius.circular(WebTheme.borderRadiusSmall),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WebTheme.sm,
                            vertical: WebTheme.xs,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite,
                                size: 18,
                                color: widget.isLiked
                                    ? AppColors.red
                                    : colorScheme.onSurface.withOpacity(0.6),
                              ),
                              if (widget.likes > 0) ...[
                                const SizedBox(width: WebTheme.xs),
                                Text(
                                  '${widget.likes}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isLiked
                                        ? AppColors.red
                                        : colorScheme.onSurface
                                            .withOpacity(0.6),
                                    fontWeight: widget.isLiked
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: WebTheme.md),
                      if (widget.canReply && canNest)
                        InkWell(
                          onTap: () {
                            setState(() => _isReplying = !_isReplying);
                            if (_isReplying) {
                              _focusNode.requestFocus();
                            }
                          },
                          borderRadius:
                              BorderRadius.circular(WebTheme.borderRadiusSmall),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WebTheme.sm,
                              vertical: WebTheme.xs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.reply,
                                  size: 18,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: WebTheme.xs),
                                Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.nestedReplies != null &&
                          widget.nestedReplies!.isNotEmpty) ...[
                        const SizedBox(width: WebTheme.md),
                        InkWell(
                          onTap: () =>
                              setState(() => _showReplies = !_showReplies),
                          borderRadius:
                              BorderRadius.circular(WebTheme.borderRadiusSmall),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WebTheme.sm,
                              vertical: WebTheme.xs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showReplies
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: WebTheme.xs),
                                Text(
                                  _showReplies
                                      ? 'Hide replies'
                                      : '${widget.nestedReplies!.length} ${widget.nestedReplies!.length == 1 ? "reply" : "replies"}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (widget.canReport && _isHovered)
                        IconButton(
                          icon: Icon(
                            Icons.flag,
                            size: 18,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: () =>
                              widget.onReport?.call(widget.commentId),
                          tooltip: 'Report',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isReplying) ...[
            const SizedBox(height: WebTheme.md),
            Padding(
              padding:
                  EdgeInsets.only(left: WebTheme.avatarSizeSmall + WebTheme.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      focusNode: _focusNode,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(WebTheme.borderRadiusSmall),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(WebTheme.borderRadiusSmall),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(WebTheme.borderRadiusSmall),
                          borderSide:
                              BorderSide(color: colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(WebTheme.md),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: WebTheme.sm),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _handleReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: WebTheme.lg,
                            vertical: WebTheme.md,
                          ),
                        ),
                        child: const Text('Reply'),
                      ),
                      const SizedBox(height: WebTheme.xs),
                      TextButton(
                        onPressed: () {
                          _replyController.clear();
                          setState(() => _isReplying = false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_showReplies &&
              widget.nestedReplies != null &&
              widget.nestedReplies!.isNotEmpty) ...[
            const SizedBox(height: WebTheme.md),
            ...widget.nestedReplies!,
          ],
          const SizedBox(height: WebTheme.md),
          if (widget.nestingLevel == 0)
            Divider(
              color: colorScheme.outline.withOpacity(0.2),
              height: 1,
            ),
        ],
      ),
    );
  }
}