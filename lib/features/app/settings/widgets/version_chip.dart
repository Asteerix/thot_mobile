import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VersionChip extends StatelessWidget {
  const VersionChip({
    super.key,
    required this.version,
    required this.buildNumber,
  });
  final String version;
  final String buildNumber;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = 'Version $version ($buildNumber)';
    return Semantics(
      button: true,
      label:
          'Version de l\'application $version, build $buildNumber. Appui long pour copier.',
      child: InkWell(
        onLongPress: () => _copyToClipboard(context, text),
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Version copiée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
