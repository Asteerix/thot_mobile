import 'package:flutter/material.dart';
import 'package:thot/features/posts/domain/entities/post.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/posts/application/providers/posts_state_provider.dart';
class OptimizedSaveButton extends StatefulWidget {
  final Post post;
  final Color? color;
  final double? size;
  const OptimizedSaveButton({
    super.key,
    required this.post,
    this.color,
    this.size,
  });
  @override
  State<OptimizedSaveButton> createState() => _OptimizedSaveButtonState();
}
class _OptimizedSaveButtonState extends State<OptimizedSaveButton> {
  late bool _isSaved;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _isSaved = widget.post.interactions.isSaved;
  }
  @override
  void didUpdateWidget(OptimizedSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.interactions.isSaved !=
            widget.post.interactions.isSaved) {
      _isSaved = widget.post.interactions.isSaved;
    }
  }
  Future<void> _handleSaveToggle() async {
    if (_isLoading) return;
    setState(() {
      _isSaved = !_isSaved;
      _isLoading = true;
    });
    try {
      final postsStateProvider = context.read<PostsStateProvider>();
      await postsStateProvider.toggleBookmark(widget.post.id);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _isSaved ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(_isSaved),
          color: widget.color ?? Colors.white,
          size: widget.size,
        ),
      ),
      onPressed: _isLoading ? null : _handleSaveToggle,
    );
  }
}