import 'package:thot/core/utils/either.dart';
import 'package:thot/features/profile/domain/entities/user_profile.dart';
import 'package:thot/features/profile/domain/failures/profile_failure.dart';
abstract class ProfileRepository {
  Future<Either<ProfileFailure, UserProfile>> getProfile(String userId);
  Future<Either<ProfileFailure, UserProfile>> updateProfile(
      UserProfile profile);
  Future<Either<ProfileFailure, void>> followUser(String userId);
  Future<Either<ProfileFailure, void>> unfollowUser(String userId);
  Future<Either<ProfileFailure, List<UserProfile>>> getFollowers(String userId);
  Future<Either<ProfileFailure, List<UserProfile>>> getFollowing(String userId);
  Future<Either<ProfileFailure, Map<String, dynamic>>> searchUsers({
    required String query,
    Map<String, String>? filters,
    int page = 1,
    bool forceRefresh = false,
  });
  Future<Either<ProfileFailure, List<UserProfile>>> getSuggestedUsers();
  Future<Either<ProfileFailure, List<UserProfile>>> getTrendingUsers();
  List<String> getRecentSearches();
  void clearRecentSearches();
  void removeFromRecentSearches(String query);
  Future<List<String>> getSearchSuggestions(String query);
  void clearCache();
  Future<Either<ProfileFailure, Map<String, dynamic>>> getSavedPosts(
      {int page = 1, int limit = 20});
  Future<Either<ProfileFailure, Map<String, dynamic>>> getSavedShorts(
      {int page = 1, int limit = 20});
  Future<Either<ProfileFailure, Map<String, dynamic>>> getUserProfile(
      String userId);
  Future<Either<ProfileFailure, Map<String, dynamic>>> getUserPublicContent(
      String userId,
      {String contentType = 'all'});
  Future<Either<ProfileFailure, void>> togglePublicContent({
    required String contentId,
    required String contentType,
    required bool isPublic,
  });
}