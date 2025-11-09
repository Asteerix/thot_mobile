import 'package:thot/core/themes/app_colors.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/domain/entities/short.dart';
import 'package:thot/features/posts/domain/entities/political_view.dart';
import 'package:thot/features/admin/presentation/shared/widgets/report_dialog.dart';
class InteractionButtons extends StatelessWidget {
  final Short short;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;
  final Function(PoliticalView) onVote;
  final Function() onVoteButtonTap;
  const InteractionButtons({
    super.key,
    required this.short,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    required this.onVote,
    required this.onVoteButtonTap,
  });
  Color _getPoliticalViewColor(PoliticalView view) {
    switch (view) {
      case PoliticalView.extremelyConservative:
        return AppColors.extremelyConservative;
      case PoliticalView.conservative:
        return AppColors.conservative;
      case PoliticalView.neutral:
        return AppColors.neutral;
      case PoliticalView.progressive:
        return AppColors.progressive;
      case PoliticalView.extremelyProgressive:
        return AppColors.extremelyProgressive;
    }
  }
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed((count % 1000) == 0 ? 0 : 1)}K';
    }
    return '${(count / 1000000).toStringAsFixed((count % 1000000) == 0 ? 0 : 1)}M';
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface.withOpacity(0.92);
    final likeActive = short.isLiked;
    final dislikeActive = short.isDisliked;
    final votes = short.politicalOrientation?.userVotes.values
            .fold<int>(0, (s, c) => s + c) ??
        0;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.thumb_up,
            activeIcon: Icons.thumb_up,
            active: likeActive,
            color: likeActive ? cs.primary : onSurface,
            count: _formatCount(short.likes),
            tooltip: 'Aimer',
            semanticsLabel: 'Aimer',
            onPressed: () {
              HapticFeedback.selectionClick();
              onLike();
            },
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.thumb_down,
            activeIcon: Icons.thumb_down,
            active: dislikeActive,
            color: dislikeActive ? cs.error : onSurface,
            count: _formatCount(short.dislikes),
            tooltip: 'Ne pas aimer',
            semanticsLabel: 'Ne pas aimer',
            onPressed: () {
              HapticFeedback.selectionClick();
              onDislike();
            },
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.comment,
            activeIcon: Icons.comment,
            active: false,
            color: onSurface,
            count: _formatCount(short.comments),
            tooltip: 'Commentaires',
            semanticsLabel: 'Commentaires',
            onPressed: () {
              HapticFeedback.selectionClick();
              onComment();
            },
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getPoliticalViewColor(short.politicalView),
                width: 2,
              ),
            ),
            child: _ActionButton(
              icon: Icons.public,
              activeIcon: Icons.public,
              active: true,
              color: _getPoliticalViewColor(short.politicalView),
              count: _formatCount(votes),
              tooltip: 'Orientation politique',
              semanticsLabel: 'Orientation politique',
              onPressed: () {
                HapticFeedback.selectionClick();
                onVoteButtonTap();
              },
            ),
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.more_horiz,
            activeIcon: Icons.more_horiz,
            active: false,
            color: onSurface,
            count: null,
            tooltip: 'Plus d\'options',
            semanticsLabel: 'Plus d\'options',
            onPressed: () {
              HapticFeedback.selectionClick();
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
    );
  }
  void _showOptionsMenu(BuildContext context) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.flag, color: Colors.red),
                title: const Text('Signaler ce contenu',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  SafeNavigation.pop(context);
                  SafeNavigation.showDialog(
                    context: context,
                    builder: (context) => ReportDialog(
                      targetType: 'short',
                      targetId: short.id,
                      targetTitle: short.title,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final Color color;
  final String? count;
  final String tooltip;
  final String semanticsLabel;
  final VoidCallback onPressed;
  const _ActionButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.color,
    required this.count,
    required this.tooltip,
    required this.semanticsLabel,
    required this.onPressed,
  });
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}
class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final iconData = widget.active ? widget.activeIcon : widget.icon;
    return Semantics(
      button: true,
      toggled: widget.active,
      label: widget.semanticsLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: widget.tooltip,
            waitDuration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkResponse(
                onTap: widget.onPressed,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                radius: 28,
                customBorder: const CircleBorder(),
                splashColor: widget.color.withOpacity(0.25),
                highlightColor: widget.color.withOpacity(0.12),
                child: AnimatedScale(
                  scale: _pressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: _FrostedCircle(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(iconData, color: widget.color, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.count != null) ...[
            const SizedBox(height: 4),
            _CountBadge(text: widget.count!),
          ],
        ],
      ),
    );
  }
}
class _FrostedCircle extends StatelessWidget {
  final Widget child;
  const _FrostedCircle({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Stack(
        alignment: Alignment.center,
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox(width: 48, height: 48),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.30),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              shape: BoxShape.circle,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
class _CountBadge extends StatelessWidget {
  final String text;
  const _CountBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child:
            SizeTransition(sizeFactor: anim, axis: Axis.vertical, child: child),
      ),
      child: ExcludeSemantics(
        key: ValueKey(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Text(text, style: style),
        ),
      ),
    );
  }
}