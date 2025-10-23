import 'package:flutter/material.dart';
import 'package:thot/core/constants/spacing_constants.dart';
import 'package:thot/features/admin/presentation/shared/utils/report_helpers.dart';
import 'package:thot/features/admin/presentation/shared/widgets/engagement_metrics.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/shared/utils/responsive_utils.dart';
class ReportTargetContent extends StatelessWidget {
  final String targetType;
  final Map<String, dynamic> targetDetails;
  final bool isCompact;
  const ReportTargetContent({
    super.key,
    required this.targetType,
    required this.targetDetails,
    this.isCompact = false,
  });
  @override
  Widget build(BuildContext context) {
    switch (targetType) {
      case 'post':
        return _buildPostContent(context);
      case 'comment':
        return _buildCommentContent(context);
      case 'user':
        return _buildUserContent(context);
      default:
        return Text('Type inconnu: $targetType');
    }
  }
  Widget _buildPostContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PostHelpers.getPostTypeIcon(targetDetails['type']),
              color: PostHelpers.getPostTypeColor(context, targetDetails['type']),
              size: ResponsiveUtils.getAdaptiveIconSize(context),
            ),
            SizedBox(width: SpacingConstants.space8),
            Expanded(
              child: Text(
                targetDetails['title'] ?? 'Sans titre',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (!isCompact) ...[
          SizedBox(height: SpacingConstants.space8),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: targetDetails['journalist']?['avatarUrl'] != null
                    ? NetworkImage(ImageUtils.getAvatarUrl(
                        targetDetails['journalist']['avatarUrl']))
                    : null,
                child: targetDetails['journalist']?['avatarUrl'] == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              SizedBox(width: SpacingConstants.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetDetails['journalist']?['name'] ??
                          targetDetails['journalist']?['username'] ??
                          'Inconnu',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Publié le ${DateHelpers.formatDate(targetDetails['createdAt'])}',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getAdaptiveFontSize(context, 12),
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SpacingConstants.space12),
          EngagementMetrics(
            views: targetDetails['views'] ?? 0,
            likes: targetDetails['likes']?.length ?? 0,
            comments: targetDetails['comments']?.length ?? 0,
          ),
        ],
      ],
    );
  }
  Widget _buildCommentContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          targetDetails['content'] ?? 'Commentaire supprimé',
          style: TextStyle(
            fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 14),
          ),
        ),
        SizedBox(height: SpacingConstants.space8),
        Row(
          children: [
            Icon(Icons.person_outline,
                size: 16, color: Theme.of(context).colorScheme.outline),
            SizedBox(width: SpacingConstants.space4),
            Text(
              targetDetails['author']?['name'] ?? 'Utilisateur',
              style: TextStyle(
                fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildUserContent(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: targetDetails['avatarUrl'] != null
              ? NetworkImage(ImageUtils.getAvatarUrl(targetDetails['avatarUrl']))
              : null,
          child: targetDetails['avatarUrl'] == null
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
        SizedBox(width: SpacingConstants.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                targetDetails['name'] ??
                    targetDetails['username'] ??
                    'Utilisateur',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                targetDetails['email'] ?? 'Email non disponible',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 12),
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}