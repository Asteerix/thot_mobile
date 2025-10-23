import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:thot/core/extensions/context_extensions.dart';
import 'package:thot/features/posts/data/repositories/post_repository_impl.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/media/utils/image_utils.dart';
class PollDetailScreen extends StatefulWidget {
  final String postId;
  const PollDetailScreen({super.key, required this.postId});
  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}
class _PollDetailScreenState extends State<PollDetailScreen> {
  late final PostRepositoryImpl _postRepository;
  bool _isLoading = true;
  Post? _post;
  String? _error;
  @override
  void initState() {
    super.initState();
    _postRepository = ServiceLocator.instance.postRepository;
    _loadPost();
  }
  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await _postRepository.getPost(widget.postId);
      final post = Post.fromJson(response);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: const TextStyle(color: AppColors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPost,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_post == null) {
      return const Scaffold(
        body: Center(
          child: Text('Post not found'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _post?.title ?? 'Poll Details',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Tailwind',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: _post?.journalist?.avatarUrl != null &&
                                _post!.journalist!.avatarUrl!.isNotEmpty
                            ? NetworkImage(ImageUtils.getAvatarUrl(
                                _post!.journalist!.avatarUrl!))
                            : const AssetImage(
                                    'assets/images/defaults/default_journalist_avatar.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post!.journalist?.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          if (_post!.journalist?.isVerified ?? false)
                            Text(
                              'Verified Journalist',
                              style: TextStyle(
                                color: AppColors.info,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _post?.content ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Poll results will be displayed here'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}