import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
class NewVideoScreenWeb extends ConsumerStatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const NewVideoScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  ConsumerState<NewVideoScreenWeb> createState() => _NewVideoScreenWebState();
}
class _NewVideoScreenWebState extends ConsumerState<NewVideoScreenWeb> {
  final _titleController = TextEditingController();
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle Vidéo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: WebTheme.xl),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: WebTheme.md),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload),
                    label: const Text('Importer vidéo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}