import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/navigation/route_names.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
import '../../../../../shared/widgets/common/loading_indicator.dart';
import '../components/editor_toolbar.dart';
class NewArticleScreenWeb extends ConsumerStatefulWidget {
  final String? postId;
  final String currentRoute;
  final Function(String route) onNavigate;
  const NewArticleScreenWeb({
    super.key,
    this.postId,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  ConsumerState<NewArticleScreenWeb> createState() =>
      _NewArticleScreenWebState();
}
class _NewArticleScreenWebState extends ConsumerState<NewArticleScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _excerptController = TextEditingController();
  String _selectedCategory = 'politique';
  String _selectedType = 'article';
  List<String> _tags = [];
  List<String> _sources = [];
  String? _coverImage;
  bool _isPublishing = false;
  bool _isDraft = true;
  final List<String> _categories = [
    'politique',
    'economie',
    'culture',
    'science',
    'sport',
    'international',
  ];
  final List<String> _articleTypes = [
    'article',
    'analyse',
    'enquete',
    'interview',
    'opinion',
  ];
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _excerptController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      showRightSidebar: context.isDesktop,
      rightSidebar: _buildPublishingSidebar(context, colorScheme),
      body: WebMultiColumnLayout(
        content: _buildEditorContent(context, colorScheme),
        contentMaxWidth: 900,
      ),
    );
  }
  Widget _buildEditorContent(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: WebTheme.xl,
        horizontal: context.isDesktop ? WebTheme.xxl : WebTheme.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => widget.onNavigate(RouteNames.home),
              icon: Icon(Icons.arrow_back, size: 20),
              label: const Text('Retour au feed'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            Text(
              widget.postId != null ? 'Modifier l\'article' : 'Nouvel article',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.xl),
            _buildTitleInput(colorScheme),
            const SizedBox(height: WebTheme.lg),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Type d\'article',
                    value: _selectedType,
                    items: _articleTypes,
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                    },
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: WebTheme.lg),
                Expanded(
                  child: _buildDropdown(
                    label: 'Catégorie',
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: WebTheme.lg),
            _buildExcerptInput(colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildCoverImageSection(colorScheme),
            const SizedBox(height: WebTheme.xl),
            EditorToolbar(
              onBold: () => _insertFormatting('**', '**'),
              onItalic: () => _insertFormatting('*', '*'),
              onHeading: () => _insertFormatting('## ', ''),
              onLink: () => _insertFormatting('[', '](url)'),
              onImage: () => _showImageDialog(),
              onQuote: () => _insertFormatting('> ', ''),
              onBulletList: () => _insertFormatting('- ', ''),
              onNumberedList: () => _insertFormatting('1. ', ''),
            ),
            const SizedBox(height: WebTheme.md),
            _buildContentEditor(colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildTagsSection(colorScheme),
            const SizedBox(height: WebTheme.lg),
            _buildSourcesSection(colorScheme),
            const SizedBox(height: WebTheme.xxl),
            if (!context.isDesktop) _buildActionButtons(colorScheme),
          ],
        ),
      ),
    );
  }
  Widget _buildTitleInput(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return TextFormField(
      controller: _titleController,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Titre de l\'article...',
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
        filled: true,
        fillColor: isDark ? colorScheme.surface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(WebTheme.lg),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le titre est requis';
        }
        return null;
      },
    );
  }
  Widget _buildExcerptInput(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résumé',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        TextFormField(
          controller: _excerptController,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:
                'Un court résumé de l\'article (optionnel, max 200 caractères)',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor: isDark ? colorScheme.surface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
            ),
            contentPadding: const EdgeInsets.all(WebTheme.md),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required ColorScheme colorScheme,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        DropdownButtonFormField<String>(
          value: value,
          style: TextStyle(color: colorScheme.onSurface),
          dropdownColor: isDark ? colorScheme.surface : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? colorScheme.surface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: WebTheme.md,
              vertical: WebTheme.sm,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item[0].toUpperCase() + item.substring(1),
                style: TextStyle(color: colorScheme.onSurface),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
  Widget _buildCoverImageSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image de couverture',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        if (_coverImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
                child: Image.network(
                  _coverImage!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: WebTheme.sm,
                right: WebTheme.sm,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() => _coverImage = null),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.onSurface.withOpacity(0.54),
                    foregroundColor: colorScheme.surface,
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: () => _showImageDialog(isCover: true),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.5),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius:
                    BorderRadius.circular(WebTheme.borderRadiusMedium),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: WebTheme.sm),
                    Text(
                      'Cliquer pour ajouter une image',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildContentEditor(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        Container(
          constraints: const BoxConstraints(minHeight: 500),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
          ),
          child: TextFormField(
            controller: _contentController,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Écrivez votre article ici...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(WebTheme.lg),
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le contenu est requis';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  Widget _buildTagsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        Wrap(
          spacing: WebTheme.sm,
          runSpacing: WebTheme.sm,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                )),
            ActionChip(
              avatar: Icon(Icons.add, size: 16),
              label: const Text('Ajouter un tag'),
              onPressed: () => _showAddTagDialog(),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildSourcesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sources',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        ..._sources.asMap().entries.map((entry) {
          final index = entry.key;
          final source = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: WebTheme.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    source,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20),
                  onPressed: () {
                    setState(() => _sources.removeAt(index));
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => _showAddSourceDialog(),
          icon: Icon(Icons.add, size: 18),
          label: const Text('Ajouter une source'),
        ),
      ],
    );
  }
  Widget _buildPublishingSidebar(
      BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(WebTheme.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publication',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.lg),
          _buildActionButtons(colorScheme),
          const SizedBox(height: WebTheme.xl),
          Divider(color: colorScheme.outline.withOpacity(0.2)),
          const SizedBox(height: WebTheme.lg),
          _buildPublishingInfo(colorScheme),
        ],
      ),
    );
  }
  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isPublishing ? null : () => _publishArticle(false),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: WebTheme.md),
            ),
            child: _isPublishing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier'),
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isPublishing ? null : () => _publishArticle(true),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: WebTheme.md),
            ),
            child: const Text('Enregistrer comme brouillon'),
          ),
        ),
      ],
    );
  }
  Widget _buildPublishingInfo(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.md),
        _buildInfoRow(
          Icons.calendar_today,
          'Date',
          'Aujourd\'hui',
          colorScheme,
        ),
        const SizedBox(height: WebTheme.sm),
        _buildInfoRow(
          Icons.visibility,
          'Statut',
          _isDraft ? 'Brouillon' : 'Publié',
          colorScheme,
        ),
        const SizedBox(height: WebTheme.sm),
        _buildInfoRow(
          Icons.language,
          'Langue',
          'Français',
          colorScheme,
        ),
      ],
    );
  }
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: WebTheme.sm),
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  void _insertFormatting(String before, String after) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      before + text.substring(selection.start, selection.end) + after,
    );
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + before.length,
    );
  }
  void _showImageDialog({bool isCover = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image upload dialog - à implémenter')),
    );
  }
  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nom du tag',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _tags.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
  void _showAddSourceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une source'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'URL de la source',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _sources.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
  Future<void> _publishArticle(bool asDraft) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isPublishing = true;
      _isDraft = asDraft;
    });
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft
                  ? 'Article enregistré comme brouillon'
                  : 'Article publié avec succès',
            ),
          ),
        );
        widget.onNavigate(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}