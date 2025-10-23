import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/core/themes/app_colors.dart';
import 'package:thot/shared/widgets/common/app_avatar.dart';
class UserListTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsets? padding;
  final bool showJournalistBadge;
  final bool showVerifiedBadge;
  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
    this.padding,
    this.showJournalistBadge = true,
    this.showVerifiedBadge = true,
  });
  @override
  Widget build(BuildContext context) {
    final userId = user['_id'] ?? user['id'];
    final name = user['name'] ?? user['fullName'] ?? user['username'] ?? 'Unknown';
    final username = user['username'] ?? '';
    final avatarUrl = user['avatarUrl'] ?? user['profileImage'];
    final isJournalist = user['isJournalist'] == true || user['journalistRole'] != null || user['role'] == 'journalist';
    final isVerified = user['verified'] == true || user['isVerified'] == true;
    return InkWell(
      onTap: onTap ?? () => _navigateToProfile(context, userId),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(context, avatarUrl, isJournalist, isVerified),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUserInfo(context, name, username, isJournalist),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
  Widget _buildAvatar(BuildContext context, String? avatarUrl, bool isJournalist, bool isVerified) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: AppAvatar(
            avatarUrl: avatarUrl,
            radius: 24,
            isJournalist: isJournalist,
          ),
        ),
        if (showVerifiedBadge && isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildUserInfo(BuildContext context, String name, String username, bool isJournalist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showJournalistBadge && isJournalist) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.purple.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'Journaliste',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '@$username',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
  void _navigateToProfile(BuildContext context, String? userId) {
    if (userId == null || userId.isEmpty) return;
    HapticFeedback.lightImpact();
    SafeNavigation.pop(context);
    context.replaceNamed(
      RouteNames.profile,
      extra: {'userId': userId, 'forceReload': true},
    );
  }
}
class UserGroupSeparator extends StatelessWidget {
  final String label;
  const UserGroupSeparator({
    super.key,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
class UserListSeparator {
  final List<Map<String, dynamic>> users;
  UserListSeparator(this.users);
  int getSeparatorCount() {
    final journalistCount = _getJournalistCount();
    final userCount = users.length - journalistCount;
    return (journalistCount > 0 && userCount > 0) ? 1 : 0;
  }
  bool shouldShowSeparator(int index) {
    if (getSeparatorCount() == 0) return false;
    return index == _getJournalistCount();
  }
  int getUserIndex(int listIndex) {
    if (getSeparatorCount() == 0) return listIndex;
    final journalistCount = _getJournalistCount();
    if (listIndex <= journalistCount) return listIndex;
    return listIndex - 1;
  }
  int _getJournalistCount() {
    return users.where((u) =>
      u['isJournalist'] == true ||
      u['journalistRole'] != null ||
      u['role'] == 'journalist'
    ).length;
  }
}