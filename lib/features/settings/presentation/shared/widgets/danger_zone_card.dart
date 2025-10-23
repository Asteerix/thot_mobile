import 'package:flutter/material.dart';
class DangerZoneCard extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onLogout;
  const DangerZoneCard({
    super.key,
    required this.onDelete,
    required this.onLogout,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.errorContainer.withOpacity(0.18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zone sensible',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: cs.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.errorContainer,
                      foregroundColor: cs.onErrorContainer,
                    ),
                    onPressed: onDelete,
                    child: const Text('Supprimer mon compte'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                    ),
                    onPressed: onLogout,
                    child: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}