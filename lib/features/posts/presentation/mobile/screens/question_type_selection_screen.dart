import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/monitoring/logger_service.dart';
class QuestionTypeSelectionScreen extends StatefulWidget {
  final String? journalistId;
  const QuestionTypeSelectionScreen({
    super.key,
    this.journalistId,
  });
  @override
  State<QuestionTypeSelectionScreen> createState() =>
      _QuestionTypeSelectionScreenState();
}
class _QuestionTypeSelectionScreenState
    extends State<QuestionTypeSelectionScreen> {
  final _logger = LoggerService.instance;
  String? _selectedDomain;
  String? _selectedType;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Nouvelle question',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configurez votre question',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez le domaine et le type de votre question',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'DOMAINE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildDomainGrid(),
              const SizedBox(height: 32),
              Text(
                'TYPE DE QUESTION',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildTypeSelection(),
              const Spacer(),
              ElevatedButton(
                onPressed: (_selectedDomain != null && _selectedType != null)
                    ? _navigateToQuestionCreation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context).colorScheme.surface,
                  disabledForegroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDomainGrid() {
    final domains = [
      {'value': 'politique', 'label': 'Politique', 'icon': Icons.gavel},
      {'value': 'economie', 'label': 'Économie', 'icon': Icons.trending_up},
      {'value': 'societe', 'label': 'Société', 'icon': Icons.group},
      {'value': 'culture', 'label': 'Culture', 'icon': Icons.palette},
      {'value': 'sport', 'label': 'Sport', 'icon': Icons.emoji_events},
      {'value': 'tech', 'label': 'Tech', 'icon': Icons.laptop},
      {'value': 'environnement', 'label': 'Environnement', 'icon': Icons.eco},
      {
        'value': 'international',
        'label': 'International',
        'icon': Icons.public
      },
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: domains.map((domain) {
        final isSelected = _selectedDomain == domain['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDomain = domain['value'] as String;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.blue : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.blue : Theme.of(context).colorScheme.surfaceContainerHighest,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  domain['icon'] as IconData,
                  color: isSelected ? Theme.of(context).colorScheme.surface : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  domain['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.surface : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  Widget _buildTypeSelection() {
    return Column(
      children: [
        _buildTypeOption(
          type: 'poll',
          title: 'Sondage',
          description: 'Les utilisateurs votent parmi des options prédéfinies',
          icon: Icons.bar_chart,
        ),
        const SizedBox(height: 12),
        _buildTypeOption(
          type: 'debate',
          title: 'Débat',
          description: 'Question ouverte pour encourager la discussion',
          icon: Icons.forum,
        ),
      ],
    );
  }
  Widget _buildTypeOption({
    required String type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.blue : Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.surface,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_unchecked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.blue : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  void _navigateToQuestionCreation() {
    _logger.info(
        'Navigating to question creation with domain: $_selectedDomain, type: $_selectedType');
    context.push(
      '/new-question',
      extra: {
        'journalistId': widget.journalistId,
        'domain': _selectedDomain,
        'questionType': _selectedType,
      },
    );
  }
}