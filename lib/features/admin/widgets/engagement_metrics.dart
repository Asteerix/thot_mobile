import 'package:flutter/material.dart';
import 'package:thot/core/config/spacing_constants.dart';
import 'package:thot/shared/utils/responsive_utils.dart';

class EngagementMetrics extends StatelessWidget {
  final int views;
  final int likes;
  final int comments;
  final MainAxisAlignment alignment;
  final double iconSize;
  final double fontSize;
  const EngagementMetrics({
    super.key,
    required this.views,
    required this.likes,
    required this.comments,
    this.alignment = MainAxisAlignment.spaceAround,
    this.iconSize = 20,
    this.fontSize = 14,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        EngagementItem(
          icon: Icons.visibility,
          value: views.toString(),
          label: 'vues',
          iconSize: iconSize,
          fontSize: fontSize,
        ),
        EngagementItem(
          icon: Icons.favorite,
          value: likes.toString(),
          label: 'likes',
          iconSize: iconSize,
          fontSize: fontSize,
        ),
        EngagementItem(
          icon: Icons.comment,
          value: comments.toString(),
          label: 'commentaires',
          iconSize: iconSize,
          fontSize: fontSize,
        ),
      ],
    );
  }
}

class EngagementItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final double iconSize;
  final double fontSize;
  const EngagementItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconSize = 20,
    this.fontSize = 14,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Theme.of(context).colorScheme.outline,
        ),
        SizedBox(height: SpacingConstants.space4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize * 0.7,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class CompactEngagementMetrics extends StatelessWidget {
  final int views;
  final int likes;
  final int comments;
  final double iconSize;
  final double fontSize;
  const CompactEngagementMetrics({
    super.key,
    required this.views,
    required this.likes,
    required this.comments,
    this.iconSize = 16,
    this.fontSize = 12,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.visibility, size: iconSize, color: colorScheme.outline),
        SizedBox(width: SpacingConstants.space4),
        Text(views.toString(), style: TextStyle(fontSize: fontSize)),
        SizedBox(width: SpacingConstants.space8),
        Icon(Icons.favorite, size: iconSize, color: colorScheme.outline),
        SizedBox(width: SpacingConstants.space4),
        Text(likes.toString(), style: TextStyle(fontSize: fontSize)),
        SizedBox(width: SpacingConstants.space8),
        Icon(Icons.comment, size: iconSize, color: colorScheme.outline),
        SizedBox(width: SpacingConstants.space4),
        Text(comments.toString(), style: TextStyle(fontSize: fontSize)),
      ],
    );
  }
}
