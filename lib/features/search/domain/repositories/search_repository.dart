import 'package:thot/core/utils/either.dart';
import 'package:thot/features/search/domain/entities/search_result.dart';
import 'package:thot/features/search/domain/failures/search_failure.dart';
abstract class SearchRepository {
  Future<Either<SearchFailure, List<SearchResult>>> search(String query);
  Future<Either<SearchFailure, List<SearchResult>>> searchUsers(String query);
  Future<Either<SearchFailure, List<SearchResult>>> searchPosts(String query);
  Future<Either<SearchFailure, List<String>>> getSearchSuggestions(
      String query);
}