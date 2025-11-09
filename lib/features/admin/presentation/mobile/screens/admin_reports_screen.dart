import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/constants/spacing_constants.dart';
import 'package:thot/shared/utils/color_utils.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:intl/intl.dart';
import 'package:thot/features/posts/presentation/mobile/screens/post_detail_screen.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'report_details_screen.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/profile/presentation/mobile/screens/user_profile_screen.dart';
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}
class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late final AdminRepositoryImpl _adminRepository;
  late TabController _tabController;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String _currentStatus = 'pending';
  @override
  void initState() {
    super.initState();
    _adminRepository = ServiceLocator.instance.adminRepository;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReportedContent();
  }
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadReportedContent();
  }
  Future<void> _loadReportedContent() async {
    setState(() => _isLoading = true);
    try {
      String targetType;
      if (_tabController.index == 0) {
        targetType = 'post';
      } else if (_tabController.index == 1) {
        targetType = 'comment';
      } else {
        targetType = 'user';
      }
      final reportsList = await _adminRepository.getReports(
        status: _currentStatus,
        targetType: targetType,
        page: 1,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _reports = reportsList.map((report) => report.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SafeNavigation.showSnackBar(
        context,
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtils.isMobile(context)
          ? AppBar(
              title: const Text('Gestion des signalements'),
              centerTitle: true,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.filter),
                  onSelected: (status) {
                    setState(() {
                      _currentStatus = status;
                    });
                    _loadReportedContent();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pending',
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty,
                              color: _currentStatus == 'pending'
                                  ? Theme.of(context).primaryColor
                                  : null),
                          const SizedBox(width: 8),
                          Text('En attente'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reviewed',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: _currentStatus == 'reviewed'
                                  ? Theme.of(context).primaryColor
                                  : null),
                          const SizedBox(width: 8),
                          Text('Vus'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'resolved',
                      child: Row(
                        children: [
                          Icon(Icons.done_all,
                              color: _currentStatus == 'resolved'
                                  ? Theme.of(context).primaryColor
                                  : null),
                          const SizedBox(width: 8),
                          Text('Résolus'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'dismissed',
                      child: Row(
                        children: [
                          Icon(Icons.close,
                              color: _currentStatus == 'dismissed'
                                  ? Theme.of(context).primaryColor
                                  : null),
                          const SizedBox(width: 8),
                          Text('Ignorés'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Publications'),
                        if (_tabController.index == 0 && _reports.isNotEmpty)
                          Text(
                            '${_reports.length} signalements',
                            style: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  const Tab(text: 'Commentaires'),
                  const Tab(text: 'Utilisateurs'),
                ],
              ),
            )
          : null,
      body: IndexedStack(
        index: _tabController.index,
        children: [
          _buildReportedPostsList(),
          _buildReportedCommentsList(),
          _buildReportedUsersList(),
        ],
      ),
    );
  }
  Widget _buildReportedPostsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag,
                size: ResponsiveUtils.getAdaptiveIconSize(context, large: 64),
                color: Theme.of(context).colorScheme.outline),
            SizedBox(height: SpacingConstants.space16),
            Text(
              'Aucun signalement en attente',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadReportedContent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final post = report['targetDetails'];
          if (post == null) return const SizedBox();
          final reason = report['reason'] ?? 'other';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: report['status'] == 'pending'
                  ? BorderSide(color: AppColors.orange.withOpacity(0.5), width: 1)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () => _showReportDetails(report),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveCardPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getReasonColor(reason),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag,
                                    color: Theme.of(context).colorScheme.surface, size: 16),
                                SizedBox(width: SpacingConstants.space4),
                                Flexible(
                                  child: Text(
                                    _getReasonLabel(reason),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: SpacingConstants.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPostTypeColor(post['type'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPostTypeIcon(post['type']),
                                size: 16,
                                color: _getPostTypeColor(post['type']),
                              ),
                              SizedBox(width: SpacingConstants.space4),
                              Text(
                                _getPostTypeLabel(post['type']),
                                style: TextStyle(
                                  color: _getPostTypeColor(post['type']),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: SpacingConstants.space8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                _navigateToPost(post);
                                break;
                              case 'review':
                                _reviewReport(report, 'reviewed');
                                break;
                              case 'resolve':
                                _reviewReport(report, 'resolved');
                                break;
                              case 'dismiss':
                                _reviewReport(report, 'dismissed');
                                break;
                              case 'delete':
                                _showDeleteConfirmation(post);
                                break;
                              case 'ban':
                                _showBanUserConfirmation(post);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.visibility),
                                title: Text('Voir le post'),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'review',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.check_circle,
                                    color: AppColors.blue),
                                title: Text('Marquer comme vu'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'resolve',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.check_circle,
                                    color: AppColors.success),
                                title: Text('Résoudre'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'dismiss',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.close, color: Theme.of(context).colorScheme.outline),
                                title: Text('Ignorer'),
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.delete, color: AppColors.red),
                                title: Text('Supprimer le post',
                                    style: TextStyle(color: AppColors.red)),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ban',
                              child: ListTile(
                                dense: true,
                                leading:
                                    Icon(Icons.block, color: AppColors.orange),
                                title: Text('Bannir l\'auteur',
                                    style: TextStyle(color: AppColors.orange)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: SpacingConstants.space12),
                    Text(
                      post['title'] ?? 'Sans titre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: SpacingConstants.space8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              post['journalist']?['avatarUrl'] != null
                                  ? NetworkImage(ImageUtils.getAvatarUrl(
                                      post['journalist']['avatarUrl']))
                                  : null,
                          child: post['journalist']?['avatarUrl'] == null
                              ? Icon(Icons.person,
                                  size: ResponsiveUtils.getAdaptiveIconSize(
                                      context,
                                      small: 16))
                              : null,
                        ),
                        SizedBox(width: SpacingConstants.space8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${post['journalist']?['name'] ?? ''} ${post['journalist']?['username'] != null ? "(@${post['journalist']['username']})" : ''}'
                                    .trim(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 14),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDate(post['createdAt']),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                      context, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (report['description'] != null &&
                        report['description'].isNotEmpty) ...[
                      SizedBox(height: SpacingConstants.space12),
                      Container(
                        padding: EdgeInsets.all(SpacingConstants.space8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          borderRadius:
                              BorderRadius.circular(SpacingConstants.space8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description du signalement:',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: SpacingConstants.space4),
                            Text(
                              report['description'],
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
                    SizedBox(height: SpacingConstants.space8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: 16, color: Theme.of(context).colorScheme.outline),
                              SizedBox(width: SpacingConstants.space4),
                              Flexible(
                                child: Text(
                                  'Par ${report['reportedBy']?['name'] ?? report['reportedBy']?['username'] ?? 'Utilisateur'}',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.getAdaptiveFontSize(
                                            context, 12),
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: SpacingConstants.space8),
                        InkWell(
                          onTap: () => _navigateToReportDetails(post),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SpacingConstants.space8,
                              vertical: SpacingConstants.space4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                  SpacingConstants.space12),
                              border: Border.all(color: AppColors.red.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flag,
                                    size: 14, color: AppColors.red),
                                SizedBox(width: SpacingConstants.space4),
                                Text(
                                  '${post['reportCount'] ?? 1}',
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveUtils.getAdaptiveFontSize(
                                            context, 12),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: SpacingConstants.space8),
                        Text(
                          _formatDate(report['createdAt']),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 11),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildReportedCommentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum,
                size: ResponsiveUtils.getAdaptiveIconSize(context, large: 64),
                color: Theme.of(context).colorScheme.outline),
            SizedBox(height: SpacingConstants.space16),
            Text(
              'Aucun commentaire signalé',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadReportedContent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final comment = report['targetDetails'];
          if (comment == null) return const SizedBox();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getReasonColor(report['reason'] ?? 'other'),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 16),
              ),
              title: Text(
                comment['content'] ?? 'Commentaire supprimé',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Signalé par ${report['reportedBy']?['name'] ?? 'Utilisateur'} - ${_formatDate(report['createdAt'])}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleCommentAction(value, report, comment),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'review', child: Text('Marquer comme vu')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Supprimer')),
                  const PopupMenuItem(value: 'dismiss', child: Text('Ignorer')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildReportedUsersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off,
                size: ResponsiveUtils.getAdaptiveIconSize(context, large: 64),
                color: Theme.of(context).colorScheme.outline),
            SizedBox(height: SpacingConstants.space16),
            Text(
              'Aucun utilisateur signalé',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadReportedContent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final user = report['targetDetails'];
          if (user == null) return const SizedBox();
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: user['avatarUrl'] != null
                    ? NetworkImage(ImageUtils.getAvatarUrl(user['avatarUrl']))
                    : null,
                child:
                    user['avatarUrl'] == null ? Icon(Icons.person) : null,
              ),
              title: Text(user['name'] ?? user['username'] ?? 'Utilisateur'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getReasonLabel(report['reason'] ?? 'other')),
                  Text(
                    'Signalé par ${report['reportedBy']?['name'] ?? 'Utilisateur'} - ${_formatDate(report['createdAt'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleUserAction(value, report, user),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'view', child: Text('Voir le profil')),
                  const PopupMenuItem(
                      value: 'suspend', child: Text('Suspendre')),
                  const PopupMenuItem(value: 'ban', child: Text('Bannir')),
                  const PopupMenuItem(value: 'dismiss', child: Text('Ignorer')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'spam':
        return AppColors.purple;
      case 'harassment':
        return AppColors.red;
      case 'hate_speech':
        return AppColors.red;
      case 'violence':
        return Colors.deepOrange;
      case 'false_information':
        return AppColors.orange;
      case 'inappropriate_content':
        return AppColors.warning;
      case 'copyright':
        return AppColors.blue;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
  void _handleCommentAction(String action, Map<String, dynamic> report,
      Map<String, dynamic> comment) async {
    switch (action) {
      case 'review':
        await _reviewReport(report, 'reviewed');
        break;
      case 'delete':
        try {
          await _adminRepository.deleteComment(comment['_id'],
              reason: 'Violation des règles');
          await _reviewReport(report, 'resolved');
          if (!mounted) return;
          SafeNavigation.showSnackBar(
            context,
            const SnackBar(
                content: Text('Commentaire supprimé'),
                backgroundColor: AppColors.success),
          );
        } catch (e) {
          if (!mounted) return;
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
                content: Text('Erreur: ${e.toString()}'),
                backgroundColor: AppColors.red),
          );
        }
        break;
      case 'dismiss':
        await _reviewReport(report, 'dismissed');
        break;
    }
  }
  void _handleUserAction(String action, Map<String, dynamic> report,
      Map<String, dynamic> user) async {
    switch (action) {
      case 'view':
        final userProfile = UserProfile.fromJson(user);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userProfile: userProfile),
          ),
        );
        break;
      case 'suspend':
        await _adminRepository.suspendUser(user['_id'],
            reason: 'Violation des règles communautaires', duration: 7);
        await _reviewReport(report, 'resolved');
        break;
      case 'ban':
        await _adminRepository.banUser(
          user['_id'],
          const Duration(days: 30),
        );
        await _reviewReport(report, 'resolved');
        break;
      case 'dismiss':
        await _reviewReport(report, 'dismissed');
        break;
    }
  }
  String _getReasonLabel(String reason) {
    switch (reason) {
      case 'spam':
        return 'Spam';
      case 'harassment':
        return 'Harcèlement';
      case 'hate_speech':
        return 'Discours de haine';
      case 'violence':
        return 'Violence';
      case 'false_information':
        return 'Fausse information';
      case 'inappropriate_content':
        return 'Contenu inapproprié';
      case 'copyright':
        return 'Violation du droit d\'auteur';
      case 'other':
        return 'Autre';
      default:
        return reason;
    }
  }
  void _navigateToReportDetails(Map<String, dynamic> post) {
    SafeNavigation.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(
          targetType: 'post',
          targetId: post['_id'] ?? post['id'],
          initialTargetDetails: post,
        ),
      ),
    );
  }
  void _showReportDetails(Map<String, dynamic> report) {
    final post = report['targetDetails'];
    SafeNavigation.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(SpacingConstants.space20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: ResponsiveUtils.isMobile(context) ? 0.9 : 0.8,
        minChildSize: ResponsiveUtils.isMobile(context) ? 0.4 : 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding(context)),
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
                    borderRadius:
                        BorderRadius.circular(SpacingConstants.space4 * 0.5),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(
                    ResponsiveUtils.getAdaptiveCardPadding(context)),
                decoration: BoxDecoration(
                  color: ColorUtils.getSafeAccentColor(context, AppColors.red),
                  borderRadius: BorderRadius.circular(SpacingConstants.space12),
                  border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.red
                          : AppColors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag,
                        color: ColorUtils.ensureContrast(AppColors.red,
                            ColorUtils.getSafeAccentColor(context, AppColors.red)),
                        size: ResponsiveUtils.getAdaptiveIconSize(context,
                            large: 32)),
                    SizedBox(width: SpacingConstants.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${post['reportCount'] ?? 1} signalement${(post['reportCount'] ?? 1) > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 20),
                              fontWeight: FontWeight.bold,
                              color: ColorUtils.ensureContrast(
                                  AppColors.red,
                                  ColorUtils.getSafeAccentColor(
                                      context, AppColors.red)),
                            ),
                          ),
                          Text(
                            'Cette publication a été signalée${(post['reportCount'] ?? 1) > 1 ? ' plusieurs fois' : ''}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 12),
                              color: ColorUtils.ensureContrast(
                                  AppColors.red,
                                  ColorUtils.getSafeAccentColor(
                                      context, AppColors.red)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: ColorUtils.ensureContrast(AppColors.red,
                            ColorUtils.getSafeAccentColor(context, AppColors.red)),
                      ),
                      onPressed: () {
                        SafeNavigation.pop(context);
                        _navigateToReportDetails(post);
                      },
                      tooltip: 'Voir tous les signalements',
                    ),
                  ],
                ),
              ),
              SizedBox(height: SpacingConstants.space20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getPostTypeColor(post['type']),
                    child: Icon(
                      _getPostTypeIcon(post['type']),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  SizedBox(width: SpacingConstants.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title'] ?? 'Sans titre',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space4),
                        Text(
                          'Type: ${_getPostTypeLabel(post['type'])}',
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SpacingConstants.space24),
              _buildDetailSection('Auteur de la publication', [
                _DetailItem(
                    Icons.person,
                    'Nom complet',
                    (post['journalist']?['name'] ?? 'Non renseigné')
                        .toString()),
                _DetailItem(Icons.alternate_email, 'Nom d\'utilisateur',
                    (post['journalist']?['username'] ?? 'N/A').toString()),
                _DetailItem(Icons.mail, 'Email',
                    (post['journalist']?['email'] ?? 'N/A').toString()),
                if (post['journalist']?['verified'] == true)
                  _DetailItem(Icons.verified, 'Statut', 'Journaliste vérifié'),
                _DetailItem(Icons.fingerprint, 'ID',
                    (post['journalist']?['_id'] ?? 'N/A').toString()),
              ]),
              SizedBox(height: SpacingConstants.space20),
              _buildDetailSection('Publication', [
                _DetailItem(Icons.calendar_today, 'Créé le',
                    _formatDate(post['createdAt'])),
                _DetailItem(Icons.visibility, 'Vues', '${post['views'] ?? 0}'),
                _DetailItem(
                    Icons.favorite, 'Likes', '${post['likes']?.length ?? 0}'),
                _DetailItem(Icons.comment, 'Commentaires',
                    '${post['comments']?.length ?? 0}'),
              ]),
              if (report['description'] != null &&
                  report['description'].isNotEmpty) ...[
                SizedBox(height: SpacingConstants.space20),
                Text(
                  'Description du signalement actuel',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: SpacingConstants.space12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(SpacingConstants.space12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(SpacingConstants.space8),
                    border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerLowest),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: ResponsiveUtils.getAdaptiveIconSize(context,
                                  small: 16),
                              color: Theme.of(context).colorScheme.outline),
                          SizedBox(width: SpacingConstants.space4),
                          Expanded(
                            child: Text(
                              '${report['reportedBy']?['name'] ?? report['reportedBy']?['username'] ?? 'Utilisateur'}',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                    context, 12),
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(report['createdAt']),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                  context, 11),
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SpacingConstants.space8),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SpacingConstants.space8,
                            vertical: SpacingConstants.space4),
                        decoration: BoxDecoration(
                          color: _getReasonColor(report['reason'] ?? 'other')
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(SpacingConstants.space12),
                        ),
                        child: Text(
                          _getReasonLabel(report['reason'] ?? 'other'),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _getReasonColor(report['reason'] ?? 'other'),
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                          ),
                        ),
                      ),
                      SizedBox(height: SpacingConstants.space8),
                      Text(
                        report['description'],
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getAdaptiveFontSize(context, 14),
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: SpacingConstants.space24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      SafeNavigation.pop(context);
                      _navigateToPost(post);
                    },
                    icon: Icon(Icons.visibility),
                    label: const Text('Voir la publication complète'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: SpacingConstants.space12),
                    ),
                  ),
                  SizedBox(height: SpacingConstants.space8),
                  ElevatedButton.icon(
                    onPressed: () {
                      SafeNavigation.pop(context);
                      _showDeleteConfirmation(post);
                    },
                    icon: Icon(Icons.delete),
                    label: const Text('Supprimer la publication'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: EdgeInsets.symmetric(
                          vertical: SpacingConstants.space12),
                    ),
                  ),
                  SizedBox(height: SpacingConstants.space8),
                  OutlinedButton.icon(
                    onPressed: () {
                      SafeNavigation.pop(context);
                      _showBanUserConfirmation(post);
                    },
                    icon: Icon(Icons.block),
                    label: const Text('Bannir l\'auteur'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      padding: EdgeInsets.symmetric(
                          vertical: SpacingConstants.space12),
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
  void _navigateToPost(Map<String, dynamic> postData) {
    final postId = postData['_id'] ?? postData['id'];
    if (postId == null) {
      SafeNavigation.showSnackBar(
        context,
        const SnackBar(
          content: Text('Impossible d\'ouvrir le post'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    SafeNavigation.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(initialPostId: postId),
      ),
    );
  }
  Future<void> _showDeleteConfirmation(Map<String, dynamic> post) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cette publication a ${post['reportCount']} signalements. '
              'Êtes-vous sûr de vouloir la supprimer définitivement?',
            ),
            SizedBox(height: SpacingConstants.space16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de la suppression*',
                hintText: 'Ex: Contenu inapproprié, violation des règles...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _adminRepository.deletePost(
          post['_id'],
          reason: reasonController.text,
          notifyAuthor: true,
        );
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Publication supprimée avec succès'),
            backgroundColor: AppColors.success
          ),
        );
        _loadReportedContent();
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
  }
  Future<void> _reviewReport(Map<String, dynamic> report, String status) async {
    try {
      await _adminRepository.reviewReport(
        report['_id'],
        status,
        status == 'resolved' ? 'Content deleted' : null,
      );
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Signalement marqué comme $status'),
          backgroundColor: AppColors.success
        ),
      );
      _loadReportedContent();
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
  Future<void> _showBanUserConfirmation(Map<String, dynamic> post) async {
    final journalist = post['journalist'];
    if (journalist == null) return;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bannir l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voulez-vous bannir ${journalist['name'] ?? journalist['username'] ?? 'cet utilisateur'} ? '
              'Cette action est permanente.',
            ),
            SizedBox(height: SpacingConstants.space16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du bannissement*',
                hintText: 'Ex: Publications répétées inappropriées...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => SafeNavigation.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
            ),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _adminRepository.banUser(
          journalist['_id'],
          const Duration(days: 30),
        );
        if (!mounted) return;
        SafeNavigation.showSnackBar(
          context,
          const SnackBar(
            content: Text('Utilisateur banni avec succès'),
            backgroundColor: AppColors.orange,
          ),
        );
        _loadReportedContent();
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
  }
  Color _getPostTypeColor(String? type) {
    switch (type) {
      case 'article':
        return AppColors.blue;
      case 'video':
        return AppColors.red;
      case 'podcast':
        return AppColors.purple;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }
  IconData _getPostTypeIcon(String? type) {
    switch (type) {
      case 'article':
        return Icons.article;
      case 'video':
        return Icons.videocam;
      case 'podcast':
        return Icons.mic;
      default:
        return Icons.note_add;
    }
  }
  String _getPostTypeLabel(String? type) {
    switch (type) {
      case 'article':
        return 'Article';
      case 'video':
        return 'Vidéo';
      case 'podcast':
        return 'Podcast';
      default:
        return 'Publication';
    }
  }
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: SpacingConstants.space12),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: SpacingConstants.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon,
                      size: ResponsiveUtils.getAdaptiveIconSize(context,
                          small: 20),
                      color: Theme.of(context).colorScheme.outline),
                  SizedBox(width: SpacingConstants.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 12),
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space4 * 0.5),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getAdaptiveFontSize(
                                context, 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}