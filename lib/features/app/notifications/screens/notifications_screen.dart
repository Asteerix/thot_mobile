import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/routing/route_names.dart';
import 'package:thot/features/app/notifications/models/notification.dart';
import 'package:thot/features/app/content/shared/widgets/post_detail_screen.dart';
import 'package:thot/features/app/content/shared/comments/comment_sheet.dart';
import '../widgets/notification_filter.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_list_controller.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}
class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _filters = NotificationFilter.values;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                HapticFeedback.selectionClick();
                if (Navigator.canPop(context)) {
                  SafeNavigation.pop(context);
                } else {
                  SafeNavigation.navigateTo(context, '/feed');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.white),
                onPressed: _markAllAsRead,
                tooltip: 'Tout marquer comme lu',
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.5),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: _filters
                      .map((f) => Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(f.icon, size: 18),
                                  const SizedBox(width: 8),
                                  Text(f.label),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _filters
              .map((f) => NotificationList(key: PageStorageKey(f), filter: f))
              .toList(),
        ),
      ),
    );
  }
  Future<void> _markAllAsRead() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tout marquer comme lu',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous marquer toutes les notifications comme lues ?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      if (mounted) setState(() {});
    }
  }
}
class NotificationList extends StatefulWidget {
  final NotificationFilter filter;
  const NotificationList({super.key, required this.filter});
  @override
  State<NotificationList> createState() => _NotificationListState();
}
class _NotificationListState extends State<NotificationList>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  late final NotificationListController _controller;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _controller = NotificationListController();
    _controller.loadNotifications(filter: widget.filter, reset: true);
    _scrollController.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_controller.loading &&
        _controller.hasMore) {
      _controller.loadNotifications(filter: widget.filter);
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.error && _controller.notifications.isEmpty) {
          return _buildErrorState();
        }
        if (_controller.notifications.isEmpty && !_controller.loading) {
          return NotificationEmptyState(filter: widget.filter);
        }
        final sections = _controller.groupByDate(_controller.notifications);
        return _buildNotificationsList(sections);
      },
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _controller.errorMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                _controller.loadNotifications(filter: widget.filter, reset: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationsList(List<NotificationSection> sections) {
    return RefreshIndicator(
      onRefresh: () =>
          _controller.loadNotifications(filter: widget.filter, reset: true),
      color: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.1),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          for (final section in sections) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  section.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notification = section.items[index];
                    return NotificationCard(
                      key: ValueKey(notification.id),
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                      onDelete: () => _deleteNotification(notification),
                      onToggleRead: () => _controller.toggleRead(notification),
                      enableDismiss: true,
                    );
                  },
                  childCount: section.items.length,
                ),
              ),
            ),
          ],
          if (_controller.loading)
            const SliverPadding(
              padding: EdgeInsets.all(32),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 32),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
  void _handleNotificationTap(NotificationModel notification) {
    HapticFeedback.lightImpact();
    if (!notification.read) {
      _controller.toggleRead(notification);
    }

    switch (notification.type) {
      case 'new_follower':
        context.push('/profile', extra: {
          'userId': notification.sender.id,
          'forceReload': true,
        });
        break;

      case 'post_like':
      case 'new_post_from_followed':
      case 'article_published':
        if (notification.postId != null) {
          SafeNavigation.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                initialPostId: notification.postId!,
                isFromFeed: true,
              ),
            ),
          );
        }
        break;

      case 'comment_reply':
      case 'comment_like':
        if (notification.postId != null) {
          SafeNavigation.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                initialPostId: notification.postId!,
                isFromFeed: true,
              ),
            ),
          ).then((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CommentsBottomSheet(
                    postId: notification.postId!,
                  ),
                );
              }
            });
          });
        }
        break;

      case 'mention':
        if (notification.postId != null) {
          SafeNavigation.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                initialPostId: notification.postId!,
                isFromFeed: true,
              ),
            ),
          );
        }
        break;

      case 'post_removed':
        break;

      default:
        if (notification.postId != null) {
          SafeNavigation.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                initialPostId: notification.postId!,
                isFromFeed: true,
              ),
            ),
          );
        }
    }
  }
  Future<void> _deleteNotification(NotificationModel notification) async {
    HapticFeedback.mediumImpact();
    try {
      await _controller.deleteNotification(notification);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Notification supprimée'),
            backgroundColor: Colors.white.withOpacity(0.1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
    }
  }
}