import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
class UquestionUtypeUselectionUscreenUweb extends ConsumerWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const UquestionUtypeUselectionUscreenUweb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: currentRoute,
      onNavigate: onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Text(
            'question_type_selection_screen_web - En développement',
            style: TextStyle(
              fontSize: 24,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}