import 'package:freezed_annotation/freezed_annotation.dart';
part 'search_result.freezed.dart';
part 'search_result.g.dart';
@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String id,
    required String title,
    required String description,
    required SearchResultType type,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) = _SearchResult;
  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}
enum SearchResultType {
  user,
  post,
  hashtag,
  topic,
}