import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
import 'package:thot/features/comments/domain/entities/comment.dart';
import 'package:thot/features/comments/domain/repositories/comment_repository.dart';
import 'package:thot/features/comments/data/repositories/comment_repository_impl.dart';
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return ServiceLocator.instance.commentRepository;
});
class CommentsState {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;
  const CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.error,
  });
  CommentsState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
class CommentsNotifier extends StateNotifier<CommentsState> {
  final CommentRepository _repository;
  CommentsNotifier(this._repository) : super(const CommentsState());
  Future<void> loadComments(String postId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getComments(postId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (comments) => state = state.copyWith(
        isLoading: false,
        comments: comments,
        error: null,
      ),
    );
  }
  Future<void> addComment(String postId, String content) async {
    final result = await _repository.addComment(postId, content);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (comment) => state = state.copyWith(
        comments: [...state.comments, comment],
        error: null,
      ),
    );
  }
  Future<void> deleteComment(String commentId) async {
    final result = await _repository.deleteComment(commentId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) => state = state.copyWith(
        comments:
            state.comments.where((comment) => comment.id != commentId).toList(),
        error: null,
      ),
    );
  }
  Future<void> likeComment(String commentId) async {
    final result = await _repository.likeComment(commentId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedComments = state.comments.map((comment) {
          if (comment.id == commentId) {
            return comment.copyWith(
                isLiked: true, likes: comment.likes + 1);
          }
          return comment;
        }).toList();
        state = state.copyWith(comments: updatedComments, error: null);
      },
    );
  }
  Future<void> unlikeComment(String commentId) async {
    final result = await _repository.unlikeComment(commentId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedComments = state.comments.map((comment) {
          if (comment.id == commentId) {
            return comment.copyWith(
                isLiked: false, likes: comment.likes - 1);
          }
          return comment;
        }).toList();
        state = state.copyWith(comments: updatedComments, error: null);
      },
    );
  }
}
final commentsProvider =
    StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
        (ref, postId) {
  final repository = ref.watch(commentRepositoryProvider);
  final notifier = CommentsNotifier(repository);
  Future.microtask(() => notifier.loadComments(postId));
  return notifier;
});