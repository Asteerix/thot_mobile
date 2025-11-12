import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/content/shared/comments/comment.dart';
import 'package:thot/features/app/content/shared/comments/comment_failure.dart';

abstract class CommentRepository {
  Future<Either<CommentFailure, List<Comment>>> getComments(String postId,
      {int? page});
  Future<Either<CommentFailure, Comment>> addComment(
      String postId, String content,
      {String? parentCommentId});
  Future<Either<CommentFailure, void>> deleteComment(String commentId);
  Future<Either<CommentFailure, void>> likeComment(String commentId);
  Future<Either<CommentFailure, void>> unlikeComment(String commentId);
  Future<Either<CommentFailure, Comment>> updateComment(
      String commentId, String content);
  Future<Either<CommentFailure, List<Comment>>> getReplies(String commentId,
      {int? page});
  Future<Either<CommentFailure, List<Map<String, dynamic>>>> getCommentLikes(
      String commentId);
}
