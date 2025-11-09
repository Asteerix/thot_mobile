import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class AnalyticsScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const AnalyticsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<AnalyticsScreenWeb> createState() => _AnalyticsScreenWebState();
}
class _AnalyticsScreenWebState extends State<AnalyticsScreenWeb> {
  String _selectedPeriod = '7d';
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: WebMultiColumnLayout(
        content: _buildAnalyticsContent(context, colorScheme),
        contentMaxWidth: WebTheme.maxContentWidth,
      ),
    );
  }
  Widget _buildAnalyticsContent(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(WebTheme.lg),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            _buildPeriodSelector(colorScheme),
          ],
        ),
        const SizedBox(height: WebTheme.xl),
        _buildStatsGrid(colorScheme),
        const SizedBox(height: WebTheme.xl),
        _buildChartsSection(colorScheme),
        const SizedBox(height: WebTheme.xl),
        _buildRecentActivitySection(colorScheme),
      ],
    );
  }
  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '7d', label: Text('7 jours')),
        ButtonSegment(value: '30d', label: Text('30 jours')),
        ButtonSegment(value: '90d', label: Text('90 jours')),
        ButtonSegment(value: 'all', label: Text('Tout')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedPeriod = newSelection.first;
        });
      },
    );
  }
  Widget _buildStatsGrid(ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: context.isDesktop ? 4 : (context.isTablet ? 2 : 1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: WebTheme.md,
      mainAxisSpacing: WebTheme.md,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
          colorScheme,
          'Vues totales',
          '12,543',
          '+12.5%',
          Icons.visibility,
          colorScheme.primary,
        ),
        _buildStatCard(
          colorScheme,
          'Likes',
          '3,245',
          '+8.2%',
          Icons.favorite,
          colorScheme.error,
        ),
        _buildStatCard(
          colorScheme,
          'Commentaires',
          '892',
          '+15.3%',
          Icons.comment,
          colorScheme.primary,
        ),
        _buildStatCard(
          colorScheme,
          'Partages',
          '1,543',
          '+5.7%',
          Icons.share,
          colorScheme.primary,
        ),
      ],
    );
  }
  Widget _buildStatCard(
    ColorScheme colorScheme,
    String title,
    String value,
    String change,
    IconData icon,
    Color iconColor,
  ) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(WebTheme.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.outline.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              Icon(
                icon,
                color: iconColor.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? AppColors.success: AppColors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildChartsSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(WebTheme.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vues au fil du temps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.lg),
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'Graphique à venir',
                style: TextStyle(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRecentActivitySection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(WebTheme.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.md),
          ...List.generate(5, (index) {
            return _buildActivityItem(
              colorScheme,
              'Nouvel article publié',
              'Il y a ${index + 1}h',
              Icons.article,
            );
          }),
        ],
      ),
    );
  }
  Widget _buildActivityItem(
    ColorScheme colorScheme,
    String title,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WebTheme.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: WebTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.outline.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}