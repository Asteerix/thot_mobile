import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/core/monitoring/logger_service.dart';
import 'package:thot/features/admin/presentation/shared/utils/admin_dialog_utils.dart';
import 'package:thot/features/admin/presentation/shared/utils/admin_snackbar_utils.dart';
class AdminModerationActions extends StatelessWidget {
  final String userId;
  final String? postId;
  final String? commentId;
  final String? shortId;
  final VoidCallback? onDeleted;
  final VoidCallback? onBanned;
  const AdminModerationActions({
    super.key,
    required this.userId,
    this.postId,
    this.commentId,
    this.shortId,
    this.onDeleted,
    this.onBanned,
  });
  Future<void> _banUser(BuildContext context) async {
    final reason = await AdminDialogUtils.showInputDialog(
      context: context,
      title: 'Bannir cet utilisateur?',
      message: 'Cette action est permanente. L\'utilisateur ne pourra plus accéder à son compte.',
      hint: 'Raison du bannissement (obligatoire)',
      confirmText: 'Bannir',
      confirmColor: AppColors.red,
      icon: Icons.block,
      required: true,
    );
    if (reason != null && reason.isNotEmpty) {
      try {
        final apiService = ServiceLocator.instance.apiService;
        await apiService.put('/api/admin/users/$userId/ban', data: {
          'reason': reason,
        });
        if (context.mounted) {
          AdminSnackbarUtils.showSuccess(context, 'Utilisateur banni avec succès');
        }
        onBanned?.call();
      } catch (e) {
        LoggerService.instance.error('Failed to ban user', e);
        if (context.mounted) {
          AdminSnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
        }
      }
    }
  }
  Future<void> _deleteContent(
      BuildContext context, String type, String id) async {
    final itemTypeName = _getContentTypeName(type);
    final confirmed = await AdminDialogUtils.showDeleteConfirmation(
      context: context,
      itemType: itemTypeName,
    );
    if (confirmed) {
      try {
        final apiService = ServiceLocator.instance.apiService;
        final endpoint = _getContentEndpoint(type, id);
        await apiService.delete(endpoint, data: {
          'reason': 'Contenu inapproprié',
        });
        if (context.mounted) {
          AdminSnackbarUtils.showSuccess(context, 'Contenu supprimé avec succès');
        }
        onDeleted?.call();
      } catch (e) {
        LoggerService.instance.error('Failed to delete content', e);
        if (context.mounted) {
          AdminSnackbarUtils.showError(context, 'Erreur: ${e.toString()}');
        }
      }
    }
  }
  String _getContentTypeName(String type) {
    switch (type) {
      case 'post':
        return 'post';
      case 'comment':
        return 'commentaire';
      case 'short':
        return 'short';
      default:
        return 'contenu';
    }
  }
  String _getContentEndpoint(String type, String id) {
    switch (type) {
      case 'post':
        return '/api/admin/posts/$id';
      case 'comment':
        return '/api/admin/comments/$id';
      case 'short':
        return '/api/admin/shorts/$id';
      default:
        throw ArgumentError('Type de contenu non supporté: $type');
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAdmin) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.1),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions Admin',
            style: TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.block,
                label: 'Bannir',
                onPressed: () => _banUser(context),
                color: AppColors.red
              ),
              if (postId != null)
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer post',
                  onPressed: () => _deleteContent(context, 'post', postId!),
                  color: AppColors.warning,
                ),
              if (commentId != null)
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer commentaire',
                  onPressed: () => _deleteContent(context, 'comment', commentId!),
                  color: AppColors.warning,
                ),
              if (shortId != null)
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer short',
                  onPressed: () => _deleteContent(context, 'short', shortId!),
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
    );
  }
}