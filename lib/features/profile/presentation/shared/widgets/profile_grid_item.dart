import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/constants/app_constants.dart';
class ProfileGridItem extends StatelessWidget {
  final String? imageUrl;
  final String type;
  final bool isConfirmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? heroTag;
  final String? semanticsLabel;
  const ProfileGridItem({
    super.key,
    required this.imageUrl,
    this.type = PostTypes.article,
    this.isConfirmed = true,
    this.onTap,
    this.onLongPress,
    this.heroTag,
    this.semanticsLabel,
  });
  (IconData, String) _typeVisual() {
    switch (type) {
      case PostTypes.video:
        return (Icons.play_circle_fill, 'Vidéo');
      case PostTypes.short:
        return (Icons.view_carousel_outlined, 'Short');
      case PostTypes.podcast:
        return (Icons.mic_none, 'Podcast');
      case PostTypes.question:
        return (Icons.question_answer_outlined, 'Question');
      case PostTypes.article:
        return (Icons.article_outlined, 'Article');
      default:
        return (Icons.article_outlined, 'Contenu');
    }
  }
  static const _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = 12.0;
    final (iconData, typeLabel) = _typeVisual();
    final semantics = [
      semanticsLabel ?? typeLabel,
      if (!isConfirmed) 'Non confirmé',
    ].join(', ');
    Widget imageLayer;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageLayer = Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
            ),
          ),
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSync) {
              if (wasSync) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (context, error, stack) {
              return _ErrorPlaceholder(colorScheme: cs);
            },
          ),
        ],
      );
    } else {
      imageLayer = _EmptyPlaceholder(colorScheme: cs);
    }
    if (!isConfirmed) {
      imageLayer = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
        child: imageLayer,
      );
    }
    final content = Stack(
      fit: StackFit.expand,
      children: [
        imageLayer,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0, .3),
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
        if (!isConfirmed)
          Positioned(
            top: 8,
            left: 8,
            child: _ChipBadge(
              background: cs.errorContainer.withOpacity(.96),
              foreground: cs.onErrorContainer,
              icon: Icons.error_outline,
              label: 'Non confirmé',
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Tooltip(
            message: typeLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.inverseSurface.withOpacity(.65),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(iconData,
                    size: _typeIconSize(type), color: cs.onInverseSurface),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            onLongPress: onLongPress,
            mouseCursor: onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
          ),
        ),
      ],
    );
    final shaped = Material(
      color: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    final heroWrapped =
        heroTag == null ? shaped : Hero(tag: heroTag!, child: shaped);
    return Semantics(
      button: onTap != null || onLongPress != null,
      label: semantics,
      image: imageUrl != null,
      child: AspectRatio(aspectRatio: 1, child: heroWrapped),
    );
  }
  double _typeIconSize(String t) {
    switch (t) {
      case PostTypes.video:
      case PostTypes.short:
        return 22;
      default:
        return 20;
    }
  }
}
class _EmptyPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyPlaceholder({required this.colorScheme});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40, color: Colors.white70),
      ),
    );
  }
}
class _ErrorPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ErrorPlaceholder({required this.colorScheme});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.errorContainer),
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            size: 36, color: colorScheme.onErrorContainer),
      ),
    );
  }
}
class _ChipBadge extends StatelessWidget {
  final Color background;
  final Color foreground;
  final IconData icon;
  final String label;
  const _ChipBadge({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: .2,
              height: 1,
            ),
          ),
        ]),
      ),
    );
  }
}