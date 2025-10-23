import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/features/search/domain/entities/search_result.dart';
import 'package:thot/features/search/domain/repositories/search_repository.dart';
import 'package:thot/features/search/data/repositories/search_repository_impl.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ServiceLocator.instance.apiService);
});
class SearchState {
  final List<SearchResult> results;
  final List<SearchResult> userResults;
  final List<SearchResult> postResults;
  final List<String> suggestions;
  final bool isLoading;
  final String? error;
  final String currentQuery;
  const SearchState({
    this.results = const [],
    this.userResults = const [],
    this.postResults = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
    this.currentQuery = '',
  });
  SearchState copyWith({
    List<SearchResult>? results,
    List<SearchResult>? userResults,
    List<SearchResult>? postResults,
    List<String>? suggestions,
    bool? isLoading,
    String? error,
    String? currentQuery,
  }) {
    return SearchState(
      results: results ?? this.results,
      userResults: userResults ?? this.userResults,
      postResults: postResults ?? this.postResults,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }
}
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  SearchNotifier(this._repository) : super(const SearchState());
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentQuery: query,
    );
    final result = await _repository.search(query);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (results) => state = state.copyWith(
        isLoading: false,
        results: results,
        error: null,
      ),
    );
  }
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(userResults: []);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.searchUsers(query);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (results) => state = state.copyWith(
        isLoading: false,
        userResults: results,
        error: null,
      ),
    );
  }
  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(postResults: []);
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.searchPosts(query);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (results) => state = state.copyWith(
        isLoading: false,
        postResults: results,
        error: null,
      ),
    );
  }
  Future<void> getSuggestions(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }
    final result = await _repository.getSearchSuggestions(query);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (suggestions) => state = state.copyWith(
        suggestions: suggestions,
        error: null,
      ),
    );
  }
  void clearResults() {
    state = const SearchState();
  }
  void updateQuery(String query) {
    state = state.copyWith(currentQuery: query);
  }
}
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchNotifier(repository);
});
final searchSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(searchRepositoryProvider);
  final result = await repository.getSearchSuggestions(query);
  return result.fold(
    (failure) => <String>[],
    (suggestions) => suggestions,
  );
});