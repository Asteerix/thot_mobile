import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../features/posts/application/providers/posts_provider.dart';
class ShortsScreenWeb extends ConsumerStatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  final String? initialDomain;
  const ShortsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.initialDomain,
  });
  @override
  ConsumerState<ShortsScreenWeb> createState() => _ShortsScreenWebState();
}
class _ShortsScreenWebState extends ConsumerState<ShortsScreenWeb> {
  String? _selectedDomain;
  final List<Map<String, dynamic>> _domains = [
    {'name': 'Politique', 'icon': Icons.account_balance, 'color': AppColors.blue},
    {'name': 'Économie', 'icon': Icons.show_chart, 'color': AppColors.success},
    {'name': 'Culture', 'icon': Icons.theater_comedy, 'color': AppColors.purple},
    {'name': 'Sport', 'icon': Icons.sports_soccer, 'color': AppColors.orange},
    {'name': 'Tech', 'icon': Icons.computer, 'color': AppColors.blue},
    {'name': 'Santé', 'icon': Icons.health_and_safety, 'color': AppColors.red},
  ];
  @override
  void initState() {
    super.initState();
    _selectedDomain = widget.initialDomain;
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shorts',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: WebTheme.md),
              Text(
                'Sélectionnez un domaine pour voir les shorts',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: WebTheme.xl),
              if (_selectedDomain == null)
                Expanded(child: _buildDomainGrid(colorScheme))
              else
                Expanded(child: _buildShortsView(colorScheme)),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDomainGrid(ColorScheme colorScheme) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: WebTheme.lg,
        mainAxisSpacing: WebTheme.lg,
        childAspectRatio: 1.2,
      ),
      itemCount: _domains.length,
      itemBuilder: (context, index) {
        final domain = _domains[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: InkWell(
            onTap: () {
              setState(() => _selectedDomain = domain['name']);
              widget.onNavigate('/shorts/${domain['name'].toLowerCase()}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(WebTheme.lg),
                  decoration: BoxDecoration(
                    color: (domain['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    domain['icon'],
                    size: 48,
                    color: domain['color'],
                  ),
                ),
                const SizedBox(height: WebTheme.md),
                Text(
                  domain['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildShortsView(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _selectedDomain = null);
                widget.onNavigate('/shorts');
              },
            ),
            const SizedBox(width: WebTheme.md),
            Text(
              'Shorts - $_selectedDomain',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: WebTheme.lg),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library,
                  size: 80,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: WebTheme.lg),
                Text(
                  'Lecteur de shorts disponible prochainement',
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: WebTheme.md),
                FilledButton(
                  onPressed: () => setState(() => _selectedDomain = null),
                  child: const Text('Retour aux domaines'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}