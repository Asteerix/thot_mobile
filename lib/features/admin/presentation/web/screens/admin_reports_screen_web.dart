import 'package:flutter/material.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/responsive_layout.dart';
class AdminReportsScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const AdminReportsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<AdminReportsScreenWeb> createState() => _AdminReportsScreenWebState();
}
enum ReportType { all, post, comment, user, message }
enum ReportStatus { all, pending, reviewed, resolved, dismissed }
class _AdminReportsScreenWebState extends State<AdminReportsScreenWeb> {
  bool _isLoading = false;
  ReportType _selectedType = ReportType.all;
  ReportStatus _selectedStatus = ReportStatus.all;
  String _sortColumn = 'date';
  bool _sortAscending = false;
  final Set<String> _selectedReports = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  @override
  void initState() {
    super.initState();
    _loadReports();
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  void _handleBulkAction(String action) async {
    if (_selectedReports.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action ${_selectedReports.length} reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    setState(() => _selectedReports.clear());
  }
  void _handleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: ResponsiveLayout(
        builder: (context, deviceType) {
          if (deviceType == DeviceType.mobile) {
            return _buildMobileLayout(context, colorScheme);
          }
          return _buildDesktopLayout(context, colorScheme, deviceType);
        },
      ),
    );
  }
  Widget _buildMobileLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(WebTheme.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, colorScheme),
              const SizedBox(height: WebTheme.md),
              _buildSearchBar(context, colorScheme),
              const SizedBox(height: WebTheme.md),
              _buildFilters(context, colorScheme),
            ],
          ),
        ),
        Expanded(
          child: _buildReportsList(context, colorScheme),
        ),
      ],
    );
  }
  Widget _buildDesktopLayout(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    final isLargeScreen = deviceType == DeviceType.largeDesktop;
    final maxWidth = isLargeScreen ? 1600.0 : WebTheme.maxContentWidth;
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(
          isLargeScreen ? WebTheme.xxxl : WebTheme.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, colorScheme),
            const SizedBox(height: WebTheme.xl),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSearchBar(context, colorScheme),
                ),
                const SizedBox(width: WebTheme.lg),
                Expanded(
                  child: _buildFilters(context, colorScheme),
                ),
              ],
            ),
            const SizedBox(height: WebTheme.lg),
            if (_selectedReports.isNotEmpty)
              _buildBulkActionsBar(context, colorScheme),
            const SizedBox(height: WebTheme.lg),
            Expanded(
              child: _buildReportsTable(context, colorScheme, deviceType),
            ),
            const SizedBox(height: WebTheme.lg),
            _buildPagination(context, colorScheme),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports Management',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: WebTheme.xs),
            Text(
              'Review and manage user reports',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _loadReports,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: WebTheme.lg,
              vertical: WebTheme.md,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: WebTheme.inputHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search reports...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurface),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.md,
          ),
        ),
        style: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }
  Widget _buildFilters(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            context,
            colorScheme,
            'Type',
            _selectedType.toString().split('.').last,
            ReportType.values.map((e) => e.toString().split('.').last).toList(),
            (value) {
              setState(() {
                _selectedType = ReportType.values.firstWhere(
                  (e) => e.toString().split('.').last == value,
                );
              });
            },
          ),
        ),
        const SizedBox(width: WebTheme.md),
        Expanded(
          child: _buildDropdown(
            context,
            colorScheme,
            'Status',
            _selectedStatus.toString().split('.').last,
            ReportStatus.values
                .map((e) => e.toString().split('.').last)
                .toList(),
            (value) {
              setState(() {
                _selectedStatus = ReportStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == value,
                );
              });
            },
          ),
        ),
      ],
    );
  }
  Widget _buildDropdown(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: WebTheme.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
        dropdownColor: colorScheme.surface,
        style: TextStyle(color: colorScheme.onSurface),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item.substring(0, 1).toUpperCase() + item.substring(1),
              style: TextStyle(color: colorScheme.onSurface),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }
  Widget _buildBulkActionsBar(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WebTheme.md),
        child: Row(
          children: [
            Text(
              '${_selectedReports.length} reports selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _handleBulkAction('Approve'),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success
              ),
            ),
            const SizedBox(width: WebTheme.sm),
            TextButton.icon(
              onPressed: () => _handleBulkAction('Dismiss'),
              icon: const Icon(Icons.close),
              label: const Text('Dismiss'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange,
              ),
            ),
            const SizedBox(width: WebTheme.sm),
            TextButton.icon(
              onPressed: () => _handleBulkAction('Delete'),
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.red
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildReportsList(BuildContext context, ColorScheme colorScheme) {
    final reports = _getMockReports();
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.xs,
          ),
          child: ListTile(
            leading: Icon(
              _getReportTypeIcon(report.type),
              color: _getReportStatusColor(report.status),
            ),
            title: Text(report.title),
            subtitle: Text('${report.reporter} • ${report.date}'),
            trailing: _buildStatusChip(context, colorScheme, report.status),
            onTap: () {
            },
          ),
        );
      },
    );
  }
  Widget _buildReportsTable(
    BuildContext context,
    ColorScheme colorScheme,
    DeviceType deviceType,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }
    final reports = _getMockReports();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - (WebTheme.xxl * 2),
          ),
          child: DataTable(
            showCheckboxColumn: true,
            headingRowHeight: WebTheme.tableHeaderHeight,
            dataRowMinHeight: WebTheme.tableRowHeight,
            dataRowMaxHeight: WebTheme.tableRowHeight,
            columns: [
              _buildDataColumn('ID', 'id'),
              _buildDataColumn('Type', 'type'),
              _buildDataColumn('Reporter', 'reporter'),
              _buildDataColumn('Content', 'title'),
              _buildDataColumn('Date', 'date'),
              _buildDataColumn('Status', 'status'),
              const DataColumn(label: Text('Actions')),
            ],
            rows: reports.map((report) {
              final isSelected = _selectedReports.contains(report.id);
              return DataRow(
                selected: isSelected,
                onSelectChanged: (selected) {
                  setState(() {
                    if (selected ?? false) {
                      _selectedReports.add(report.id);
                    } else {
                      _selectedReports.remove(report.id);
                    }
                  });
                },
                cells: [
                  DataCell(Text(
                    report.id,
                    style: TextStyle(color: colorScheme.onSurface),
                  )),
                  DataCell(Row(
                    children: [
                      Icon(
                        _getReportTypeIcon(report.type),
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: WebTheme.xs),
                      Text(
                        report.type,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ],
                  )),
                  DataCell(Text(
                    report.reporter,
                    style: TextStyle(color: colorScheme.onSurface),
                  )),
                  DataCell(Text(
                    report.title,
                    style: TextStyle(color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(Text(
                    report.date,
                    style: TextStyle(color: colorScheme.onSurface),
                  )),
                  DataCell(
                      _buildStatusChip(context, colorScheme, report.status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility,
                              color: colorScheme.primary, size: 20),
                          onPressed: () {
                          },
                          tooltip: 'View',
                        ),
                        IconButton(
                          icon: Icon(Icons.check,
                              color: AppColors.success, size: 20),
                          onPressed: () {
                          },
                          tooltip: 'Approve',
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.close, color: AppColors.red, size: 20),
                          onPressed: () {
                          },
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  DataColumn _buildDataColumn(String label, String columnKey) {
    final isSorted = _sortColumn == columnKey;
    return DataColumn(
      label: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (isSorted)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
        ],
      ),
      onSort: (columnIndex, ascending) => _handleSort(columnKey),
    );
  }
  Widget _buildStatusChip(
    BuildContext context,
    ColorScheme colorScheme,
    String status,
  ) {
    final color = _getReportStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
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
      ),
    );
  }
  Widget _buildPagination(BuildContext context, ColorScheme colorScheme) {
    final totalPages = 5;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          icon: const Icon(Icons.chevron_left),
          color: colorScheme.onSurface,
        ),
        const SizedBox(width: WebTheme.md),
        for (int i = 1; i <= totalPages; i++) ...[
          InkWell(
            onTap: () => setState(() => _currentPage = i),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(WebTheme.borderRadiusSmall),
                border: Border.all(
                  color: _currentPage == i
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: _currentPage == i
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (i < totalPages) const SizedBox(width: WebTheme.xs),
        ],
        const SizedBox(width: WebTheme.md),
        IconButton(
          onPressed: _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
          color: colorScheme.onSurface,
        ),
      ],
    );
  }
  IconData _getReportTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'post':
        return Icons.article;
      case 'comment':
        return Icons.comment;
      case 'user':
        return Icons.person;
      case 'message':
        return Icons.message;
      default:
        return Icons.flag;
    }
  }
  Color _getReportStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.orange;
      case 'reviewed':
        return AppColors.blue;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }
  List<ReportItem> _getMockReports() {
    return [
      ReportItem(
        id: 'RPT-001',
        type: 'Post',
        reporter: 'john_doe',
        title: 'Inappropriate content',
        date: '2024-01-15',
        status: 'Pending',
      ),
      ReportItem(
        id: 'RPT-002',
        type: 'Comment',
        reporter: 'jane_smith',
        title: 'Spam comment',
        date: '2024-01-14',
        status: 'Reviewed',
      ),
      ReportItem(
        id: 'RPT-003',
        type: 'User',
        reporter: 'mike_chen',
        title: 'Harassment',
        date: '2024-01-13',
        status: 'Resolved',
      ),
      ReportItem(
        id: 'RPT-004',
        type: 'Message',
        reporter: 'sarah_wilson',
        title: 'Abusive language',
        date: '2024-01-12',
        status: 'Dismissed',
      ),
      ReportItem(
        id: 'RPT-005',
        type: 'Post',
        reporter: 'alex_johnson',
        title: 'Copyright violation',
        date: '2024-01-11',
        status: 'Pending',
      ),
    ];
  }
}
class ReportItem {
  final String id;
  final String type;
  final String reporter;
  final String title;
  final String date;
  final String status;
  ReportItem({
    required this.id,
    required this.type,
    required this.reporter,
    required this.title,
    required this.date,
    required this.status,
  });
}