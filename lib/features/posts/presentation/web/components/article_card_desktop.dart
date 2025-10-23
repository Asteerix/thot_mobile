import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../features/posts/domain/entities/post.dart';
import 'web_action_button.dart';
import 'web_post_header.dart';
class ArticleCardDesktop extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  const ArticleCardDesktop({
    super.key,
    required this.post,
    required this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onSave,
  });
  @override
  State<ArticleCardDesktop> createState() => _ArticleCardDesktopState();
}
class _ArticleCardDesktopState extends State<ArticleCardDesktop> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.2),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.post.imageUrl != null) _buildImage(colorScheme),
              Padding(
                padding: const EdgeInsets.all(WebTheme.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colorScheme),
                    const SizedBox(height: WebTheme.md),
                    _buildTitle(colorScheme),
                    const SizedBox(height: WebTheme.sm),
                    _buildExcerpt(colorScheme),
                    const SizedBox(height: WebTheme.lg),
                    _buildFooter(colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildImage(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(WebTheme.borderRadiusMedium),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          widget.post.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(ColorScheme colorScheme) {
    return WebPostHeader(
      journalist: widget.post.journalist,
      domain: widget.post.domain,
      createdAt: widget.post.createdAt,
      colorScheme: colorScheme,
    );
  }
  Widget _buildTitle(ColorScheme colorScheme) {
    return Text(
      widget.post.title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
  Widget _buildExcerpt(ColorScheme colorScheme) {
    final excerpt = widget.post.content.length > 150
        ? '${widget.post.content.substring(0, 150)}...'
        : widget.post.content;
    return Text(
      excerpt,
      style: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurface.withOpacity(0.7),
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
  Widget _buildFooter(ColorScheme colorScheme) {
    return Row(
      children: [
        WebActionButton(
          icon: widget.post.interactions.isLiked
              ? Icons.favorite
              : Icons.favorite_border,
          label: '${widget.post.stats.likes}',
          onTap: widget.onLike,
          isActive: widget.post.interactions.isLiked,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: WebTheme.md),
        WebActionButton(
          icon: Icons.comment_outlined,
          label: '${widget.post.stats.comments}',
          onTap: widget.onComment,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: WebTheme.md),
        WebActionButton(
          icon: Icons.share_outlined,
          label: '${widget.post.stats.shares}',
          onTap: widget.onShare,
          colorScheme: colorScheme,
        ),
        const Spacer(),
        WebActionButton(
          icon: widget.post.interactions.isSaved
              ? Icons.bookmark
              : Icons.bookmark_border,
          label: '',
          onTap: widget.onSave,
          isActive: widget.post.interactions.isSaved,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}