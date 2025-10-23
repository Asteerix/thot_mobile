import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class NewShortScreenWeb extends ConsumerStatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const NewShortScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  ConsumerState<NewShortScreenWeb> createState() => _NewShortScreenWebState();
}
class _NewShortScreenWebState extends ConsumerState<NewShortScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedDomain;
  bool _isUploading = false;
  static const List<Map<String, dynamic>> _domains = [
    {'name': 'Politique', 'icon': Icons.account_balance},
    {'name': 'Économie', 'icon': Icons.show_chart},
    {'name': 'Culture', 'icon': Icons.theater_comedy},
    {'name': 'Sport', 'icon': Icons.sports_soccer},
    {'name': 'Tech', 'icon': Icons.computer},
  ];
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créer un Short',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: WebTheme.xl),
                if (_selectedDomain == null)
                  _buildDomainSelection(colorScheme)
                else
                  Expanded(child: _buildVideoCreation(colorScheme)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildDomainSelection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez un domaine',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.lg),
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: WebTheme.md,
            mainAxisSpacing: WebTheme.md,
            childAspectRatio: 1.5,
          ),
          itemCount: _domains.length,
          itemBuilder: (context, index) {
            final domain = _domains[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedDomain = domain['name']),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(domain['icon'], size: 48, color: colorScheme.primary),
                    const SizedBox(height: WebTheme.sm),
                    Text(
                      domain['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _buildVideoCreation(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedDomain = null),
              ),
              Text(
                'Domaine: $_selectedDomain',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: WebTheme.lg),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: WebTheme.md),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: WebTheme.md),
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 64, color: colorScheme.outline),
                  const SizedBox(height: WebTheme.md),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload),
                    label: const Text('Choisir une vidéo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WebTheme.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.onNavigate('/feed'),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: WebTheme.md),
              FilledButton(
                onPressed: _isUploading ? null : () {},
                child: Text(_isUploading ? 'Publication...' : 'Publier'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}