import 'dart:developer' as developer;
import 'package:thot/core/utils/either.dart';
import 'package:thot/features/app/profile/models/user_profile.dart';
import 'package:thot/features/app/profile/models/profile_failure.dart';
import 'package:thot/features/app/profile/providers/profile_repository.dart';
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/config/api_routes.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiService _apiService;
  final List<String> _recentSearches = [];
  static const int _maxRecentSearches = 10;
  final Map<String, Map<String, dynamic>> _searchCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};
  ProfileRepositoryImpl(this._apiService);
  @override
  Future<Either<ProfileFailure, UserProfile>> getProfile(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId');
      return Right(UserProfile.fromJson(response.data));
    } catch (e) {
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, UserProfile>> updateProfile(
      UserProfile profile) async {
    try {
      final profileData = {
        'name': profile.name,
        if (profile.bio != null) 'bio': profile.bio,
        if (profile.avatarUrl != null) 'avatarUrl': profile.avatarUrl,
        if (profile.coverUrl != null) 'coverUrl': profile.coverUrl,
        if (profile.location != null) 'location': profile.location,
        if (profile.isJournalist) ...{
          if (profile.organization != null)
            'organization': profile.organization,
          if (profile.journalistRole != null)
            'journalistRole': profile.journalistRole,
          if (profile.socialLinks != null) 'socialLinks': profile.socialLinks,
          if (profile.specialties != null && profile.specialties!.isNotEmpty)
            'specialties': profile.specialties,
          if (profile.pressCard != null) 'pressCard': profile.pressCard,
          if (profile.formations != null)
            'formations': profile.formations!.map((f) => f.toJson()).toList(),
          if (profile.experience != null)
            'experience': profile.experience!.map((e) => e.toJson()).toList(),
        } else ...{
          if (profile.preferences != null) 'preferences': profile.preferences,
        }
      };
      final response = await _apiService.put(
        '/api/auth/profile',
        data: profileData,
      );
      final userData = response.data['data']?['user'] ??
          response.data['data'] ??
          response.data;
      return Right(UserProfile.fromJson(userData));
    } catch (e) {
      developer.log(
        'Error updating profile: $e',
        name: 'ProfileRepository',
        error: e,
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, void>> followUser(String userId) async {
    try {
      await _apiService.post('/api/users/follow/$userId');
      return const Right(null);
    } catch (e) {
      developer.log(
        'Error following journalist: $e',
        name: 'ProfileRepository',
        error: e,
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, void>> unfollowUser(String userId) async {
    try {
      await _apiService.post('/api/users/unfollow/$userId');
      return const Right(null);
    } catch (e) {
      developer.log(
        'Error unfollowing journalist: $e',
        name: 'ProfileRepository',
        error: e,
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, List<UserProfile>>> getFollowers(
      String userId) async {
    try {
      final url = '/api/users/$userId/followers';
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[FOLLOWERS_REPO] Fetching followers');
      print('   userId: $userId');
      print('   url: $url');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _apiService.get(url);
      print('[FOLLOWERS_REPO] Response received: ${response.statusCode}');
      print('[FOLLOWERS_REPO] Response data type: ${response.data.runtimeType}');

      final data = response.data;

      List<dynamic> followersList;
      if (data is List) {
        print('[FOLLOWERS_REPO] Data is List with ${data.length} items');
        followersList = data;
      } else if (data is Map) {
        print('[FOLLOWERS_REPO] Data is Map with keys: ${data.keys}');
        if (data['data'] is Map && data['data']['followers'] is List) {
          followersList = data['data']['followers'] as List<dynamic>;
          print('[FOLLOWERS_REPO] Extracted ${followersList.length} followers from data.followers');
        } else if (data['data'] is List) {
          followersList = data['data'] as List<dynamic>;
          print('[FOLLOWERS_REPO] Using data["data"] with ${followersList.length} items');
        } else if (data['followers'] is List) {
          followersList = data['followers'] as List<dynamic>;
          print('[FOLLOWERS_REPO] Using data["followers"] with ${followersList.length} items');
        } else {
          print('[FOLLOWERS_REPO] No List found, keys: ${data.keys}');
          followersList = [];
        }
      } else {
        print('[FOLLOWERS_REPO] ⚠️ Unexpected data type: ${data.runtimeType}');
        followersList = [];
      }

      final result = followersList.map((json) {
        try {
          final profile = UserProfile.fromJson(json);
          print('[FOLLOWERS_REPO] ✅ Parsed follower: ${profile.username}');
          return profile;
        } catch (e) {
          print('[FOLLOWERS_REPO] ❌ Error parsing follower: $e');
          return null;
        }
      }).where((p) => p != null).cast<UserProfile>().toList();

      print('[FOLLOWERS_REPO] ✅ Returning ${result.length} followers');
      return Right(result);
    } catch (e, stackTrace) {
      print('[FOLLOWERS_REPO] ❌ Exception: $e');
      print('[FOLLOWERS_REPO] Stack: $stackTrace');
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, List<UserProfile>>> getFollowing(
      String userId) async {
    try {
      final url = ApiRoutes.journalistFollowing(userId);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('[FOLLOWING_REPO] Fetching following');
      print('   userId: $userId');
      print('   url: $url');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _apiService.get(url);
      print('[FOLLOWING_REPO] Response received: ${response.statusCode}');
      print('[FOLLOWING_REPO] Response data type: ${response.data.runtimeType}');

      dynamic responseData = response.data;
      if (responseData is Map) {
        print('[FOLLOWING_REPO] Response is Map with keys: ${responseData.keys}');
        print('[FOLLOWING_REPO] data value: ${responseData['data']}');
        print('[FOLLOWING_REPO] data type: ${responseData['data'].runtimeType}');

        if (responseData['data'] is Map) {
          print('[FOLLOWING_REPO] data is Map with keys: ${responseData['data'].keys}');
          if (responseData['data']['following'] != null) {
            print('[FOLLOWING_REPO] Extracting data.following');
            responseData = responseData['data']['following'];
          } else {
            print('[FOLLOWING_REPO] ❌ No "following" key in data');
            responseData = [];
          }
        } else if (responseData['data'] is List) {
          print('[FOLLOWING_REPO] data is List with ${responseData['data'].length} items');
          responseData = responseData['data'];
        } else {
          print('[FOLLOWING_REPO] ❌ Unexpected data type');
          responseData = [];
        }
      }

      print('[FOLLOWING_REPO] Processing list, type: ${responseData.runtimeType}');
      print('[FOLLOWING_REPO] List length: ${responseData is List ? responseData.length : 'not a list'}');
      final users = (responseData as List?)
              ?.map((user) {
                try {
                  final profile = UserProfile.fromJson(user as Map<String, dynamic>);
                  print('[FOLLOWING_REPO] ✅ Parsed user: ${profile.username}');
                  return profile;
                } catch (e) {
                  print('[FOLLOWING_REPO] ❌ Error parsing user: $e');
                  return null;
                }
              })
              .where((user) => user != null)
              .cast<UserProfile>()
              .toList() ??
          [];

      print('[FOLLOWING_REPO] ✅ Returning ${users.length} following');
      return Right(users);
    } catch (e, stackTrace) {
      print('[FOLLOWING_REPO] ❌ Exception: $e');
      print('[FOLLOWING_REPO] Stack: $stackTrace');
      return Right([]);
    }
  }

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>>> searchUsers({
    required String query,
    Map<String, String>? filters,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = _getCacheKey(query, filters, page);
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        return Right(_searchCache[cacheKey]!);
      }
      final endpoint = query.isNotEmpty
          ? '${ApiRoutes.buildPath(ApiRoutes.journalists)}?search=$query'
          : ApiRoutes.buildPath(ApiRoutes.journalists);
      final journalistsResponse = await _apiService.get(endpoint);
      final data = journalistsResponse.data['data'];
      final journalistsList = data is Map
          ? (data['journalists'] as List?) ?? []
          : (data as List? ?? []);
      final journalists = journalistsList
          .map((json) => UserProfile.fromJson({
                ...json,
                'isJournalist': true,
              }))
          .toList();
      List<UserProfile> filteredUsers = journalists;
      if (filters != null) {
        if (filters['verified'] == 'true') {
          filteredUsers = filteredUsers.where((u) => u.isVerified).toList();
        }
        final minFollowers = int.tryParse(filters['minFollowers'] ?? '0') ?? 0;
        if (minFollowers > 0) {
          filteredUsers = filteredUsers
              .where((u) => u.followersCount >= minFollowers)
              .toList();
        }
        if (filters['sortBy'] == 'followers') {
          filteredUsers
              .sort((a, b) => b.followersCount.compareTo(a.followersCount));
        }
      }
      _addToRecentSearches(query);
      final result = {
        'users': filteredUsers,
        'totalCount': filteredUsers.length,
        'currentPage': page,
        'hasMore': false,
        'suggestions': _generateSuggestions(query, filteredUsers),
      };
      _searchCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return Right(result);
    } catch (e) {
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, List<UserProfile>>> getSuggestedUsers() async {
    try {
      final response =
          await _apiService.get(ApiRoutes.buildPath(ApiRoutes.journalists));
      final data = response.data['data'];
      final journalistsList = data is Map
          ? (data['journalists'] as List?) ?? []
          : (data as List? ?? []);
      final users = journalistsList
          .map((json) => UserProfile.fromJson({
                ...json,
                'isJournalist': true,
              }))
          .toList();
      users.sort((a, b) => b.followersCount.compareTo(a.followersCount));
      return Right(users.take(10).toList());
    } catch (e) {
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, List<UserProfile>>> getTrendingUsers() async {
    try {
      final result = await searchUsers(
        query: '',
        filters: {
          'type': 'journalist',
          'sortBy': 'followers',
        },
      );
      return result.fold(
        (failure) => Left(failure),
        (data) => Right((data['users'] as List<UserProfile>).take(10).toList()),
      );
    } catch (e) {
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  List<String> getRecentSearches() {
    return List.from(_recentSearches);
  }

  @override
  void clearRecentSearches() {
    _recentSearches.clear();
  }

  @override
  void removeFromRecentSearches(String query) {
    _recentSearches.remove(query);
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      final suggestions = _recentSearches
          .where((search) => search.toLowerCase().contains(query.toLowerCase()))
          .take(5)
          .toList();
      final commonSearches = [
        'politique',
        'économie',
        'technologie',
        'sport',
        'culture',
        'santé',
        'environnement',
        'international',
      ];
      for (final search in commonSearches) {
        if (search.toLowerCase().contains(query.toLowerCase()) &&
            !suggestions.contains(search)) {
          suggestions.add(search);
        }
      }
      return suggestions.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
  }

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>>> getSavedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url =
          '${ApiRoutes.buildPath(ApiRoutes.userSavedPosts)}?page=$page&limit=$limit';
      developer.log(
        'ProfileRepository: Fetching saved posts',
        name: 'ProfileRepository',
        error: {
          'url': url,
          'page': page.toString(),
          'limit': limit.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final response = await _apiService.get(url);
      final result = response.data ?? response;
      if (result is Map && result.containsKey('data')) {
        final dataToReturn = result['data'];
        developer.log(
          'ProfileRepository: Extracting data field to return',
          name: 'ProfileRepository',
          error: {
            'dataType': dataToReturn.runtimeType.toString(),
            'dataKeys': dataToReturn is Map
                ? dataToReturn.keys.toList().toString()
                : 'Not a Map',
          },
        );
        return Right(dataToReturn);
      }
      return Right(result);
    } catch (e, stackTrace) {
      developer.log(
        'ProfileRepository: Error fetching saved posts',
        name: 'ProfileRepository',
        error: e.toString(),
      );
      developer.log(
        'Stack trace: ${stackTrace.toString()}',
        name: 'ProfileRepository',
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>>> getSavedShorts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url =
          '${ApiRoutes.buildPath(ApiRoutes.userSavedShorts)}?page=$page&limit=$limit';
      developer.log(
        'ProfileRepository: Fetching saved shorts',
        name: 'ProfileRepository',
        error: {
          'url': url,
          'page': page.toString(),
          'limit': limit.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final response = await _apiService.get(url);
      final result = response.data ?? response;
      if (result is Map && result.containsKey('data')) {
        final dataToReturn = result['data'];
        developer.log(
          'ProfileRepository: Extracting data field to return',
          name: 'ProfileRepository',
          error: {
            'dataType': dataToReturn.runtimeType.toString(),
            'dataKeys': dataToReturn is Map
                ? dataToReturn.keys.toList().toString()
                : 'Not a Map',
          },
        );
        return Right(dataToReturn);
      }
      return Right(result);
    } catch (e, stackTrace) {
      developer.log(
        'ProfileRepository: Error fetching saved shorts',
        name: 'ProfileRepository',
        error: e.toString(),
      );
      developer.log(
        'Stack trace: ${stackTrace.toString()}',
        name: 'ProfileRepository',
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>>> getUserProfile(
      String userId) async {
    try {
      final response = await _apiService.get(
        ApiRoutes.buildPath(ApiRoutes.getUserProfile(userId)),
      );
      final data = response.data['data'] ?? response.data;
      return Right(data);
    } catch (e) {
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>>> getUserPublicContent(
    String userId, {
    String contentType = 'all',
  }) async {
    try {
      final url = '/api/users/public-content/$userId?type=$contentType';
      developer.log(
        'ProfileRepository: Fetching public content',
        name: 'ProfileRepository',
        error: {
          'url': url,
          'userId': userId,
          'contentType': contentType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      final response = await _apiService.get(url);
      final result = response.data ?? response;
      if (result is Map && result.containsKey('data')) {
        final dataToReturn = result['data'];
        developer.log(
          'ProfileRepository: Extracting data field for public content',
          name: 'ProfileRepository',
          error: {
            'dataType': dataToReturn.runtimeType.toString(),
            'dataKeys': dataToReturn is Map
                ? dataToReturn.keys.toList().toString()
                : 'Not a Map',
          },
        );
        return Right(dataToReturn);
      }
      return Right(result);
    } catch (e, stackTrace) {
      developer.log(
        'ProfileRepository: Error fetching public content',
        name: 'ProfileRepository',
        error: e.toString(),
      );
      developer.log(
        'Stack trace: ${stackTrace.toString()}',
        name: 'ProfileRepository',
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<ProfileFailure, void>> togglePublicContent({
    required String contentId,
    required String contentType,
    required bool isPublic,
  }) async {
    try {
      final response = await _apiService.post(
        ApiRoutes.buildPath('/users/toggle-public-content'),
        data: {
          'contentId': contentId,
          'contentType': contentType,
          'isPublic': isPublic,
        },
      );
      developer.log(
        'ProfileRepository: Toggle public content response',
        name: 'ProfileRepository',
        error: {
          'contentId': contentId,
          'contentType': contentType,
          'isPublic': isPublic,
          'response': response.data,
        },
      );
      return const Right(null);
    } catch (e) {
      developer.log(
        'ProfileRepository: Error toggling public content',
        name: 'ProfileRepository',
        error: e.toString(),
      );
      return Left(ProfileFailure.serverError(e.toString()));
    }
  }

  String _getCacheKey(String query, Map<String, String>? filters, int page) {
    final filterKey =
        filters?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$query|$filterKey|$page';
  }

  bool _isCacheValid(String key) {
    if (!_searchCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeLast();
    }
  }

  List<String> _generateSuggestions(String query, List<UserProfile> results) {
    final suggestions = <String>[];
    final specialties = results
        .where((u) => u.isJournalist)
        .expand((u) => (u as dynamic).specialties ?? [])
        .toSet()
        .take(5);
    suggestions.addAll(specialties.map((s) => s.toString()));
    final organizations = results
        .where((u) => u.organization != null)
        .map((u) => u.organization!)
        .toSet()
        .take(3);
    suggestions.addAll(organizations);
    return suggestions;
  }
}
