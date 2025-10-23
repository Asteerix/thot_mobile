import 'package:flutter/material.dart';
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: isDark ? Colors.black : Colors.white,
        surfaceTintColor: isDark ? Colors.black : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurface,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const Divider(height: 1),
            ..._intersperseDividers(children),
          ],
        ),
      ),
    );
  }
  List<Widget> _intersperseDividers(List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) out.add(const Divider(height: 1));
    }
    return out;
  }
}