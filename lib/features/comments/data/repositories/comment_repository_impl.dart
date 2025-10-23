import 'package:flutter/foundation.dart';
import 'package:thot/core/utils/either.dart';
import 'package:thot/core/network/api_client.dart';
import 'package:thot/core/constants/api_routes_helper.dart';
import 'package:thot/core/constants/api_routes.dart';
import 'package:thot/features/comments/domain/entities/comment.dart';
import 'package:thot/features/comments/domain/failures/comment_failure.dart';
import 'package:thot/features/comments/domain/repositories/comment_repository.dart';
import 'package:thot/features/comments/data/models/comment_dto.dart';
class CommentRepositoryImpl implements CommentRepository {
  final ApiService _apiService;
  CommentRepositoryImpl(this._apiService);
  @override
  Future<Either<CommentFailure, List<Comment>>> getComments(String postId,
      {int? page}) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📡 [COMMENT_REPO] GET COMMENTS REQUEST');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📡 [COMMENT_REPO] Post ID: $postId');
      debugPrint('📡 [COMMENT_REPO] Page: ${page ?? 1}');
      final response = await _apiService.get(
        '${ApiRoutesHelper.getComments}/$postId?page=${page ?? 1}&sortBy=recent',
      );
      final responseData = response.data;
      if (responseData == null) {
        debugPrint('⚠️ [COMMENT_REPO] Response data is null');
        return const Right([]);
      }
      final dataObject = responseData['data'];
      if (dataObject == null) {
        debugPrint('⚠️ [COMMENT_REPO] Data object is null');
        return const Right([]);
      }
      final commentsData = dataObject['comments'] as List?;
      if (commentsData == null) {
        debugPrint('⚠️ [COMMENT_REPO] Comments data is null');
        return const Right([]);
      }
      final comments = commentsData
          .map((json) => CommentDto.fromJson(json as Map<String, dynamic>))
          .map((dto) => _dtoToEntity(dto))
          .toList();
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [COMMENT_REPO] COMMENTS LOADED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [COMMENT_REPO] Post ID: $postId');
      debugPrint('✅ [COMMENT_REPO] Comments count: ${comments.length}');
      for (int i = 0; i < comments.length; i++) {
        final comment = comments[i];
        debugPrint('💬 [COMMENT_REPO] Comment #$i:');
        debugPrint('   - ID: ${comment.id}');
        debugPrint('   - Author: ${comment.author.name}');
        debugPrint('   - Reply count: ${comment.replyCount}');
        debugPrint('   - Parent comment: ${comment.parentComment ?? "null (top-level)"}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return Right(comments);
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_REPO] GET COMMENTS ERROR');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_REPO] Post ID: $postId');
      debugPrint('❌ [COMMENT_REPO] Error: ${e.toString()}');
      debugPrint('❌ [COMMENT_REPO] Stack trace: ${stackTrace.toString()}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, Comment>> addComment(
      String postId, String content,
      {String? parentCommentId}) async {
    try {
      final isReply = parentCommentId != null;
      final payload = {
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      };
      final response = await _apiService.post(
        '${ApiRoutesHelper.createComment}/$postId',
        data: payload,
      );
      final responseData = response.data;
      final dataObject = responseData['data'];
      final commentData = dataObject['comment'];
      final dto = CommentDto.fromJson(commentData as Map<String, dynamic>);
      final comment = _dtoToEntity(dto);
      if (isReply) {
        final isLinked = comment.parentComment == parentCommentId;
        debugPrint('🔗 [COMMENT_REPO] Reply created | id: ${comment.id}, parentComment: ${comment.parentComment}, isLinked: $isLinked');
      } else {
        debugPrint('✅ [COMMENT_REPO] Comment created | id: ${comment.id}, author: ${comment.author.name}');
      }
      return Right(comment);
    } catch (e) {
      debugPrint('❌ [COMMENT_REPO] Add comment error | postId: $postId, error: ${e.toString()}');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, void>> deleteComment(String commentId) async {
    try {
      await _apiService.delete(
        '${ApiRoutesHelper.deleteComment}/$commentId',
      );
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [COMMENT_REPO] Delete comment error | commentId: $commentId, error: ${e.toString()}');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, void>> likeComment(String commentId) async {
    try {
      await _apiService.post(
        ApiRoutesHelper.commentLike(commentId),
        data: {},
      );
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [COMMENT_REPO] Like comment error | commentId: $commentId, error: ${e.toString()}');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, void>> unlikeComment(String commentId) async {
    try {
      await _apiService.post(
        ApiRoutesHelper.commentUnlike(commentId),
        data: {},
      );
      return const Right(null);
    } catch (e) {
      debugPrint('❌ [COMMENT_REPO] Unlike comment error | commentId: $commentId, error: ${e.toString()}');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, Comment>> updateComment(
      String commentId, String content) async {
    try {
      final response = await _apiService.put(
        '${ApiRoutesHelper.updateComment}/$commentId',
        data: {'content': content},
      );
      final dto = CommentDto.fromJson(response.data as Map<String, dynamic>);
      return Right(_dtoToEntity(dto));
    } catch (e) {
      debugPrint('❌ [COMMENT_REPO] Update comment error | commentId: $commentId, error: ${e.toString()}');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, List<Comment>>> getReplies(String commentId,
      {int? page}) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📡 [COMMENT_REPO] GET REPLIES REQUEST');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📡 [COMMENT_REPO] Comment ID: $commentId');
      debugPrint('📡 [COMMENT_REPO] Page: ${page ?? 1}');
      debugPrint('📡 [COMMENT_REPO] URL: ${ApiRoutesHelper.getCommentReplies}/$commentId?page=${page ?? 1}');
      final response = await _apiService.get(
        '${ApiRoutesHelper.getCommentReplies}/$commentId?page=${page ?? 1}',
      );
      debugPrint('📡 [COMMENT_REPO] Response received');
      debugPrint('📡 [COMMENT_REPO] Response data type: ${response.data.runtimeType}');
      final responseData = response.data;
      debugPrint('📡 [COMMENT_REPO] Response data: ${responseData.toString().substring(0, responseData.toString().length > 200 ? 200 : responseData.toString().length)}...');
      final dataObject = responseData['data'];
      debugPrint('📡 [COMMENT_REPO] Data object: ${dataObject.runtimeType}');
      final repliesData = (dataObject['replies'] ?? []) as List;
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [COMMENT_REPO] REPLIES FETCHED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [COMMENT_REPO] Comment ID: $commentId');
      debugPrint('✅ [COMMENT_REPO] Replies count: ${repliesData.length}');
      final replies = repliesData
          .map((json) => CommentDto.fromJson(json as Map<String, dynamic>))
          .map((dto) => _dtoToEntity(dto))
          .toList();
      debugPrint('✅ [COMMENT_REPO] Replies converted to entities: ${replies.length}');
      for (int i = 0; i < replies.length; i++) {
        final reply = replies[i];
        final hasParent = reply.parentComment != null;
        debugPrint('🔗 [COMMENT_REPO] Reply #$i:');
        debugPrint('   - ID: ${reply.id}');
        debugPrint('   - Author: ${reply.author.name}');
        debugPrint('   - Content: ${reply.content.substring(0, reply.content.length > 30 ? 30 : reply.content.length)}...');
        debugPrint('   - Parent: ${reply.parentComment}');
        debugPrint('   - Has parent: $hasParent');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return Right(replies);
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_REPO] GET REPLIES ERROR');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [COMMENT_REPO] Comment ID: $commentId');
      debugPrint('❌ [COMMENT_REPO] Error: ${e.toString()}');
      debugPrint('❌ [COMMENT_REPO] Stack trace: ${stackTrace.toString()}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  @override
  Future<Either<CommentFailure, List<Map<String, dynamic>>>> getCommentLikes(
      String commentId) async {
    try {
      final response = await _apiService.get(
        '${ApiRoutesHelper.getCommentLikes}/$commentId',
      );
      final users =
          List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      return Right(users);
    } catch (e) {
      debugPrint('❌ [COMMENT_REPO] Get comment likes error | commentId: $commentId, error: ${e.toString()}');
      return Left(CommentFailure.serverError(e.toString()));
    }
  }
  Comment _dtoToEntity(CommentDto dto) {
    return Comment(
      id: dto.id,
      postId: dto.postId,
      content: dto.content,
      author: CommentAuthor(
        id: dto.author.id,
        username: dto.author.username,
        name: dto.author.name,
        avatarUrl: dto.author.avatarUrl,
        isVerified: dto.author.isVerified,
      ),
      likes: dto.likesCount,
      isLiked: dto.isLiked,
      replyCount: dto.replyCount,
      parentComment: dto.parentCommentId,
      status: dto.status ?? 'active',
      createdAt: dto.createdAt ?? DateTime.now(),
      updatedAt: dto.updatedAt ?? DateTime.now(),
      isEdited: dto.isEdited ?? false,
      isDeleted: dto.isDeleted ?? false,
      deletedAt: dto.deletedAt,
    );
  }
}