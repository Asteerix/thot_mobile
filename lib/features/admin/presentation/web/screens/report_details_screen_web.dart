import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import '../../../../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../../../../features/media/utils/image_utils.dart';
import '../../../../../features/admin/presentation/shared/utils/report_helpers.dart';
import '../../../../../features/admin/presentation/shared/widgets/report_target_content.dart';
class ReportDetailsScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  final String targetType;
  final String targetId;
  final Map<String, dynamic>? initialTargetDetails;
  const ReportDetailsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.targetType,
    required this.targetId,
    this.initialTargetDetails,
  });
  @override
  State<ReportDetailsScreenWeb> createState() =>
      _ReportDetailsScreenWebState();
}
class _ReportDetailsScreenWebState extends State<ReportDetailsScreenWeb> {
  late final AdminRepositoryImpl _adminRepository;
  Map<String, dynamic>? _targetDetails;
  List<Map<String, dynamic>> _reports = [];
  Map<String, List<Map<String, dynamic>>> _reportsByReason = {};
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _error = '';
  @override
  void initState() {
    super.initState();
    _adminRepository = ServiceLocator.instance.adminRepository;
    _targetDetails = widget.initialTargetDetails;
    _loadReportDetails();
  }
  Future<void> _loadReportDetails() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminRepository.getReportsByTarget(
        targetType: widget.targetType,
        targetId: widget.targetId,
      );
      if (!mounted) return;
      setState(() {
        _targetDetails = result['data']['targetDetails'] ?? _targetDetails;
        _reports =
            List<Map<String, dynamic>>.from(result['data']['reports'] ?? []);
        _reportsByReason = Map<String, List<Map<String, dynamic>>>.from(
          (result['data']['reportsByReason'] ?? {}).map(
            (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(value),
            ),
          ),
        );
        _stats = result['data']['stats'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  Future<void> _deleteContent() async {
    try {
      await _adminRepository.deleteContent(
        targetType: widget.targetType,
        targetId: widget.targetId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contenu supprimé avec succès')),
      );
      widget.onNavigate('/admin/reports');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  Future<void> _dismissReports() async {
    try {
      await _adminRepository.dismissReports(
        targetType: widget.targetType,
        targetId: widget.targetId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalements rejetés avec succès')),
      );
      widget.onNavigate('/admin/reports');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? _buildErrorView(colorScheme)
                  : _buildContent(colorScheme),
        ),
      ),
    );
  }
  Widget _buildErrorView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: WebTheme.lg),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WebTheme.sm),
          Text(
            _error,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: WebTheme.xl),
          FilledButton.icon(
            onPressed: () => widget.onNavigate('/admin/reports'),
            icon: Icon(Icons.arrow_back),
            label: const Text('Retour aux signalements'),
          ),
        ],
      ),
    );
  }
  Widget _buildContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => widget.onNavigate('/admin/reports'),
              ),
              const SizedBox(width: WebTheme.md),
              Icon(Icons.flag, size: 32, color: colorScheme.primary),
              const SizedBox(width: WebTheme.md),
              Text(
                'Détails du signalement',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: WebTheme.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildTargetCard(colorScheme),
              ),
              const SizedBox(width: WebTheme.lg),
              Expanded(
                flex: 1,
                child: _buildReportsCard(colorScheme),
              ),
            ],
          ),
          const SizedBox(height: WebTheme.lg),
          _buildActionsCard(colorScheme),
        ],
      ),
    );
  }
  Widget _buildTargetCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contenu signalé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.md),
            _buildTargetContent(colorScheme),
          ],
        ),
      ),
    );
  }
  Widget _buildTargetContent(ColorScheme colorScheme) {
    if (_targetDetails == null) {
      return const Text('Aucune information disponible');
    }
    return ReportTargetContent(
      targetType: widget.targetType,
      targetDetails: _targetDetails!,
      isCompact: false,
    );
  }
  Widget _buildReportsCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signalements (${_reports.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.md),
            if (_stats.isNotEmpty) ...[
              _buildStatRow('Total', _stats['total']?.toString() ?? '0',
                  colorScheme),
              _buildStatRow('Dernières 24h',
                  _stats['last24h']?.toString() ?? '0', colorScheme),
              const Divider(height: WebTheme.lg),
            ],
            ..._reportsByReason.entries.map((entry) {
              return _buildReasonSection(entry.key, entry.value, colorScheme);
            }),
          ],
        ),
      ),
    );
  }
  Widget _buildStatRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  Widget _buildReasonSection(String reason,
      List<Map<String, dynamic>> reports, ColorScheme colorScheme) {
    final reasonLabel = ReportHelpers.getReasonLabel(reason);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$reasonLabel (${reports.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: WebTheme.sm),
        ...reports.take(3).map((report) {
          final date = DateHelpers.formatDate(report['createdAt']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.person,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '@${report['reporter']?['username'] ?? 'anonyme'} - $date',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (reports.length > 3)
          Text(
            '+ ${reports.length - 3} autre(s)',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: WebTheme.md),
      ],
    );
  }
  Widget _buildActionsCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions de modération',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showDeleteDialog(),
                    icon: Icon(Icons.delete),
                    label: const Text('Supprimer le contenu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.all(WebTheme.md),
                    ),
                  ),
                ),
                const SizedBox(width: WebTheme.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDismissDialog(),
                    icon: Icon(Icons.close),
                    label: const Text('Rejeter les signalements'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(WebTheme.md),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contenu'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer définitivement ce contenu ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteContent();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
  void _showDismissDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter les signalements'),
        content: const Text(
          'Voulez-vous rejeter tous les signalements concernant ce contenu ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _dismissReports();
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}