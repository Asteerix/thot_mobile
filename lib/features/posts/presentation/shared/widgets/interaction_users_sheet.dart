import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/presentation/shared/widgets/users/user_list_tile.dart';
class InteractionUsersSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> users;
  const InteractionUsersSheet({
    super.key,
    required this.title,
    required this.users,
  });
  static void show(
      BuildContext context, String title, List<Map<String, dynamic>> users) {
    SafeNavigation.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InteractionUsersSheet(
        title: title,
        users: users,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${users.length}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun utilisateur',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildUserList(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildUserList(ScrollController scrollController) {
    final separator = UserListSeparator(users);
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length + separator.getSeparatorCount(),
      itemBuilder: (context, index) {
        if (separator.shouldShowSeparator(index)) {
          return const UserGroupSeparator(label: 'UTILISATEURS');
        }
        final userIndex = separator.getUserIndex(index);
        final user = users[userIndex];
        return UserListTile(
          user: user,
          trailing: user['isCurrentUser'] != true
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: user['isFollowing'] == true
                        ? Colors.transparent
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user['isFollowing'] == true
                          ? AppColors.textSecondary
                          : Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user['isFollowing'] == true ? 'Abonné' : 'Suivre',
                    style: TextStyle(
                      color: user['isFollowing'] == true
                          ? AppColors.textSecondary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}