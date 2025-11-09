import 'package:thot/core/themes/app_colors.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/core/navigation/route_names.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
class OppositionDialog extends StatelessWidget {
  final Post post;
  const OppositionDialog({
    super.key,
    required this.post,
  });
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Publications en opposition',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cette publication s\'oppose à :',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildOppositionsList(post.opposingPosts),
            const SizedBox(height: 16),
            Text(
              'Publications qui s\'opposent à celle-ci :',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildOppositionsList(post.opposedByPosts),
          ],
        ),
      ),
    );
  }
  Widget _buildOppositionsList(List<OppositionPost>? oppositions) {
    if (oppositions == null || oppositions.isEmpty) {
      return Text(
        'Aucune publication en opposition',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: oppositions
          .map((opposition) => _OppositionItem(opposition: opposition))
          .toList(),
    );
  }
}
class _OppositionItem extends StatelessWidget {
  final OppositionPost opposition;
  const _OppositionItem({
    required this.opposition,
  });
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        developer.log(
          'Fetching opposition post',
          name: 'OppositionDialog',
          error: {
            'postId': opposition.postId,
          },
        );
        try {
          final postRepository = ServiceLocator.instance.postRepository;
          final id = opposition.postId.split('/').last;
          final data = await postRepository.getPost(id);
          return data;
        } catch (e, stackTrace) {
          developer.log(
            'Error fetching opposition post',
            name: 'OppositionDialog',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      }(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.error_outline, color: AppColors.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors du chargement de la publication',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        }
        Widget imageWidget;
        String title = 'Chargement...';
        String? description = opposition.description;
        String journalistInfo = '';
        if (snapshot.connectionState == ConnectionState.waiting) {
          imageWidget = Container(
            width: 60,
            height: 60,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final postData = snapshot.data;
          title = postData?['title'] ?? 'Sans titre';
          journalistInfo = postData?['journalist'] != null
              ? '@${postData?['journalist']['username'] ?? ''}'
              : '';
          final processedUrl =
              ImageUtils.processImageUrl(postData?['imageUrl']);
          if (ImageUtils.isValidNetworkUrl(processedUrl)) {
            imageWidget = ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                processedUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.error_outline, color: AppColors.textSecondary),
                ),
              ),
            );
          } else {
            imageWidget = Container(
              width: 60,
              height: 60,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.article, color: AppColors.textSecondary),
            );
          }
        } else {
          imageWidget = Container(
            width: 60,
            height: 60,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              final id = opposition.postId.split('/').last;
              SafeNavigation.pop(context);
              context.pushReplacement(
                '/post/$id',
                extra: {
                  'postId': id,
                  'isFromProfile': false,
                  'isFromFeed': true,
                },
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (journalistInfo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            journalistInfo,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}