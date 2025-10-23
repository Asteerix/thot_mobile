import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/media/utils/image_utils.dart';
import 'package:thot/core/utils/number_formatter.dart';
class ArticlePost extends StatelessWidget {
  final Post post;
  final VoidCallback onReadMore;
  const ArticlePost({
    super.key,
    required this.post,
    required this.onReadMore,
  });
  int _calculateReadingTime() {
    final wordCount = post.content.split(RegExp(r'\s+')).length;
    final readingTime = (wordCount / 200).ceil();
    return readingTime < 1 ? 1 : readingTime;
  }
  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  Widget _buildHeroImage(BuildContext context) {
    if (post.imageUrl == null || post.imageUrl!.isEmpty) {
      return Container(
        height: 240,
        width: double.infinity,
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Icon(
            Icons.article_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 56,
          ),
        ),
      );
    }
    final processedUrl = ImageUtils.processImageUrl(post.imageUrl!);
    return Container(
      height: 240,
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      child: CachedNetworkImage(
        imageUrl: processedUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white.withOpacity(0.3),
            size: 56,
          ),
        ),
      ),
    );
  }
  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
  Widget _buildContent(BuildContext context) {
    final paragraphs = post.content.split('\n\n');
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetadataChip(
                icon: Icons.schedule_outlined,
                label: '${_calculateReadingTime()} min',
              ),
              const SizedBox(width: 16),
              _buildMetadataChip(
                icon: Icons.visibility_outlined,
                label: NumberFormatter.format(post.stats.views),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...paragraphs.asMap().entries.map((entry) {
            final paragraph = entry.value.trim();
            if (paragraph.isEmpty) {
              return const SizedBox(height: 12);
            }
            if (paragraph.startsWith('>') || paragraph.startsWith('"')) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  paragraph.replaceFirst('>', '').replaceFirst('"', '').trim(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                paragraph,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onReadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
              child: const Text(
                'Lire l\'article complet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }
}