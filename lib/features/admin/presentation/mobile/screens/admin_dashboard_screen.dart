import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:intl/intl.dart';
import 'admin_journalists_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
import 'package:thot/shared/utils/color_utils.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/constants/spacing_constants.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminRepositoryImpl _adminRepository;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _error = '';
  @override
  void initState() {
    super.initState();
    _adminRepository = ServiceLocator.instance.adminRepository;
    _loadStats();
  }
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _adminRepository.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = response['data'] ?? response ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du chargement des statistiques';
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: ResponsiveUtils.isMobile(context)
          ? AppBar(
              title: const Text('Administration'),
              centerTitle: true,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: ResponsiveUtils.getAdaptiveIconSize(context,
                            small: 48, medium: 56, large: 64),
                        color: AppColors.red
                      ),
                      SizedBox(
                          height: ResponsiveUtils.getAdaptiveSpacing(context,
                              mobile: 12, tablet: 16, desktop: 20)),
                      Text(_error),
                      SizedBox(
                          height: ResponsiveUtils.getAdaptiveSpacing(context,
                              mobile: 12, tablet: 16, desktop: 20)),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                        ResponsiveUtils.getAdaptiveMargin(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: theme.primaryColor,
                          child: Padding(
                            padding: EdgeInsets.all(
                                ResponsiveUtils.getAdaptiveCardPadding(
                                    context)),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius:
                                      ResponsiveUtils.getAdaptiveAvatarRadius(
                                          context),
                                  backgroundColor: ColorUtils.ensureContrast(
                                      Colors.white, theme.primaryColor),
                                  child: Text(
                                    authProvider.userProfile?.name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        'A',
                                    style: TextStyle(
                                      color: ColorUtils.ensureContrast(
                                          theme.primaryColor, Colors.white),
                                      fontSize:
                                          ResponsiveUtils.getAdaptiveFontSize(
                                              context, 16),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: ResponsiveUtils.getAdaptiveSpacing(
                                        context,
                                        mobile: 12,
                                        tablet: 16,
                                        desktop: 20)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bonjour ${authProvider.userProfile?.name ?? 'Admin'}',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils
                                              .getAdaptiveFontSize(context, 18),
                                          fontWeight: FontWeight.bold,
                                          color: ColorUtils.ensureContrast(
                                              Colors.white, theme.primaryColor),
                                        ),
                                      ),
                                      Text(
                                        'Dernière mise à jour : ${DateFormat('HH:mm').format(DateTime.now())}',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils
                                              .getAdaptiveFontSize(context, 14),
                                          color: ColorUtils.ensureContrast(
                                              Colors.white.withOpacity(0.9),
                                              theme.primaryColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space24),
                        Text(
                          'Statistiques',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount =
                                ResponsiveUtils.getAdaptiveGridCount(context);
                            double childAspectRatio;
                            if (width <= 360) {
                              childAspectRatio = 0.95;
                            } else if (width <= 600) {
                              childAspectRatio = 1.15;
                            } else {
                              childAspectRatio = 1.1;
                            }
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing:
                                  ResponsiveUtils.getAdaptiveSpacingSimple(
                                      context),
                              crossAxisSpacing:
                                  ResponsiveUtils.getAdaptiveSpacingSimple(
                                      context),
                              childAspectRatio: childAspectRatio,
                              children: [
                                _buildStatCard(
                                  title: 'Utilisateurs',
                                  value: _formatNumber(
                                      _stats['overview']?['totalUsers'] ?? 0),
                                  icon: Icons.group,
                                  color: AppColors.info,
                                  subtitle:
                                      'Actifs: ${_formatNumber(_stats['overview']?['activeUsers'] ?? 0)} | Bannis: ${_formatNumber(_stats['overview']?['bannedUsers'] ?? 0)}',
                                  isCompact: width <= 360,
                                ),
                                _buildStatCard(
                                  title: 'Journalistes',
                                  value: _formatNumber(_stats['overview']
                                          ?['totalJournalists'] ??
                                      0),
                                  icon: Icons.verified,
                                  color: AppColors.success,
                                  subtitle:
                                      'Vérifiés: ${_formatNumber(_stats['overview']?['verifiedJournalists'] ?? 0)}',
                                  isCompact: width <= 360,
                                ),
                                _buildStatCard(
                                  title: 'Articles',
                                  value: _formatNumber(
                                      _stats['overview']?['totalPosts'] ?? 0),
                                  icon: Icons.article,
                                  color: AppColors.warning,
                                  subtitle:
                                      'Cette semaine: ${_formatNumber(_stats['content']?['postsThisWeek'] ?? 0)}',
                                  isCompact: width <= 360,
                                ),
                                _buildStatCard(
                                  title: 'Engagement',
                                  value:
                                      '${_stats['engagement']?['engagementRate'] ?? 0}%',
                                  icon: Icons.trending_up,
                                  color: AppColors.purple,
                                  subtitle: 'Taux moyen',
                                  isCompact: width <= 360,
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: SpacingConstants.space24),
                        Text(
                          'Actions rapides',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: SpacingConstants.space16),
                        _buildActionCard(
                          title: 'Journalistes en attente',
                          subtitle:
                              '${_formatNumber(_stats['pendingJournalists'] ?? 0)} demandes à examiner',
                          icon: Icons.schedule,
                          color: AppColors.warning,
                          onTap: () {
                            SafeNavigation.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminJournalistsScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: SpacingConstants.space12),
                        _buildActionCard(
                          title: 'Signalements récents',
                          subtitle:
                              '${_formatNumber(_stats['reports']?['pending'] ?? 0)} en attente',
                          icon: Icons.warning,
                          color: AppColors.red,
                          onTap: () {
                            SafeNavigation.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminReportsScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: SpacingConstants.space12),
                        _buildActionCard(
                          title: 'Nouveaux utilisateurs',
                          subtitle:
                              '${_formatNumber(_stats['growth']?['newUsersToday'] ?? 0)} aujourd\'hui',
                          icon: Icons.person_add,
                          color: AppColors.info,
                          onTap: () {
                            SafeNavigation.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminUsersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool isCompact = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 6 : 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isCompact ? 20 : 24, color: color),
            SizedBox(height: isCompact ? 2 : 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 1 : 2),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: isCompact ? 0 : 1),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getAdaptiveFontSize(
                        context, isCompact ? 8 : 10),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getAdaptiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14)),
                decoration: BoxDecoration(
                  color: ColorUtils.getSafeAccentColor(context, color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: ColorUtils.ensureContrast(
                      color, Theme.of(context).colorScheme.surface),
                  size: ResponsiveUtils.getAdaptiveIconSize(context),
                ),
              ),
              SizedBox(width: SpacingConstants.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 14),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.6),
                size: ResponsiveUtils.getAdaptiveIconSize(context,
                    small: 14, medium: 16, large: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    int number;
    if (value is String) {
      number = int.tryParse(value) ?? 0;
    } else if (value is num) {
      number = value.toInt();
    } else {
      return '0';
    }
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}