import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class AdminDashboardScreenWeb extends StatelessWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const AdminDashboardScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: currentRoute,
      onNavigate: onNavigate,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: WebTheme.maxContentWidth),
          padding: const EdgeInsets.all(WebTheme.xxl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: WebTheme.xl),
                _buildStatsGrid(context, colorScheme),
                const SizedBox(height: WebTheme.xl),
                _buildRecentActivity(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildStatsGrid(BuildContext context, ColorScheme colorScheme) {
    return ResponsiveGrid(
      desktopColumns: 4,
      tabletColumns: 2,
      mobileColumns: 1,
      childAspectRatio: 2,
      children: [
        _buildStatCard(context, colorScheme, 'Total Users', '12,458', '+12%',
            Icons.group, AppColors.blue),
        _buildStatCard(context, colorScheme, 'Total Posts', '45,892', '+8%',
            Icons.article, AppColors.success),
        _buildStatCard(context, colorScheme, 'Active Reports', '23', '-5%',
            Icons.flag, AppColors.orange),
        _buildStatCard(context, colorScheme, 'Revenue', '\$89,450', '+15%',
            Icons.dollarSign, AppColors.purple),
      ],
    );
  }
  Widget _buildStatCard(
    BuildContext context,
    ColorScheme colorScheme,
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    final isPositive = change.startsWith('+');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.lg),
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
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
            const SizedBox(height: WebTheme.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: WebTheme.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? AppColors.success : AppColors.red,
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
  Widget _buildRecentActivity(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: WebTheme.lg),
            _buildActivityTable(context, colorScheme),
          ],
        ),
      ),
    );
  }
  Widget _buildActivityTable(BuildContext context, ColorScheme colorScheme) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          children: [
            _buildTableHeader(context, 'User'),
            _buildTableHeader(context, 'Action'),
            _buildTableHeader(context, 'Date'),
            _buildTableHeader(context, 'Status'),
          ],
        ),
        ...[
          ['John Doe', 'Created post', '2h ago', 'Active'],
          ['Jane Smith', 'Updated profile', '4h ago', 'Active'],
          ['Mike Chen', 'Reported content', '6h ago', 'Pending'],
          ['Sarah Wilson', 'Joined platform', '8h ago', 'Active'],
          ['Alex Johnson', 'Posted comment', '10h ago', 'Active'],
        ].map((row) => TableRow(
              children: [
                _buildTableCell(context, row[0]),
                _buildTableCell(context, row[1]),
                _buildTableCell(context, row[2]),
                _buildStatusCell(context, row[3]),
              ],
            )),
      ],
    );
  }
  Widget _buildTableHeader(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: WebTheme.tableCellPadding,
        vertical: WebTheme.md,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
  Widget _buildTableCell(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: WebTheme.tableCellPadding,
        vertical: WebTheme.md,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
  Widget _buildStatusCell(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = status == 'Active' ? AppColors.success: AppColors.orange;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: WebTheme.tableCellPadding,
        vertical: WebTheme.md,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: WebTheme.sm,
          vertical: WebTheme.xs,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}