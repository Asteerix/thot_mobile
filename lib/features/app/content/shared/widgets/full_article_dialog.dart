import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/core/utils/safe_navigation.dart';

class FullArticleDialog extends StatelessWidget {
  final Post post;
  const FullArticleDialog({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            children: [
              Column(
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
                                Text(
                                  post.content,
                                  style: const TextStyle(
                                    color: Color(0xFF1F1F1F),
                                    fontSize: 19,
                                    height: 1.8,
                                    letterSpacing: 0.1,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                                if (post.sources.isNotEmpty) ...[
                                  const SizedBox(height: 48),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F7FF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFD1E7FF),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[600],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.source,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Sources',
                                              style: TextStyle(
                                                color: Color(0xFF0A0A0A),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        ...post.sources.map((source) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    margin: const EdgeInsets.only(top: 9),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[700],
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Text(
                                                      source,
                                                      style: TextStyle(
                                                        color: Colors.blue[900],
                                                        fontSize: 16,
                                                        height: 1.6,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                                if (post.tags.isNotEmpty) ...[
                                  const SizedBox(height: 36),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: post.tags
                                        .map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 9,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                '#$tag',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
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
            ],
          ),
        );
      },
    );
  }
}
