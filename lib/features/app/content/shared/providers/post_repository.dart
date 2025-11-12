import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/models/question.dart';
import 'package:thot/features/app/content/shared/models/post_failure.dart';

abstract class PostRepository {
  Future<Either<PostFailure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
    String? category,
  });
  Future<Either<PostFailure, Post>> getPost(String id);
  Future<Either<PostFailure, Post>> createPost(Post post);
  Future<Either<PostFailure, void>> updatePost(String id, Post post);
  Future<Either<PostFailure, void>> deletePost(String id);
  Future<Either<PostFailure, void>> likePost(String id);
  Future<Either<PostFailure, void>> unlikePost(String id);
  Future<Either<PostFailure, List<Question>>> getQuestions({
    int page = 1,
    int limit = 20,
  });
  Future<Either<PostFailure, Question>> createQuestion(Question question);
}
