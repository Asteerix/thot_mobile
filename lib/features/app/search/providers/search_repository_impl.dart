import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/search/models/search_result.dart';
import 'package:thot/features/app/search/models/search_failure.dart';
import 'package:thot/features/app/search/providers/search_repository.dart';
import 'package:thot/core/services/network/api_client.dart';
class SearchRepositoryImpl implements SearchRepository {
  final ApiService _apiService;
  SearchRepositoryImpl(this._apiService);
  @override
  Future<Either<SearchFailure, List<SearchResult>>> search(String query) async {
    try {
      final response = await _apiService.get('/search', queryParameters: {
        'q': query,
      });
      final List<dynamic> data = response.data['results'] ?? [];
      final results = data.map((item) => SearchResult.fromJson(item)).toList();
      return Right(results);
    } catch (e) {
      return Left(SearchFailureServer(e.toString()));
    }
  }
  @override
  Future<Either<SearchFailure, List<SearchResult>>> searchUsers(
      String query) async {
    try {
      final response = await _apiService.get('/search/users', queryParameters: {
        'q': query,
      });
      final List<dynamic> data = response.data['results'] ?? [];
      final results = data.map((item) => SearchResult.fromJson(item)).toList();
      return Right(results);
    } catch (e) {
      return Left(SearchFailureServer(e.toString()));
    }
  }
  @override
  Future<Either<SearchFailure, List<SearchResult>>> searchPosts(
      String query) async {
    try {
      final response = await _apiService.get('/search/posts', queryParameters: {
        'q': query,
      });
      final List<dynamic> data = response.data['results'] ?? [];
      final results = data.map((item) => SearchResult.fromJson(item)).toList();
      return Right(results);
    } catch (e) {
      return Left(SearchFailureServer(e.toString()));
    }
  }
  @override
  Future<Either<SearchFailure, List<String>>> getSearchSuggestions(
      String query) async {
    try {
      final response =
          await _apiService.get('/search/suggestions', queryParameters: {
        'q': query,
      });
      final List<dynamic> data = response.data['suggestions'] ?? [];
      final suggestions = data.map((item) => item.toString()).toList();
      return Right(suggestions);
    } catch (e) {
      return Left(SearchFailureServer(e.toString()));
    }
  }
}