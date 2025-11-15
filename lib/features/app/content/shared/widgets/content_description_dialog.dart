import 'package:flutter/material.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/core/presentation/theme/app_colors.dart';

class ContentDescriptionDialog extends StatelessWidget {
  final Post post;
  final Widget? mediaWidget;

  const ContentDescriptionDialog({
    super.key,
    required this.post,
    this.mediaWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isArticle = post.type == PostType.article;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentPadding = screenWidth > 600 ? 56.0 : 32.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFB),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.imageUrl != null || post.thumbnailUrl != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                post.thumbnailUrl ?? post.imageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: contentPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                color: Color(0xFF0A0A0A),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 32),
                            post.content.isNotEmpty
                                ? Text(
                                    post.content,
                                    style: const TextStyle(
                                      color: Color(0xFF1F1F1F),
                                      fontSize: 19,
                                      height: 1.8,
                                      letterSpacing: 0.1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: isArticle ? TextAlign.justify : TextAlign.start,
                                  )
                                : Text(
                                    'Aucune description disponible',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 17,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
