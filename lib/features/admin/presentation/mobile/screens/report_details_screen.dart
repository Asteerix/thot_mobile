import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/constants/spacing_constants.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/features/posts/presentation/mobile/screens/post_detail_screen.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/admin/presentation/shared/widgets/stat_card.dart';
import 'package:thot/features/admin/presentation/shared/widgets/status_badge.dart';
import 'package:thot/features/admin/presentation/shared/widgets/engagement_metrics.dart';
import 'package:thot/features/admin/presentation/shared/utils/report_helpers.dart';
class ReportDetailsScreen extends StatefulWidget {
  final String targetType;
  final String targetId;
  final Map<String, dynamic>? initialTargetDetails;
  const ReportDetailsScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    this.initialTargetDetails,
  });
  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}
class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails des signalements'),
        elevation: 0,
        actions: [
          if (_targetDetails != null && widget.targetType == 'post')
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'Voir la publication',
              onPressed: () => _navigateToPost(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.red),
                      SizedBox(height: SpacingConstants.space16),
                      Text(
                        'Erreur lors du chargement',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: SpacingConstants.space8),
                      Text(_error, textAlign: TextAlign.center),
                      SizedBox(height: SpacingConstants.space16),
                      ElevatedButton(
                        onPressed: _loadReportDetails,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReportDetails,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildStatsSection(),
                      ),
                      if (_targetDetails != null)
                        SliverToBoxAdapter(
                          child: _buildTargetDetailsSection(),
                        ),
                      SliverToBoxAdapter(
                        child: _buildReportsByReasonSection(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(SpacingConstants.space16),
                          child: Text(
                            'Tous les signalements (${_reports.length})',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildReportItem(_reports[index]),
                          childCount: _reports.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: SpacingConstants.space32),
                      ),
                    ],
                  ),
                ),
    );
  }
  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.all(SpacingConstants.space16),
      child: StatsGrid(
        padding: EdgeInsets.all(SpacingConstants.space16),
        stats: [
          StatCard(
            label: 'Total',
            value: _stats['totalReports']?.toString() ?? '0',
            icon: Icons.flag,
            color: AppColors.red,
          ),
          StatCard(
            label: 'Uniques',
            value: _stats['uniqueReporters']?.toString() ?? '0',
            icon: Icons.people,
            color: AppColors.orange,
          ),
          StatCard(
            label: 'En attente',
            value: _stats['pending']?.toString() ?? '0',
            icon: Icons.pending,
            color: AppColors.warning,
          ),
          StatCard(
            label: 'Vus',
            value: _stats['reviewed']?.toString() ?? '0',
            icon: Icons.visibility,
            color: AppColors.blue,
          ),
          StatCard(
            label: 'Résolus',
            value: _stats['resolved']?.toString() ?? '0',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          StatCard(
            label: 'Ignorés',
            value: _stats['dismissed']?.toString() ?? '0',
            icon: Icons.cancel,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
  Widget _buildTargetDetailsSection() {
    final target = _targetDetails!;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: SpacingConstants.space16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SpacingConstants.space12),
      ),
      child: Padding(
        padding: EdgeInsets.all(SpacingConstants.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contenu signalé',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SpacingConstants.space12),
            if (widget.targetType == 'post') ...[
              Row(
                children: [
                  Icon(
                    PostHelpers.getPostTypeIcon(target['type']),
                    color: PostHelpers.getPostTypeColor(context, target['type']),
                    size: ResponsiveUtils.getAdaptiveIconSize(context),
                  ),
                  SizedBox(width: SpacingConstants.space8),
                  Expanded(
                    child: Text(
                      target['title'] ?? 'Sans titre',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingConstants.space8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: target['journalist']?['avatarUrl'] != null
                        ? NetworkImage(ImageUtils.getAvatarUrl(
                            target['journalist']['avatarUrl']))
                        : null,
                    child: target['journalist']?['avatarUrl'] == null
                        ? Icon(Icons.person, size: 20)
                        : null,
                  ),
                  SizedBox(width: SpacingConstants.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target['journalist']?['name'] ??
                              target['journalist']?['username'] ??
                              'Inconnu',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Publié le ${DateHelpers.formatDate(target['createdAt'])}',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingConstants.space12),
              EngagementMetrics(
                views: target['views'] ?? 0,
                likes: target['likes']?.length ?? 0,
                comments: target['comments']?.length ?? 0,
              ),
            ] else if (widget.targetType == 'comment') ...[
              Text(
                target['content'] ?? 'Commentaire supprimé',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
              SizedBox(height: SpacingConstants.space8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.outline),
                  SizedBox(width: SpacingConstants.space4),
                  Text(
                    target['author']?['name'] ?? 'Utilisateur',
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 12),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ] else if (widget.targetType == 'user') ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: target['avatarUrl'] != null
                        ? NetworkImage(
                            ImageUtils.getAvatarUrl(target['avatarUrl']))
                        : null,
                    child: target['avatarUrl'] == null
                        ? Icon(Icons.person, size: 30)
                        : null,
                  ),
                  SizedBox(width: SpacingConstants.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target['name'] ?? target['username'] ?? 'Utilisateur',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          target['email'] ?? 'Email non disponible',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildReportsByReasonSection() {
    if (_reportsByReason.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(SpacingConstants.space16),
          child: Text(
            'Signalements par raison',
            style: TextStyle(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: SpacingConstants.space16),
            itemCount: _reportsByReason.length,
            itemBuilder: (context, index) {
              final reason = _reportsByReason.keys.elementAt(index);
              final reports = _reportsByReason[reason]!;
              return Container(
                width: 150,
                margin: EdgeInsets.only(right: SpacingConstants.space12),
                padding: EdgeInsets.all(SpacingConstants.space12),
                decoration: BoxDecoration(
                  color: ReportHelpers.getReasonColor(context, reason)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SpacingConstants.space12),
                  border: Border.all(
                      color: ReportHelpers.getReasonColor(context, reason)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag,
                      color: ReportHelpers.getReasonColor(context, reason),
                      size: ResponsiveUtils.getAdaptiveIconSize(context,
                          large: 32),
                    ),
                    SizedBox(height: SpacingConstants.space8),
                    Text(
                      ReportHelpers.getReasonLabel(reason),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 12),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: SpacingConstants.space4),
                    Text(
                      '${reports.length} signalement${reports.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 10),
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildReportItem(Map<String, dynamic> report) {
    final reportedBy = report['reportedBy'];
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: SpacingConstants.space16,
        vertical: SpacingConstants.space4,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ReportHelpers.getReasonColor(context, report['reason'] ?? 'other'),
          child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
        title: Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.outline),
            SizedBox(width: SpacingConstants.space4),
            Expanded(
              child: Text(
                '${reportedBy?['name'] ?? reportedBy?['username'] ?? 'Utilisateur'}',
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14)),
              ),
            ),
            StatusBadge(
              status: report['status'],
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 10),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SpacingConstants.space4),
            Text(
              ReportHelpers.getReasonLabel(report['reason'] ?? 'other'),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: ReportHelpers.getReasonColor(
                    context, report['reason'] ?? 'other'),
              ),
            ),
            if (report['description'] != null &&
                report['description'].isNotEmpty) ...[
              SizedBox(height: SpacingConstants.space4),
              Text(
                report['description'],
                style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: SpacingConstants.space4),
            Text(
              DateHelpers.formatDate(report['createdAt']),
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 11),
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showReportDetails(report),
      ),
    );
  }
  void _showReportDetails(Map<String, dynamic> report) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(SpacingConstants.space20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(SpacingConstants.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: SpacingConstants.space20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: report['reportedBy']?['avatarUrl'] != null
                        ? NetworkImage(ImageUtils.getAvatarUrl(
                            report['reportedBy']['avatarUrl']))
                        : null,
                    child: report['reportedBy']?['avatarUrl'] == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                  SizedBox(width: SpacingConstants.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signalé par',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          report['reportedBy']?['name'] ??
                              report['reportedBy']?['username'] ??
                              'Utilisateur',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          report['reportedBy']?['email'] ?? '',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingConstants.space24),
              Container(
                padding: EdgeInsets.all(SpacingConstants.space12),
                decoration: BoxDecoration(
                  color: ReportHelpers.getReasonColor(context, report['reason'] ?? 'other')
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SpacingConstants.space8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: ReportHelpers.getReasonColor(
                          context, report['reason'] ?? 'other'),
                    ),
                    SizedBox(width: SpacingConstants.space8),
                    Text(
                      ReportHelpers.getReasonLabel(report['reason'] ?? 'other'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ReportHelpers.getReasonColor(
                            context, report['reason'] ?? 'other'),
                      ),
                    ),
                  ],
                ),
              ),
              if (report['description'] != null &&
                  report['description'].isNotEmpty) ...[
                SizedBox(height: SpacingConstants.space16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SpacingConstants.space8),
                Text(
                  report['description'],
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14)),
                ),
              ],
              SizedBox(height: SpacingConstants.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signalé le',
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getAdaptiveFontSize(context, 12),
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Text(
                        DateHelpers.formatDate(report['createdAt']),
                        style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 14)),
                      ),
                    ],
                  ),
                  if (report['reviewedAt'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Examiné le',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Text(
                          DateHelpers.formatDate(report['reviewedAt']),
                          style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 14)),
                        ),
                      ],
                    ),
                ],
              ),
              if (report['reviewedBy'] != null) ...[
                SizedBox(height: SpacingConstants.space16),
                Text(
                  'Examiné par: ${report['reviewedBy']['name'] ?? report['reviewedBy']['username']}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
              if (report['actionTaken'] != null) ...[
                SizedBox(height: SpacingConstants.space16),
                Text(
                  'Action prise',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SpacingConstants.space8),
                Text(
                  report['actionTaken'],
                  style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getAdaptiveFontSize(context, 14)),
                ),
              ],
              SizedBox(height: SpacingConstants.space24),
              if (report['status'] == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          SafeNavigation.pop(context);
                          _reviewReport(report['_id'], 'dismissed');
                        },
                        child: const Text('Ignorer'),
                      ),
                    ),
                    SizedBox(width: SpacingConstants.space8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          SafeNavigation.pop(context);
                          _reviewReport(report['_id'], 'reviewed');
                        },
                        child: const Text('Marquer comme vu'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _reviewReport(String reportId, String status) async {
    try {
      await _adminRepository.reviewReport(reportId, status, null);
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text(
              'Signalement ${status == 'dismissed' ? 'ignoré' : 'marqué comme vu'}'),
          backgroundColor: AppColors.success
        ),
      );
      _loadReportDetails();
    } catch (e) {
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  void _navigateToPost() {
    if (_targetDetails == null || _targetDetails!['_id'] == null) return;
    SafeNavigation.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostDetailScreen(initialPostId: _targetDetails!['_id']),
      ),
    );
  }
}