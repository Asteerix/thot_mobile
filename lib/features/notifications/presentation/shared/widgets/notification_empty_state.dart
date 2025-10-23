import 'package:flutter/material.dart';
import 'notification_filter.dart';
class NotificationEmptyState extends StatelessWidget {
  final NotificationFilter filter;
  const NotificationEmptyState({
    super.key,
    required this.filter,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, title, subtitle) = switch (filter) {
      NotificationFilter.all => (
          Icons.notifications_none_rounded,
          'Aucune notification',
          'Vos notifications apparaîtront ici',
        ),
      NotificationFilter.mention => (
          Icons.alternate_email,
          'Aucune mention',
          'Personne ne vous a mentionné',
        ),
      NotificationFilter.postLike => (
          Icons.favorite_border_rounded,
          'Aucun J\'aime',
          'Vos J\'aime apparaîtront ici',
        ),
      NotificationFilter.comment => (
          Icons.chat_bubble_outline_rounded,
          'Aucun commentaire',
          'Les réponses apparaîtront ici',
        ),
      NotificationFilter.newFollower => (
          Icons.group_outlined,
          'Aucun nouvel abonné',
          'Vos nouveaux abonnés apparaîtront ici',
        ),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withOpacity(0.3),
                    cs.secondaryContainer.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}