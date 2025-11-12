import 'dart:math';
import 'package:flutter/material.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/public/auth/shared/providers/auth_provider.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/features/app/content/shared/comments/comment.dart';
import 'package:thot/shared/widgets/images/app_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/widgets/comment_likes_sheet.dart';
import 'package:thot/features/admin/widgets/admin_moderation_actions.dart';

class CommentListItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onReply;
  final Function(bool)? onLike;
  final bool showReplies;
  final VoidCallback? onViewReplies;
  final bool isReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  const CommentListItem({
    super.key,
    required this.comment,
    this.onReply,
    this.onLike,
    this.showReplies = true,
    this.onViewReplies,
    this.isReply = false,
    this.onEdit,
    this.onDelete,
    this.onReport,
  });
  @override
  State<CommentListItem> createState() => _CommentListItemState();
}

class _CommentListItemState extends State<CommentListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  bool _isLiked = false;
  int _likeCount = 0;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _isLiked = widget.comment.isLiked;
    _likeCount = widget.comment.likes;
  }

  @override
  void didUpdateWidget(CommentListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.isLiked != widget.comment.isLiked ||
        oldWidget.comment.likes != widget.comment.likes) {
      setState(() {
        _isLiked = widget.comment.isLiked;
        _likeCount = widget.comment.likes;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToProfile(BuildContext context) {
    context.replaceNamed(
      RouteNames.profile,
      extra: {'userId': widget.comment.author.id},
    );
  }

  void _showLikesSheet(BuildContext context) {
    if (_likeCount > 0) {
      CommentLikesSheet.show(context, widget.comment.id);
    }
  }

  void _handleLike() {
    if (widget.onLike != null) {
      HapticFeedback.lightImpact();
      final currentlyLiked = _isLiked;
      final newLikedState = !currentlyLiked;
      setState(() {
        _isLiked = newLikedState;
        _likeCount += newLikedState ? 1 : -1;
        if (_likeCount < 0) _likeCount = 0;
      });
      widget.onLike!(newLikedState);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      _dragExtent = _dragExtent.clamp(-200.0, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.userProfile?.id == widget.comment.author.id;
    if (_dragExtent < -100) {
      _animation = Tween<double>(
        begin: _dragExtent,
        end: isOwner ? -160.0 : -80.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    } else {
      _animation = Tween<double>(
        begin: _dragExtent,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    }
    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragExtent = _animation.value;
      });
    });
  }

  Widget _buildMoreMenu(BuildContext context, ColorScheme colorScheme) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.userProfile?.id == widget.comment.author.id;
    return PopupMenuButton<String>(
      constraints: const BoxConstraints(
        minWidth: 150,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.outline.withOpacity(0.6),
        size: 18,
      ),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit?.call();
            break;
          case 'delete':
            _showDeleteConfirmation(context);
            break;
          case 'report':
            _showReportDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        if (isOwner) ...[
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: colorScheme.onSurface, size: 18),
                const SizedBox(width: 8),
                Text('Modifier',
                    style: TextStyle(color: colorScheme.onSurface)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: colorScheme.error, size: 18),
                const SizedBox(width: 8),
                Text('Supprimer', style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
        ] else
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text('Signaler', style: TextStyle(color: AppColors.warning)),
              ],
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    SafeNavigation.showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Supprimer le commentaire',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              SafeNavigation.pop(context);
              widget.onDelete?.call();
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    widget.onReport?.call();
  }

  void _showActionsBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.userProfile?.id == widget.comment.author.id;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Actions sur le commentaire',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (isOwner) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: colorScheme.primary),
                  title: Text(
                    'Modifier',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit?.call();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text(
                    'Supprimer',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.flag, color: AppColors.warning),
                  title: Text(
                    'Signaler',
                    style: TextStyle(color: AppColors.warning),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.userProfile?.id == widget.comment.author.id;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          onLongPress: () => _showActionsBottomSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset:
                          Offset(max(0, -_dragExtent - _animation.value), 0),
                      child: Row(
                        children: [
                          if (isOwner) ...[
                            GestureDetector(
                              onTap: () {
                                _dragExtent = 0;
                                _controller.reverse();
                                widget.onEdit?.call();
                              },
                              child: Container(
                                width: 80,
                                color: colorScheme.primary,
                                child: Icon(
                                  Icons.edit,
                                  color: colorScheme.onSurface,
                                  size: 24,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _dragExtent = 0;
                                _controller.reverse();
                                _showDeleteConfirmation(context);
                              },
                              child: Container(
                                width: 80,
                                color: colorScheme.error,
                                child: Icon(
                                  Icons.delete,
                                  color: colorScheme.onSurface,
                                  size: 24,
                                ),
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: () {
                                _dragExtent = 0;
                                _controller.reverse();
                                _showReportDialog(context);
                              },
                              child: Container(
                                width: 80,
                                color: AppColors.warning,
                                child: Icon(
                                  Icons.flag,
                                  color: colorScheme.onSurface,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_dragExtent + _animation.value, 0),
                    child: Container(
                      width: constraints.maxWidth,
                      color: colorScheme.surface,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: widget.isReply ? 48.0 : 12.0,
                          right: 12.0,
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _navigateToProfile(context),
                                child: AppAvatar(
                                  avatarUrl: widget.comment.author.avatarUrl,
                                  radius: 18,
                                  isJournalist:
                                      widget.comment.author.isVerified,
                                  backgroundColor: colorScheme.surface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _navigateToProfile(
                                                          context),
                                                  child: Text(
                                                    widget.comment.author
                                                        .username,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ),
                                              if (widget.comment.author
                                                  .isVerified) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.verified,
                                                  color: colorScheme.primary,
                                                  size: 14,
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: Text(
                                                  widget.comment.isEdited
                                                      ? '${timeago.format(widget.comment.createdAt, locale: 'fr')} • Modifié'
                                                      : timeago.format(
                                                          widget.comment
                                                              .createdAt,
                                                          locale: 'fr'),
                                                  style: TextStyle(
                                                    color: colorScheme.outline
                                                        .withOpacity(0.5),
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_dragExtent == 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: _buildMoreMenu(
                                                context, colorScheme),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        widget.comment.content,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: _handleLike,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                child: Icon(
                                                  _isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite,
                                                  color: _isLiked
                                                      ? colorScheme.error
                                                      : colorScheme.outline
                                                          .withOpacity(0.6),
                                                  size: _isLiked ? 20 : 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            if (_likeCount > 0)
                                              GestureDetector(
                                                onTap: () =>
                                                    _showLikesSheet(context),
                                                child: Text(
                                                  _likeCount.toString(),
                                                  style: TextStyle(
                                                    color: _isLiked
                                                        ? colorScheme.error
                                                        : colorScheme.outline
                                                            .withOpacity(0.6),
                                                    fontSize: 13,
                                                    fontWeight: _isLiked
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (widget.onReply != null)
                                          GestureDetector(
                                            onTap: widget.onReply,
                                            child: Text(
                                              'Répondre',
                                              style: TextStyle(
                                                color: colorScheme.outline
                                                    .withOpacity(0.6),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        if (widget.showReplies &&
                                            widget.comment.replyCount > 0)
                                          GestureDetector(
                                            onTap: widget.onViewReplies,
                                            child: Text(
                                              'Voir les ${widget.comment.replyCount} réponses',
                                              style: TextStyle(
                                                color: colorScheme.outline
                                                    .withOpacity(0.6),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        if (authProvider.isAdmin && !isOwner) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: AdminModerationActions(
                                              userId: widget.comment.author.id,
                                              commentId: widget.comment.id,
                                              onDeleted: widget.onDelete,
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
