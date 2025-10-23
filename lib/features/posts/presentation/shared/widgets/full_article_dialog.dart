import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'post_actions.dart';
import 'package:thot/features/comments/presentation/shared/widgets/comment_sheet.dart';
import 'package:thot/core/utils/safe_navigation.dart';
class FullArticleDialog extends StatefulWidget {
  final Post post;
  const FullArticleDialog({
    super.key,
    required this.post,
  });
  @override
  State<FullArticleDialog> createState() => _FullArticleDialogState();
}
class _FullArticleDialogState extends State<FullArticleDialog> {
  final _postRepository = ServiceLocator.instance.postRepository;
  late Post _currentPost;
  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
  }
  Future<void> _handleLike() async {
    developer.log(
      'FullArticleDialog: Handling like for post ${_currentPost.id}',
      name: 'FullArticleDialog',
    );
    if (_currentPost.id.startsWith('invalid_post_id_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'interagir avec ce post'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await _postRepository.likePost(_currentPost.id);
      HapticFeedback.mediumImpact();
      final response = await _postRepository.getPost(_currentPost.id);
      final updatedPost = Post.fromJson(response);
      if (mounted) {
        setState(() {
          _currentPost = updatedPost;
        });
      }
    } catch (e) {
      developer.log(
        'Error liking post in FullArticleDialog',
        name: 'FullArticleDialog',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  Future<void> _handleSave() async {
    developer.log(
      'FullArticleDialog: Handling save for post ${_currentPost.id}',
      name: 'FullArticleDialog',
    );
    if (_currentPost.id.startsWith('invalid_post_id_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de sauvegarder ce post'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      if (_currentPost.isSaved) {
        await _postRepository.unsavePost(_currentPost.id);
      } else {
        await _postRepository.savePost(_currentPost.id);
      }
      HapticFeedback.lightImpact();
      final response = await _postRepository.getPost(_currentPost.id);
      final updatedPost = Post.fromJson(response);
      if (mounted) {
        setState(() {
          _currentPost = updatedPost;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentPost.isSaved
                ? 'Retiré des favoris'
                : 'Ajouté aux favoris'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log(
        'Error saving post in FullArticleDialog',
        name: 'FullArticleDialog',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  void _showCommentsSheet() {
    if (_currentPost.id.startsWith('invalid_post_id_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'afficher les commentaires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    SafeNavigation.showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => CommentsBottomSheet(postId: _currentPost.id),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.3,
                    pinned: true,
                    backgroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
                      onPressed: () => SafeNavigation.pop(context),
                    ),
                    stretch: true,
                    stretchTriggerOffset: 100,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_currentPost.imageUrl != null)
                            Image.network(
                              _currentPost.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  (isDark ? Colors.black : Colors.white).withOpacity(0.9),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPost.content,
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.85),
                              fontSize: 17,
                              height: 1.6,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (_currentPost.sources.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Text(
                              'Sources',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._currentPost.sources.map((source) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '• $source',
                                    style: TextStyle(
                                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                )),
                          ],
                          if (_currentPost.tags.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _currentPost.tags
                                  .map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: TextStyle(
                                            color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: PostActions(
                post: _currentPost,
                onLike: _handleLike,
                onComment: _showCommentsSheet,
                onSave: _handleSave,
                onPostUpdated: (updatedPost) {
                  setState(() {
                    _currentPost = updatedPost;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}