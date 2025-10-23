import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../../core/themes/web_theme.dart';
import '../../../domain/entities/post.dart';
class WebPostHeader extends StatelessWidget {
  final JournalistProfile? journalist;
  final String domain;
  final DateTime createdAt;
  final ColorScheme? colorScheme;
  const WebPostHeader({
    super.key,
    this.journalist,
    required this.domain,
    required this.createdAt,
    this.colorScheme,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = colorScheme ?? Theme.of(context).colorScheme;
    return Row(
      children: [
        if (journalist != null) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: journalist!.avatarUrl != null
                ? NetworkImage(journalist!.avatarUrl!)
                : null,
            child: journalist!.avatarUrl == null
                ? Text(
                    journalist!.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: WebTheme.sm),
          Text(
            journalist!.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: WebTheme.sm),
        ],
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WebTheme.sm,
            vertical: WebTheme.xs,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
          ),
          child: Text(
            domain.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const Spacer(),
        Text(
          timeago.format(createdAt, locale: 'fr'),
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}