import 'package:thot/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/features/app/content/shared/comments/comment.dart';
import 'package:thot/features/app/content/shared/comments/comment_repository_impl.dart';
import 'comment_list_item.dart';
import 'package:thot/features/admin/widgets/report_dialog.dart';

class CommentList extends StatefulWidget {
  final String postId;
  final ScrollController? scrollController;
  const CommentList({
    super.key,
    required this.postId,
    this.scrollController,
  });
  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  late final CommentRepositoryImpl _commentRepository;
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  @override
  void initState() {
    super.initState();
    _commentRepository = ServiceLocator.instance.commentRepository;
    _loadComments();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        _comments = [];
        _currentPage = 1;
        _hasMore = true;
      }
    });
    try {
      final result = await _commentRepository.getComments(
        widget.postId,
        page: _currentPage,
      );
      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasMore = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          }
        },
        (newComments) {
          if (mounted) {
            setState(() {
              if (refresh) {
                _comments = newComments;
              } else {
                _comments.addAll(newComments);
              }
              _hasMore = newComments.isNotEmpty;
              if (_hasMore) _currentPage++;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      final result = await _commentRepository.addComment(widget.postId, text);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          }
        },
        (newComment) {
          if (mounted) {
            setState(() {
              _comments.insert(0, newComment);
            });
            _commentController.clear();
            HapticFeedback.mediumImpact();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _handleLike(Comment comment, bool like) async {
    try {
      final result = like
          ? await _commentRepository.likeComment(comment.id)
          : await _commentRepository.unlikeComment(comment.id);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${failure.message}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            setState(() {
              final index = _comments.indexWhere((c) => c.id == comment.id);
              if (index != -1) {
                _comments[index] = comment.copyWith(
                  likes: comment.likes + (like ? 1 : -1),
                  isLiked: like,
                );
              }
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ${like ? 'liking' : 'unliking'} comment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleEdit(Comment comment, String newContent) async {
    try {
      final result =
          await _commentRepository.updateComment(comment.id, newContent);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${failure.message}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        (updatedComment) {
          if (mounted) {
            setState(() {
              final index = _comments.indexWhere((c) => c.id == comment.id);
              if (index != -1) {
                _comments[index] = updatedComment;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating comment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(Comment comment) async {
    try {
      final result = await _commentRepository.deleteComment(comment.id);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${failure.message}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            setState(() {
              _comments = _comments.where((c) => c.id != comment.id).toList();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReport(Comment comment) async {
    SafeNavigation.showDialog(
      context: context,
      builder: (context) => ReportDialog(
        targetType: 'comment',
        targetId: comment.id,
        targetTitle: comment.content,
      ),
    );
  }

  void _showEditDialog(Comment comment) {
    final editController = TextEditingController(text: comment.content);
    SafeNavigation.showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          maxLength: 500,
          buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) {
            return Text(
              '$currentLength/$maxLength',
              style: TextStyle(
                color:
                    currentLength >= maxLength! ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            );
          },
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => SafeNavigation.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty && newContent != comment.content) {
                SafeNavigation.pop(context);
                _handleEdit(comment, newContent);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadComments(refresh: true),
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _comments.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  if (_isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final comment = _comments[index];
                return CommentListItem(
                  comment: comment,
                  onLike: (like) => _handleLike(comment, like),
                  onEdit: () => _showEditDialog(comment),
                  onDelete: () => _handleDelete(comment),
                  onReport: () => _handleReport(comment),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(
              top: BorderSide(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 500,
                  buildCounter: (context,
                      {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      '$currentLength/$maxLength',
                      style: TextStyle(
                        color: currentLength >= maxLength!
                            ? Colors.red
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onFieldSubmitted: (_) => _addComment(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: _addComment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
