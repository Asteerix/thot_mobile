import 'package:flutter/material.dart';
import 'package:thot/shared/widgets/common/cached_network_image_widget.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/features/notifications/domain/entities/notification.dart';
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleRead;
  final bool enableDismiss;
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.onToggleRead,
    this.enableDismiss = true,
  });
  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!enableDismiss) {
      return content;
    }
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(
          notification.read
              ? Icons.mail
              : Icons.mail,
          color: cs.onPrimary,
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: cs.onError),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggleRead();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: content,
    );
  }
  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.read
            ? (isDark ? cs.surfaceContainer : Colors.white)
            : (isDark
                ? cs.primaryContainer.withOpacity(0.15)
                : cs.primaryContainer.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: !notification.read
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessage(context),
                      if (notification.post?.title != null) ...[
                        const SizedBox(height: 8),
                        _buildPostPreview(context),
                      ],
                      const SizedBox(height: 8),
                      _buildFooter(context),
                    ],
                  ),
                ),
                if (notification.post?.thumbnailUrl != null)
                  _buildThumbnail(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer,
                cs.secondaryContainer,
              ],
            ),
          ),
          child: ClipOval(
            child: notification.sender.profileImage != null
                ? CachedNetworkImageWidget(
                    imageUrl: ImageUtils.constructFullUrl(
                        notification.sender.profileImage!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      notification.sender.username.isNotEmpty
                          ? notification.sender.username[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: notification.iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                size: 14,
                color: notification.iconColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildMessage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(
          height: 1.4,
          color: cs.onSurface,
        ),
        children: [
          TextSpan(
            text: notification.sender.username,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: notification.message,
            style: TextStyle(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPostPreview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.article,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notification.post!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFooter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: cs.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          notification.getTimeAgo(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
        ),
        const Spacer(),
        if (notification.type == 'new_follower')
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: cs.primaryContainer,
            ),
            child: Text(
              'Suivre',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        if (!notification.read)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
      ],
    );
  }
  Widget _buildThumbnail(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImageWidget(
          imageUrl:
              ImageUtils.constructFullUrl(notification.post!.thumbnailUrl!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}