import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/web_theme.dart';
import '../../../../../shared/widgets/web/web_scaffold.dart';
import '../../../../../shared/widgets/web/web_two_column_layout.dart' as web_layout;
import '../../../../../features/notifications/domain/entities/notification.dart';
import '../../shared/widgets/notification_filter.dart';
import '../../shared/widgets/notification_card.dart';
import '../../shared/widgets/notification_empty_state.dart';
import '../../shared/logic/notification_list_controller.dart';
class NotificationsScreenWeb extends StatefulWidget {
  final String currentRoute;
  final Function(String route) onNavigate;
  const NotificationsScreenWeb({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });
  @override
  State<NotificationsScreenWeb> createState() => _NotificationsScreenWebState();
}
class _NotificationsScreenWebState extends State<NotificationsScreenWeb> {
  NotificationFilter _selectedFilter = NotificationFilter.all;
  late final NotificationListController _controller;
  @override
  void initState() {
    super.initState();
    _controller = NotificationListController();
    _controller.loadNotifications(filter: _selectedFilter, reset: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      currentRoute: widget.currentRoute,
      onNavigate: widget.onNavigate,
      body: web_layout.WebTwoColumnLayout(
        leftColumnWidth: 280,
        leftColumn: _buildFiltersColumn(context),
        rightColumn: _buildNotificationsList(context),
        padding: const EdgeInsets.all(WebTheme.xl),
      ),
    );
  }
  Widget _buildFiltersColumn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Filtres',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: WebTheme.lg),
        ...NotificationFilter.values.map((filter) => Padding(
              padding: const EdgeInsets.only(bottom: WebTheme.sm),
              child: _buildFilterItem(context, filter),
            )),
        const SizedBox(height: WebTheme.lg),
        Divider(color: colorScheme.outline),
        const SizedBox(height: WebTheme.lg),
        TextButton.icon(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.check_circle),
          label: const Text('Tout marquer comme lu'),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: WebTheme.md,
              vertical: WebTheme.md,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildFilterItem(BuildContext context, NotificationFilter filter) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedFilter == filter;
    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
      child: InkWell(
        onTap: () => _changeFilter(filter),
        borderRadius: BorderRadius.circular(WebTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WebTheme.md,
            vertical: WebTheme.md,
          ),
          child: Row(
            children: [
              Icon(
                filter.icon,
                size: 20,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: WebTheme.md),
              Text(
                filter.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNotificationsList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => widget.onNavigate('/settings/notifications'),
              tooltip: 'Paramètres de notification',
            ),
          ],
        ),
        const SizedBox(height: WebTheme.xl),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.error && _controller.notifications.isEmpty) {
                return _buildErrorState();
              }
              if (_controller.notifications.isEmpty && !_controller.loading) {
                return NotificationEmptyState(filter: _selectedFilter);
              }
              final sections = _controller.groupByDate(_controller.notifications);
              return _buildNotificationsListContent(sections);
            },
          ),
        ),
      ],
    );
  }
  Widget _buildErrorState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: cs.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () =>
                _controller.loadNotifications(filter: _selectedFilter, reset: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationsListContent(List<NotificationSection> sections) {
    return ListView.builder(
      itemCount: sections.length + (_controller.loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sections.length) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final section = sections[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: WebTheme.md,
                top: WebTheme.lg,
                bottom: WebTheme.sm,
              ),
              child: Text(
                section.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...section.items.map((notification) => Padding(
                  padding: const EdgeInsets.only(bottom: WebTheme.sm),
                  child: NotificationCard(
                    key: ValueKey(notification.id),
                    notification: notification,
                    onTap: () => _handleNotificationTap(notification),
                    onDelete: () => _deleteNotification(notification),
                    onToggleRead: () => _controller.toggleRead(notification),
                    enableDismiss: false,
                  ),
                )),
          ],
        );
      },
    );
  }
  void _changeFilter(NotificationFilter filter) {
    setState(() => _selectedFilter = filter);
    _controller.loadNotifications(filter: filter, reset: true);
  }
  Future<void> _markAllAsRead() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout marquer comme lu'),
        content: const Text(
            'Voulez-vous marquer toutes les notifications comme lues ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _controller.markAllAsRead();
    }
  }
  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.read) {
      _controller.toggleRead(notification);
    }
    if (notification.type == 'new_follower') {
      widget.onNavigate('/user/${notification.sender.id}');
    } else if (notification.postId != null) {
      widget.onNavigate('/post/${notification.postId}');
    }
  }
  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _controller.deleteNotification(notification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
    }
  }
}