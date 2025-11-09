import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thot/features/comments/domain/entities/comment.dart';
import 'package:thot/core/utils/safe_navigation.dart';
import 'package:thot/core/utils/time_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/comments/data/repositories/comment_repository_impl.dart';
import 'package:thot/features/authentication/application/providers/auth_provider.dart';
class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  const CommentsBottomSheet({
    super.key,
    required this.postId,
  });
  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}
class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late final CommentRepositoryImpl _commentRepository;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _replyingToId;
  String? _replyingToUsername;
  final Map<String, List<Comment>> _repliesMap = {};
  final Map<String, bool> _loadingReplies = {};
  final Set<String> _expandedComments = {};
  @override
  void initState() {
    super.initState();
    debugPrint(
        '🎬 [COMMENT_SHEET] Widget initialized | postId: ${widget.postId}');
    _commentRepository = ServiceLocator.instance.commentRepository;
    debugPrint(
        '📦 [COMMENT_SHEET] Repository initialized | postId: ${widget.postId}');
    _loadComments();
  }
  @override
  void dispose() {
    debugPrint(
        '🗑️ [COMMENT_SHEET] Widget disposing | postId: ${widget.postId}, commentsCount: ${_comments.length}');
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  Future<void> _loadComments() async {
    debugPrint(
        '🔄 [COMMENT_SHEET] Loading comments | postId: ${widget.postId}');
    setState(() => _isLoading = true);
    try {
      final result = await _commentRepository.getComments(widget.postId);
      result.fold(
        (failure) {
          debugPrint(
              '❌ [COMMENT_SHEET] Load comments failed | postId: ${widget.postId}, failureMessage: ${failure.message}');
          if (mounted) {
            setState(() => _isLoading = false);
            SafeNavigation.showSnackBar(
              context,
              SnackBar(
                content: Text('Erreur: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (comments) async {
          debugPrint(
              '✅ [COMMENT_SHEET] Comments loaded successfully | postId: ${widget.postId}, count: ${comments.length}, firstComment: ${comments.isNotEmpty ? comments[0].author.name : 'none'}');
          if (!mounted) return;
          setState(() {
            _comments = List<Comment>.from(comments);
            _isLoading = false;
          });
          for (final comment in _comments) {
            if (comment.replyCount > 0) {
              debugPrint(
                  '🔄 [COMMENT_SHEET] Auto-loading replies | commentId: ${comment.id}, replyCount: ${comment.replyCount}');
              await _loadRepliesForComment(comment.id);
            }
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
          '❌ [COMMENT_SHEET] Exception loading comments | postId: ${widget.postId}, error: ${e.toString()}, stackTrace: ${stackTrace.toString()}');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _loadRepliesForComment(String commentId) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔄 [COMMENT_SHEET] AUTO-LOADING REPLIES');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔄 [COMMENT_SHEET] Comment ID: $commentId');
    try {
      debugPrint('🔄 [COMMENT_SHEET] Calling repository.getReplies...');
      final result = await _commentRepository.getReplies(commentId);
      debugPrint('🔄 [COMMENT_SHEET] Repository response received');
      result.fold(
        (failure) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('❌ [COMMENT_SHEET] AUTO-LOAD REPLIES FAILED');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('❌ [COMMENT_SHEET] Comment ID: $commentId');
          debugPrint('❌ [COMMENT_SHEET] Failure message: ${failure.message}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        },
        (replies) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ [COMMENT_SHEET] REPLIES AUTO-LOADED SUCCESSFULLY');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ [COMMENT_SHEET] Comment ID: $commentId');
          debugPrint('✅ [COMMENT_SHEET] Replies count: ${replies.length}');
          if (replies.isNotEmpty) {
            debugPrint('✅ [COMMENT_SHEET] First reply:');
            debugPrint('   - ID: ${replies[0].id}');
            debugPrint('   - Author: ${replies[0].author.name}');
            debugPrint('   - Content: ${replies[0].content.substring(0, replies[0].content.length > 50 ? 50 : replies[0].content.length)}...');
            debugPrint('   - Parent: ${replies[0].parentComment}');
          }
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          if (mounted) {
            setState(() {
              _repliesMap[commentId] = replies;
              _expandedComments.add(commentId);
              debugPrint('✅ [COMMENT_SHEET] State updated | repliesMap size: ${_repliesMap.length}, expandedComments size: ${_expandedComments.length}');
            });
          } else {
            debugPrint('⚠️ [COMMENT_SHEET] Widget not mounted, skipping state update');
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_SHEET] EXCEPTION AUTO-LOADING REPLIES');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_SHEET] Comment ID: $commentId');
      debugPrint('❌ [COMMENT_SHEET] Error: ${e.toString()}');
      debugPrint('❌ [COMMENT_SHEET] Stack trace: ${stackTrace.toString()}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;
    final isReply = _replyingToId != null;
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✍️ [COMMENT_SHEET] 📝 SENDING COMMENT');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✍️ [COMMENT_SHEET] Post ID: ${widget.postId}');
    debugPrint('✍️ [COMMENT_SHEET] Content: "${text.substring(0, text.length > 50 ? 50 : text.length)}${text.length > 50 ? "..." : ""}"');
    debugPrint('✍️ [COMMENT_SHEET] Content Length: ${text.length}');
    debugPrint('✍️ [COMMENT_SHEET] IS REPLY: ${isReply ? "✅ YES" : "❌ NO"}');
    debugPrint('✍️ [COMMENT_SHEET] Replying To ID: ${_replyingToId ?? "null"}');
    debugPrint('✍️ [COMMENT_SHEET] Replying To Username: ${_replyingToUsername ?? "null"}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    setState(() => _isSending = true);
    try {
      debugPrint('✍️ [COMMENT_SHEET] 📡 Calling repository addComment...');
      final result = await _commentRepository.addComment(
        widget.postId,
        text,
        parentCommentId: _replyingToId,
      );
      debugPrint('✍️ [COMMENT_SHEET] 📥 Repository response received');
      result.fold(
        (failure) {
          debugPrint(
              '❌ [COMMENT_SHEET] Send comment failed | postId: ${widget.postId}, failureMessage: ${failure.message}');
          if (!mounted) return;
          setState(() => _isSending = false);
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (newComment) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ [COMMENT_SHEET] COMMENT SENT SUCCESSFULLY');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ [COMMENT_SHEET] Post ID: ${widget.postId}');
          debugPrint('✅ [COMMENT_SHEET] Comment ID: ${newComment.id}');
          debugPrint('✅ [COMMENT_SHEET] Author: ${newComment.author.name}');
          debugPrint('✅ [COMMENT_SHEET] Parent Comment: ${newComment.parentComment ?? "null"}');
          debugPrint('✅ [COMMENT_SHEET] IS REPLY: ${newComment.parentComment != null ? "✅ YES" : "❌ NO"}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          if (!mounted) return;
          setState(() {
            if (newComment.parentComment != null) {
              debugPrint('✍️ [COMMENT_SHEET] 💬 Processing as REPLY...');
              debugPrint('✍️ [COMMENT_SHEET] Looking for parent comment: ${newComment.parentComment}');
              final parentIndex = _comments
                  .indexWhere((c) => c.id == newComment.parentComment);
              debugPrint('✍️ [COMMENT_SHEET] Parent comment index: $parentIndex');
              if (parentIndex != -1) {
                final parentComment = _comments[parentIndex];
                debugPrint('✍️ [COMMENT_SHEET] ✅ Parent comment found');
                debugPrint('✍️ [COMMENT_SHEET] Parent current reply count: ${parentComment.replyCount}');
                _comments[parentIndex] = parentComment.copyWith(
                  replyCount: parentComment.replyCount + 1,
                );
                debugPrint('✍️ [COMMENT_SHEET] Parent new reply count: ${_comments[parentIndex].replyCount}');
                if (_expandedComments.contains(newComment.parentComment)) {
                  debugPrint('✍️ [COMMENT_SHEET] ✅ Parent is expanded, adding reply to visible list');
                  if (_repliesMap[newComment.parentComment] != null) {
                    debugPrint('✍️ [COMMENT_SHEET] Adding to existing replies list (count: ${_repliesMap[newComment.parentComment]!.length})');
                    _repliesMap[newComment.parentComment]!.insert(
                      0,
                      newComment,
                    );
                  } else {
                    debugPrint('✍️ [COMMENT_SHEET] Creating new replies list');
                    _repliesMap[newComment.parentComment!] = [newComment];
                  }
                  debugPrint('✍️ [COMMENT_SHEET] New replies count: ${_repliesMap[newComment.parentComment]!.length}');
                } else {
                  debugPrint('✍️ [COMMENT_SHEET] ℹ️ Parent is collapsed, not showing reply in list');
                }
              } else {
                debugPrint('✍️ [COMMENT_SHEET] ⚠️ Parent comment not found in list!');
              }
            } else {
              debugPrint('✍️ [COMMENT_SHEET] 📝 Processing as TOP-LEVEL comment');
              _comments.insert(0, newComment);
              debugPrint('✍️ [COMMENT_SHEET] Added to top of comments list');
              debugPrint('✍️ [COMMENT_SHEET] Total comments: ${_comments.length}');
            }
            _commentController.clear();
            _isSending = false;
            _replyingToId = null;
            _replyingToUsername = null;
            debugPrint('✍️ [COMMENT_SHEET] ✅ State updated, reply context cleared');
          });
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text(newComment.parentComment != null
                  ? 'Réponse publiée'
                  : 'Commentaire publié'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          debugPrint('✍️ [COMMENT_SHEET] 🎉 Success notification shown');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
          '❌ [COMMENT_SHEET] Exception sending comment | postId: ${widget.postId}, error: ${e.toString()}, stackTrace: ${stackTrace.toString()}');
      if (!mounted) return;
      setState(() => _isSending = false);
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _replyToComment(Comment comment) {
    debugPrint(
        '💬 [COMMENT_SHEET] Reply to comment | commentId: ${comment.id}, authorName: ${comment.author.name}');
    setState(() {
      _replyingToId = comment.id;
      _replyingToUsername = comment.author.name;
    });
    _focusNode.requestFocus();
  }
  void _cancelReply() {
    debugPrint('❌ [COMMENT_SHEET] Cancel reply');
    setState(() {
      _replyingToId = null;
      _replyingToUsername = null;
    });
  }
  Future<void> _toggleReplies(Comment comment) async {
    final commentId = comment.id;
    if (_expandedComments.contains(commentId)) {
      setState(() {
        _expandedComments.remove(commentId);
      });
      debugPrint(
          '🔼 [COMMENT_SHEET] Collapsed replies | commentId: $commentId');
      return;
    }
    if (!_repliesMap.containsKey(commentId)) {
      setState(() {
        _loadingReplies[commentId] = true;
      });
      debugPrint(
          '🔽 [COMMENT_SHEET] Fetching replies | commentId: $commentId, replyCount: ${comment.replyCount}');
      try {
        final result = await _commentRepository.getReplies(commentId);
        result.fold(
          (failure) {
            debugPrint(
                '❌ [COMMENT_SHEET] Fetch replies failed | commentId: $commentId, failureMessage: ${failure.message}');
            if (mounted) {
              setState(() {
                _loadingReplies[commentId] = false;
              });
              SafeNavigation.showSnackBar(
                context,
                SnackBar(
                  content: Text('Erreur: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          (replies) {
            debugPrint(
                '✅ [COMMENT_SHEET] Replies loaded successfully | commentId: $commentId, count: ${replies.length}');
            if (mounted) {
              setState(() {
                _repliesMap[commentId] = replies;
                _loadingReplies[commentId] = false;
                _expandedComments.add(commentId);
              });
            }
          },
        );
      } catch (e, stackTrace) {
        debugPrint(
            '❌ [COMMENT_SHEET] Exception fetching replies | commentId: $commentId, error: ${e.toString()}, stackTrace: ${stackTrace.toString()}');
        if (mounted) {
          setState(() {
            _loadingReplies[commentId] = false;
          });
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _expandedComments.add(commentId);
      });
      debugPrint(
          '🔽 [COMMENT_SHEET] Expanded loaded replies | commentId: $commentId, replyCount: ${_repliesMap[commentId]?.length}');
    }
  }
  Future<void> _toggleLike(Comment comment) async {
    final shouldLike = !comment.isLiked;
    debugPrint(
        '❤️ [COMMENT_SHEET] Toggling like | commentId: ${comment.id}, currentIsLiked: ${comment.isLiked}, currentLikes: ${comment.likes}, shouldLike: $shouldLike, action: ${shouldLike ? 'LIKE' : 'UNLIKELY'}, isReply: ${comment.parentComment != null}');
    setState(() {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        final updatedComment = comment.copyWith(
          likes: comment.likes + (shouldLike ? 1 : -1),
          isLiked: shouldLike,
        );
        _comments[index] = updatedComment;
      } else {
        for (final parentId in _repliesMap.keys) {
          final replies = _repliesMap[parentId]!;
          final replyIndex = replies.indexWhere((r) => r.id == comment.id);
          if (replyIndex != -1) {
            final updatedReply = replies[replyIndex].copyWith(
              likes: replies[replyIndex].likes + (shouldLike ? 1 : -1),
              isLiked: shouldLike,
            );
            _repliesMap[parentId]![replyIndex] = updatedReply;
            break;
          }
        }
      }
    });
    try {
      final result = shouldLike
          ? await _commentRepository.likeComment(comment.id)
          : await _commentRepository.unlikeComment(comment.id);
      result.fold(
        (failure) {
          debugPrint(
              '❌ [COMMENT_SHEET] Like toggle failed | commentId: ${comment.id}, action: ${shouldLike ? 'LIKE' : 'UNLIKE'}, failureMessage: ${failure.message}');
          setState(() {
            final index = _comments.indexWhere((c) => c.id == comment.id);
            if (index != -1) {
              final revertedComment = _comments[index].copyWith(
                likes: _comments[index].likes + (shouldLike ? -1 : 1),
                isLiked: !shouldLike,
              );
              _comments[index] = revertedComment;
            } else {
              for (final parentId in _repliesMap.keys) {
                final replies = _repliesMap[parentId]!;
                final replyIndex = replies.indexWhere((r) => r.id == comment.id);
                if (replyIndex != -1) {
                  final revertedReply = replies[replyIndex].copyWith(
                    likes: replies[replyIndex].likes + (shouldLike ? -1 : 1),
                    isLiked: !shouldLike,
                  );
                  _repliesMap[parentId]![replyIndex] = revertedReply;
                  break;
                }
              }
            }
          });
          if (!mounted) return;
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          debugPrint(
              '✅ [COMMENT_SHEET] Like toggled successfully | commentId: ${comment.id}, action: ${shouldLike ? 'LIKE' : 'UNLIKE'}');
        },
      );
    } catch (e, stackTrace) {
      debugPrint(
          '❌ [COMMENT_SHEET] Exception toggling like | commentId: ${comment.id}, action: ${shouldLike ? 'LIKE' : 'UNLIKE'}, error: ${e.toString()}, stackTrace: ${stackTrace.toString()}');
      setState(() {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          final revertedComment = _comments[index].copyWith(
            likes: _comments[index].likes + (shouldLike ? -1 : 1),
            isLiked: !shouldLike,
          );
          _comments[index] = revertedComment;
        } else {
          for (final parentId in _repliesMap.keys) {
            final replies = _repliesMap[parentId]!;
            final replyIndex = replies.indexWhere((r) => r.id == comment.id);
            if (replyIndex != -1) {
              final revertedReply = replies[replyIndex].copyWith(
                likes: replies[replyIndex].likes + (shouldLike ? -1 : 1),
                isLiked: !shouldLike,
              );
              _repliesMap[parentId]![replyIndex] = revertedReply;
              break;
            }
          }
        }
      });
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _deleteComment(Comment comment) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🗑️ [COMMENT_SHEET] DELETE COMMENT ATTEMPT');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🗑️ [COMMENT_SHEET] Comment ID: ${comment.id}');
    debugPrint('🗑️ [COMMENT_SHEET] Is Reply: ${comment.parentComment != null}');
    debugPrint('🗑️ [COMMENT_SHEET] Parent ID: ${comment.parentComment ?? "null"}');
    debugPrint('🗑️ [COMMENT_SHEET] Comments count before: ${_comments.length}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    try {
      debugPrint('🗑️ [COMMENT_SHEET] Calling API to delete...');
      final result = await _commentRepository.deleteComment(comment.id);
      result.fold(
        (failure) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('❌ [COMMENT_SHEET] DELETE FAILED');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('❌ [COMMENT_SHEET] Error: ${failure.message}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          if (!mounted) return;
          SafeNavigation.showSnackBar(
            context,
            SnackBar(
              content: Text('Erreur: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ [COMMENT_SHEET] DELETE SUCCESS');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('✅ [COMMENT_SHEET] Now removing from UI...');
          if (!mounted) return;
          setState(() {
            if (comment.parentComment != null) {
              final parentId = comment.parentComment!;
              final beforeCount = _repliesMap[parentId]?.length ?? 0;
              _repliesMap[parentId]?.removeWhere((r) => r.id == comment.id);
              final afterCount = _repliesMap[parentId]?.length ?? 0;
              debugPrint('✅ [COMMENT_SHEET] Removed reply from map | parentId: $parentId, before: $beforeCount, after: $afterCount');
              final parentIndex = _comments.indexWhere((c) => c.id == parentId);
              if (parentIndex != -1) {
                final oldCount = _comments[parentIndex].replyCount;
                _comments[parentIndex] = _comments[parentIndex].copyWith(
                  replyCount: max(0, _comments[parentIndex].replyCount - 1),
                );
                debugPrint('✅ [COMMENT_SHEET] Updated parent replyCount | oldCount: $oldCount, newCount: ${_comments[parentIndex].replyCount}');
              }
            } else {
              final beforeCount = _comments.length;
              _comments.removeWhere((c) => c.id == comment.id);
              final afterCount = _comments.length;
              _repliesMap.remove(comment.id);
              _expandedComments.remove(comment.id);
              debugPrint('✅ [COMMENT_SHEET] Removed top-level comment | before: $beforeCount, after: $afterCount');
            }
          });
          debugPrint('✅ [COMMENT_SHEET] UI updated successfully');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          SafeNavigation.showSnackBar(
            context,
            const SnackBar(
              content: Text('Commentaire supprimé'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_SHEET] EXCEPTION DELETING');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_SHEET] Error: $e');
      debugPrint('❌ [COMMENT_SHEET] Stack: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (!mounted) return;
      SafeNavigation.showSnackBar(
        context,
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🎨 [COMMENT_SHEET] Building widget | postId: ${widget.postId}, commentsCount: ${_comments.length}, isLoading: $_isLoading, hasReply: ${_replyingToId != null}');
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Commentaires',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _comments.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment,
                              size: 64,
                              color: Colors.grey[800],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun commentaire.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Soyez le premier à commenter.',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          debugPrint(
                              '📝 [COMMENT_SHEET] Rendering comment | index: $index, commentId: ${comment.id}, authorName: ${comment.author.name}, likes: ${comment.likes}, isLiked: ${comment.isLiked}, replyCount: ${comment.replyCount}');
                          if (comment.parentComment != null) {
                            return const SizedBox.shrink();
                          }
                          final isExpanded = _expandedComments.contains(comment.id);
                          final hasRepliesInMap = _repliesMap[comment.id] != null;
                          final repliesCount = _repliesMap[comment.id]?.length ?? 0;
                          debugPrint('🔍 [COMMENT_SHEET] Render check | commentId: ${comment.id}, isExpanded: $isExpanded, hasRepliesInMap: $hasRepliesInMap, repliesCount: $repliesCount');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InstagramCommentItem(
                                comment: comment,
                                onReply: () => _replyToComment(comment),
                                onLike: () => _toggleLike(comment),
                                onDelete: () => _deleteComment(comment),
                                onViewReplies: comment.replyCount > 0
                                    ? () => _toggleReplies(comment)
                                    : null,
                                isExpanded: isExpanded,
                                isLoadingReplies:
                                    _loadingReplies[comment.id] ?? false,
                              ),
                              if (isExpanded && hasRepliesInMap) ...[
                                ..._repliesMap[comment.id]!.map((reply) {
                                  debugPrint(
                                      '💬 [COMMENT_SHEET] Rendering reply | commentId: ${comment.id}, replyId: ${reply.id}, authorName: ${reply.author.name}');
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 56),
                                    child: _InstagramCommentItem(
                                      comment: reply,
                                      onReply: () => _replyToComment(comment),
                                      onLike: () => _toggleLike(reply),
                                      onDelete: () => _deleteComment(reply),
                                      isReply: true,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyingToUsername != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        color: const Color(0xFF0095F6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Répondre à ',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextSpan(
                                text: _replyingToUsername,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final avatarUrl = authProvider.userProfile?.avatarUrl;
                            return CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: avatarUrl != null
                                  ? CachedNetworkImageProvider(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 36,
                              maxHeight: 120,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _commentController,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: _replyingToUsername != null
                                    ? 'Répondre...'
                                    : 'Ajouter un commentaire...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _commentController,
                          builder: (context, value, child) {
                            final hasText = value.text.trim().isNotEmpty;
                            return GestureDetector(
                              onTap: hasText && !_isSending ? _sendComment : null,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasText
                                      ? const Color(0xFF0095F6)
                                      : Colors.transparent,
                                ),
                                child: Center(
                                  child: _isSending
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          Icons.send,
                                          color: hasText
                                              ? Colors.white
                                              : Colors.grey[700],
                                          size: 18,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _InstagramCommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback? onViewReplies;
  final VoidCallback? onDelete;
  final bool isExpanded;
  final bool isLoadingReplies;
  final bool isReply;
  const _InstagramCommentItem({
    required this.comment,
    required this.onReply,
    required this.onLike,
    this.onViewReplies,
    this.onDelete,
    this.isExpanded = false,
    this.isLoadingReplies = false,
    this.isReply = false,
  });
  @override
  State<_InstagramCommentItem> createState() => _InstagramCommentItemState();
}
class _InstagramCommentItemState extends State<_InstagramCommentItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }
  void _handleLike() {
    widget.onLike();
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
  }
  String _formatTimeAgo(DateTime dateTime) => TimeFormatter.formatTimeAgo(dateTime);
  void _showDeleteDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.userProfile?.id == widget.comment.author.id;
    if (!isOwner || widget.onDelete == null) return;
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Supprimer le commentaire',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          widget.comment.parentComment == null && widget.comment.replyCount > 0
              ? 'Ce commentaire a ${widget.comment.replyCount} réponse(s). Toutes les réponses seront également supprimées.'
              : 'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🧱 [COMMENT_ITEM] Building comment item | commentId: ${widget.comment.id}, authorName: ${widget.comment.author.name}, likes: ${widget.comment.likes}, isLiked: ${widget.comment.isLiked}, isReply: ${widget.isReply}');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.userProfile?.id == widget.comment.author.id;
    return GestureDetector(
      onLongPress: isOwner && widget.onDelete != null
          ? () => _showDeleteDialog(context)
          : null,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: widget.comment.author.avatarUrl != null
                ? CachedNetworkImageProvider(widget.comment.author.avatarUrl!)
                : null,
            child: widget.comment.author.avatarUrl == null
                ? Text(
                    widget.comment.author.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: widget.comment.author.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: widget.comment.content,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        debugPrint(
                            '❤️ [COMMENT_ITEM] Like button tapped | commentId: ${widget.comment.id}, currentIsLiked: ${widget.comment.isLiked}, currentLikes: ${widget.comment.likes}');
                        _handleLike();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ScaleTransition(
                          scale: _likeAnimation,
                          child: Icon(
                            widget.comment.isLiked
                                ? Icons.favorite
                                : Icons.favorite,
                            size: 12,
                            color: widget.comment.isLiked
                                ? Colors.red
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(widget.comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.comment.likes > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${widget.comment.likes} j\'aime',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text(
                        'Répondre',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.comment.replyCount > 0 && !widget.isReply) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      debugPrint(
                          '🔽 [COMMENT_ITEM] View replies tapped | commentId: ${widget.comment.id}, replyCount: ${widget.comment.replyCount}, isExpanded: ${widget.isExpanded}');
                      if (widget.onViewReplies != null) {
                        widget.onViewReplies!();
                      }
                    },
                    child: widget.isLoadingReplies
                        ? Row(
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chargement...',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 24,
                                height: 0.5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isExpanded
                                    ? 'Masquer les réponses'
                                    : 'Voir les ${widget.comment.replyCount} réponse${widget.comment.replyCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
typedef CommentSheet = CommentsBottomSheet;