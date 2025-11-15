import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:thot/core/services/network/api_client.dart';
import 'package:thot/core/services/connectivity/connectivity_service.dart';
import 'package:thot/core/config/api_routes.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/config/app_config.dart';
import 'package:thot/core/services/logging/logger_service.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/post_repository.dart';
import 'package:thot/core/utils/api_response_helper.dart';

class PostRepositoryImpl with ConnectivityAware {
  final ApiService _apiService;
  final _logger = LoggerService.instance;
  final _cache = _LruCache<String, Object>(capacity: 64);
  final _inFlight = _InFlight();
  PostRepositoryImpl(this._apiService);
  static final _validTypes = {
    'article',
    'video',
    'podcast',
    'short',
    'question',
    'posts',
    'saved',
  };
  static bool isValidType(String? type) {
    return type == null || _validTypes.contains(type);
  }

  @override
  Future<List<Post>> getSubscriptionsPosts(
      {int page = 1, int limit = 20}) async {
    return withConnectivity(() async {
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': limit.toString(),
        };
        final endpoint =
            '/api/subscriptions/posts?${Uri(queryParameters: queryParams).query}';
        print('📡 Fetching subscriptions posts');
        final response = await _apiService.get(endpoint);
        dynamic responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          responseData = responseData['data'];
        }
        final posts = (responseData['posts'] as List?)?.map((post) {
              try {
                final transformedPost =
                    _transformPost(post as Map<String, dynamic>);
                return Post.fromJson(transformedPost);
              } catch (e, _) {
                print('Error transforming subscription post');
                final fallbackPost =
                    _createFallbackPost(post as Map<String, dynamic>);
                return Post.fromJson(fallbackPost);
              }
            }).toList() ??
            [];
        return posts;
      } catch (e, _) {
        print('Error fetching subscriptions posts');
        return [];
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getSavedPosts({int page = 1}) async {
    return withConnectivity(() async {
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': '20',
        };
        final endpoint =
            '/api/users/saved-posts?${Uri(queryParameters: queryParams).query}';
        print('📡 Fetching saved posts');
        final response = await _apiService.get(endpoint);
        dynamic responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          responseData = responseData['data'];
        }
        final posts = (responseData['posts'] as List?)?.map((post) {
              try {
                return _transformPost(post as Map<String, dynamic>);
              } catch (e, _) {
                print('Error transforming saved post');
                return _createFallbackPost(post as Map<String, dynamic>);
              }
            }).toList() ??
            [];
        return {
          'posts': posts,
          'total': responseData['total'] ?? posts.length,
          'page': responseData['page'] ?? page,
        };
      } catch (e, _) {
        print('Error fetching saved posts');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    String? type,
    String? status,
    String? search,
    String? userId,
    String? domain,
    String? sort,
    String? politicalView,
  }) async {
    if (!isValidType(type)) {
      throw ArgumentError('Invalid post type: $type');
    }
    if (type == 'saved') {
      print('🔍 getPosts redirecting to getSavedPosts');
      return getSavedPosts(page: page);
    }
    return withConnectivity(() async {
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': '20',
          if (type != null) 'type': type,
          if (status != null) 'status': status,
          if (search != null) 'search': search,
          if (userId != null && userId != 'undefined' && userId != 'null')
            'journalist': userId,
          if (domain != null) 'domain': domain,
          if (sort != null) 'sort': sort,
          if (politicalView != null &&
              politicalView != 'all' &&
              politicalView != 'neutral')
            'politicalView': politicalView,
          if (type == 'short' || type == 'video' || type == 'live')
            'populate': 'journalist',
        };
        final endpoint =
            '/api/posts?${Uri(queryParameters: queryParams).query}';
        print('📡 Fetching posts');
        final response = await _apiService.get(endpoint);
        dynamic responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          responseData = responseData['data'];
        }
        final posts = (responseData['posts'] as List?)?.map((post) {
              try {
                return _transformPost(post as Map<String, dynamic>);
              } catch (e, _) {
                print('Error transforming post data');
                return _createFallbackPost(post as Map<String, dynamic>);
              }
            }).toList() ??
            [];
        return {
          'posts': posts,
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
        };
      } catch (e, _) {
        print('Get posts error');
        rethrow;
      }
    });
  }

  Map<String, dynamic> transformPost(Map<String, dynamic> post) {
    return _transformPost(post);
  }

  Map<String, dynamic> _transformPost(Map<String, dynamic> post) {
    var transformed = Map<String, dynamic>.from(post);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 _transformPost - opposedByPosts RAW:');
    print('   Type: ${transformed['opposedByPosts']?.runtimeType}');
    print('   Value: ${transformed['opposedByPosts']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (transformed['journalist'] != null) {
      final journalist = transformed['journalist'] as Map<String, dynamic>;
      print('👤 Journalist data in _transformPost');
    }
    if (transformed['_id'] == null && transformed['id'] != null) {
      transformed['_id'] = transformed['id'];
    } else if (transformed['_id'] == null && transformed['id'] == null) {
      print('WARNING: Post without ID detected');
    }
    var existingPoliticalOrientation =
        transformed['politicalOrientation'] as Map<String, dynamic>? ?? {};
    transformed['politicalOrientation'] = {
      'userVotes': existingPoliticalOrientation['userVotes'] ?? {},
      'journalistChoice':
          existingPoliticalOrientation['journalistChoice'] ?? 'neutral',
      'finalScore': existingPoliticalOrientation['finalScore'] ?? 0.0,
      'dominantView': existingPoliticalOrientation['dominantView'],
      'hasVoted': existingPoliticalOrientation['hasVoted'] ?? false,
    };
    transformed['stats'] = {
      'views': 0,
      'responses': 0,
      'readTime': null,
      'completion': 0.0,
      'engagement': 0.0,
      ...(transformed['stats'] as Map<String, dynamic>? ?? {}),
    };
    var interactions =
        transformed['interactions'] as Map<String, dynamic>? ?? {};
    transformed['interactions'] = {
      'likes': interactions['likes'] ?? 0,
      'dislikes': interactions['dislikes'] ?? 0,
      'comments': interactions['comments'] ?? 0,
      'reports': interactions['reports'] ?? 0,
      'bookmarks': interactions['bookmarks'] ?? 0,
      'isLiked': interactions['isLiked'] ?? false,
      'isBookmarked':
          interactions['isBookmarked'] ?? interactions['isSaved'] ?? false,
    };
    if (transformed['journalist'] != null) {
      var journalist = Map<String, dynamic>.from(transformed['journalist'] as Map<String, dynamic>);

      // CORRECTION CRITIQUE: Mapper _id vers id
      if (journalist['_id'] != null) {
        if (journalist['_id'] is Map && journalist['_id']['\$oid'] != null) {
          journalist['id'] = journalist['_id']['\$oid'].toString();
        } else {
          journalist['id'] = journalist['_id'].toString();
        }
      } else if (journalist['id'] == null) {
        journalist['id'] = journalist['userId'] ??
                          journalist['user']?['_id'] ??
                          journalist['user']?['id'];
      }

      journalist['name'] = journalist['name'] ?? 'Unknown';
      journalist['username'] = journalist['username'] ??
          journalist['name']?.toString().toLowerCase().replaceAll(' ', '_') ??
          'unknown';
      journalist['history'] = journalist['history'] ?? '';
      journalist['specialties'] = journalist['specialties'] ?? [];
      journalist['isVerified'] = journalist['verified'] ?? journalist['isVerified'] ?? false;
      journalist['isFollowing'] = journalist['isFollowing'] ?? false;

      transformed['journalist'] = journalist;

      // Debug: Vérifier l'ID
      if (journalist['id'] == null || journalist['id'].toString().isEmpty) {
        print('⚠️ WARNING: Post "${transformed['title']}" has journalist but no ID!');
        print('   Journalist data: $journalist');
        print('   Full journalist keys: ${journalist.keys.toList()}');
        print('   _id value: ${journalist['_id']}');
        print('   _id type: ${journalist['_id'].runtimeType}');
      }
    } else {
      print('⚠️ WARNING: Post "${transformed['title']}" has no journalist!');
    }
    transformed['metadata'] = _transformMetadata(
      transformed['type'] as String?,
      transformed['metadata'] as Map<String, dynamic>?,
    );
    if (transformed['opposingPosts'] != null) {
      transformed['opposingPosts'] =
          (transformed['opposingPosts'] as List).map((post) {
        String imageUrl = post['imageUrl'] ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = 'https://via.placeholder.com/400x300';
        }
        return {
          'postId': post['postId'] ?? post['post'] ?? post['_id'],
          'title': post['title'] ?? '',
          'imageUrl': imageUrl,
          'description': post['description'] ?? '',
        };
      }).toList();
    }
    if (transformed['opposedByPosts'] != null) {
      transformed['opposedByPosts'] =
          (transformed['opposedByPosts'] as List).map((post) {
        String imageUrl = post['imageUrl'] ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = 'https://via.placeholder.com/400x300';
        }
        return {
          'postId': post['post'] ?? post['_id'],
          'title': post['title'] ?? '',
          'imageUrl': imageUrl,
          'description': post['description'] ?? '',
        };
      }).toList();
    }
    if (transformed['imageUrl'] == null ||
        transformed['imageUrl'].toString().isEmpty) {
      transformed['imageUrl'] = '';
    } else {
      String imageUrl = transformed['imageUrl'].toString();
      if (!imageUrl.startsWith('http') && !imageUrl.startsWith('assets/')) {
        transformed['imageUrl'] = 'https://via.placeholder.com/400x300';
      }
    }
    if (transformed['thumbnailUrl'] == null ||
        transformed['thumbnailUrl'].toString().isEmpty) {
      transformed['thumbnailUrl'] = null;
    } else {
      String thumbnailUrl = transformed['thumbnailUrl'].toString();
      if (!thumbnailUrl.startsWith('http') &&
          !thumbnailUrl.startsWith('assets/')) {
        transformed['thumbnailUrl'] = 'https://via.placeholder.com/400x300';
      }
    }
    transformed['tags'] ??= [];
    transformed['sources'] ??= [];
    return transformed;
  }

  Map<String, dynamic> _createFallbackPost(Map<String, dynamic> post) {
    var existingPoliticalOrientation =
        post['politicalOrientation'] as Map<String, dynamic>? ?? {};
    return {
      '_id': post['_id'],
      'title': post['title'] ?? 'Untitled',
      'type': post['type'] ?? 'article',
      'domain': post['domain'] ?? 'politique',
      'status': post['status'] ?? 'draft',
      'imageUrl': _processImageUrl(post['imageUrl']),
      'content': post['content'] ?? '',
      'createdAt': post['createdAt'] ?? DateTime.now().toIso8601String(),
      'politicalOrientation': {
        'userVotes': existingPoliticalOrientation['userVotes'] ?? {},
        'journalistChoice':
            existingPoliticalOrientation['journalistChoice'] ?? 'neutral',
        'finalScore': existingPoliticalOrientation['finalScore'] ?? 0.0,
        'dominantView': existingPoliticalOrientation['dominantView'],
        'hasVoted': existingPoliticalOrientation['hasVoted'] ?? false,
      },
      'stats': {
        'views': 0,
        'responses': 0,
        'completion': 0.0,
        'engagement': 0.0,
      },
      'interactions': {
        'likes': 0,
        'comments': 0,
        'bookmarks': 0,
        'isLiked': false,
        'isSaved': false,
      },
      'metadata': {},
      'tags': [],
      'sources': [],
    };
  }

  Map<String, dynamic> _transformMetadata(
      String? type, Map<String, dynamic>? metadata) {
    if (metadata == null) return {};
    switch (type) {
      case 'article':
        return {
          'article': {
            'wordCount': metadata['wordCount'],
            'sources': metadata['sources'] ?? [],
            'citations': metadata['citations'] ?? [],
            'relatedArticles': metadata['relatedArticles'] ?? [],
          }
        };
      case 'video':
        return {
          'video': {
            'duration': metadata['duration'],
            'quality': metadata['quality'],
            'transcript': metadata['transcript'],
            'chapters': metadata['chapters'] ?? [],
          }
        };
      case 'question':
        final questionData = metadata['question'] ?? metadata;
        return {
          'question': {
            'options': (questionData['options'] as List?)
                    ?.map((option) => {
                          '_id': option['_id'] ?? '',
                          'text': option['text'] ?? '',
                          'votes': option['votes'] ?? 0,
                        })
                    .toList() ??
                [],
            'totalVotes': questionData['totalVotes'] ?? 0,
            'isMultipleChoice': questionData['isMultipleChoice'] ?? false,
            'allowComments': questionData['allowComments'] ?? true,
            'endDate': questionData['endDate'],
            'voters': questionData['voters'] ?? [],
          }
        };
      default:
        return metadata;
    }
  }

  String _processImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http') || imageUrl.startsWith('assets/')) {
      return imageUrl;
    }
    return 'https://via.placeholder.com/400x300';
  }

  @override
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    if (!isValidType(postData['type'] as String?)) {
      throw ArgumentError('Invalid post type: ${postData['type']}');
    }
    if (postData['domain'] != null) {
      postData['domain'] = postData['domain'].toString().toLowerCase();
    }
    return withConnectivity(() async {
      try {
        print('📤 Creating post');
        print('📦 Post data: ${postData.toString()}');
        final response = await _apiService.post('/api/posts', data: postData);
        final result = response.data ?? response;
        print('✅ Post created successfully');
        print('📦 Result: ${result.toString()}');
        return result;
      } catch (e) {
        print('❌ Create post error: ${e.toString()}');
        if (e is DioException) {
          print('❌ Status code: ${e.response?.statusCode}');
          print('❌ Response headers: ${e.response?.headers}');
          print('❌ Response data: ${e.response?.data}');
          if (e.response?.data is Map) {
            final data = e.response?.data as Map;
            print('❌ Error message: ${data['message'] ?? data['error'] ?? 'No error message'}');
          }
        }
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> updatePost(
      String id, Map<String, dynamic> postData) async {
    if (!isValidType(postData['type'] as String?)) {
      throw ArgumentError('Invalid post type: ${postData['type']}');
    }
    if (postData['domain'] != null) {
      postData['domain'] = postData['domain'].toString().toLowerCase();
    }
    return withConnectivity(() async {
      try {
        final response =
            await _apiService.patch('/api/posts/$id', data: postData);
        return response.data ?? response;
      } catch (e) {
        print('Update post error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getPost(String id) async {
    return withConnectivity(() async {
      try {
        final response = await _apiService.get('/api/posts/$id');
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedData = _transformPost(postData);
        return transformedData;
      } catch (e) {
        print('Get post error');
        rethrow;
      }
    });
  }

  @override
  Future<void> deletePost(String id) async {
    return withConnectivity(() async {
      try {
        await _apiService.delete('/api/posts/$id');
      } catch (e) {
        print('Delete post error');
        rethrow;
      }
    });
  }

  @override
  Future<bool> checkDuplicate(String hash) async {
    return withConnectivity(() async {
      try {
        final response =
            await _apiService.get('/api/posts/check-duplicate?hash=$hash');
        return response.data['isDuplicate'] ?? false;
      } catch (e) {
        print('Check duplicate error');
        return false;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> interactWithPost(
      String id, String type, String action) async {
    return withConnectivity(() async {
      try {
        print('🎯 Interact with post');
        final response = await _apiService.post(
          '/api/posts/$id/interact',
          data: {'type': type, 'action': action},
        );
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Interaction success');
        return transformedPost;
      } catch (e) {
        print('Post interaction error');
        rethrow;
      }
    });
  }

  Future<Map<String, dynamic>> votePoliticalOrientation(
      String postId, String orientation) async {
    return withConnectivity(() async {
      try {
        print('🗳️ Vote political orientation');
        final response = await _apiService.post(
          '/api/posts/$postId/political-view',
          data: {'view': orientation},
        );
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Political vote success');
        return transformedPost;
      } catch (e) {
        print('Political vote error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> likePost(String id) async {
    return withConnectivity(() async {
      try {
        print('👍 Like post request');
        final response =
            await _apiService.post('/api/posts/$id/like', data: {});
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Like post success');
        return transformedPost;
      } catch (e) {
        print('Like post error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> unlikePost(String id) async {
    return withConnectivity(() async {
      try {
        print('👎 Unlike post request');
        final response = await _apiService.delete('/api/posts/$id/like');
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Unlike post success');
        return transformedPost;
      } catch (e) {
        print('Unlike post error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> savePost(String id) async {
    return withConnectivity(() async {
      try {
        print('💾 Save post request');
        final response =
            await _apiService.post('/api/posts/$id/save', data: {});
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Save post success');
        return transformedPost;
      } catch (e) {
        print('Save post error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> unsavePost(String id) async {
    return withConnectivity(() async {
      try {
        print('💾 Unsave post request');
        final response = await _apiService.post('/api/posts/$id/unsave');
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Unsave post success');
        return transformedPost;
      } catch (e) {
        print('Unsave post error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> toggleLike(String id) async {
    return withConnectivity(() async {
      try {
        final post = await getPost(id);
        final isLiked =
            (post['interactions'] as Map<String, dynamic>?)?['isLiked'] ??
                false;
        if (isLiked) {
          return await interactWithPost(id, 'like', 'remove');
        } else {
          return await likePost(id);
        }
      } catch (e) {
        print('Toggle like error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> toggleBookmark(String id) async {
    return withConnectivity(() async {
      try {
        final post = await getPost(id);
        final isBookmarked =
            (post['interactions'] as Map<String, dynamic>?)?['isBookmarked'] ??
                false;
        if (isBookmarked) {
          return await unsavePost(id);
        } else {
          return await savePost(id);
        }
      } catch (e) {
        print('Toggle bookmark error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> voteOnQuestion(
      String postId, String optionId) async {
    return withConnectivity(() async {
      try {
        print('🗳️ Vote on question');
        final response = await _apiService.post(
          '/api/posts/$postId/vote',
          data: {'optionId': optionId},
        );
        Map<String, dynamic> postData;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            postData = responseData['data'] as Map<String, dynamic>;
          } else {
            postData = responseData;
          }
        } else {
          postData = response.data ?? {};
        }
        final transformedPost = _transformPost(postData);
        print('✅ Vote success');
        return transformedPost;
      } catch (e) {
        print('Vote on question error');
        rethrow;
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPostInteractions(
      String id, String type) async {
    return withConnectivity(() async {
      try {
        print('📊 Get post interactions');
        final response =
            await _apiService.get('/api/posts/$id/interactions?type=$type');
        List<Map<String, dynamic>> users;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            users = List<Map<String, dynamic>>.from(
                responseData['data'] as List? ?? []);
          } else {
            users = List<Map<String, dynamic>>.from(
                responseData['users'] as List? ?? []);
          }
        } else if (response.data is List) {
          users = List<Map<String, dynamic>>.from(response.data);
        } else {
          users = [];
        }
        print('✅ Got interactions');
        return users;
      } catch (e) {
        print('Get post interactions error');
        return [];
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getPoliticalVoters(
      String id, String view) async {
    return withConnectivity(() async {
      try {
        print('🗳️ Get political voters');
        final response =
            await _apiService.get('/api/posts/$id/political-voters?orientation=$view');
        Map<String, dynamic> result;
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData['success'] == true && responseData['data'] != null) {
            result = responseData['data'] as Map<String, dynamic>;
          } else {
            result = responseData;
          }
        } else {
          result = response.data ?? {};
        }
        print('✅ Got political voters');
        return result;
      } catch (e) {
        print('Get political voters error');
        return {'voters': [], 'total': 0};
      }
    });
  }

  @override
  Future<Map<String, dynamic>> searchPostsWithRelevance(
    String query, {
    int page = 1,
    int limit = 20,
    String? type,
    String? domain,
  }) async {
    return withConnectivity(() async {
      try {
        print('🔍 Search posts with relevance');
        final queryParams = {
          'search': query,
          'page': page.toString(),
          'limit': limit.toString(),
          if (type != null) 'type': type,
          if (domain != null) 'domain': domain,
          'includeRelevance': 'true',
        };
        final endpoint =
            '/api/posts/search?${Uri(queryParameters: queryParams).query}';
        final response = await _apiService.get(endpoint);
        dynamic responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          responseData = responseData['data'];
        }
        final posts = (responseData['posts'] as List?)?.map((post) {
              try {
                return _transformPost(post as Map<String, dynamic>);
              } catch (e, _) {
                print('Error transforming search result');
                return _createFallbackPost(post as Map<String, dynamic>);
              }
            }).toList() ??
            [];
        print('✅ Search completed');
        return {
          'posts': posts,
          'total': responseData['total'] ?? posts.length,
          'page': responseData['page'] ?? page,
          'relevanceScores': responseData['relevanceScores'] ?? {},
        };
      } catch (e, _) {
        print('Search posts error');
        return {
          'posts': [],
          'total': 0,
          'page': page,
          'relevanceScores': {},
        };
      }
    });
  }

  static final _validJournalistPostTypes = {
    'article',
    'video',
    'podcast',
    'live',
    'short',
    'question',
  };
  static bool isValidJournalistPostType(String? type) {
    return type == null || _validJournalistPostTypes.contains(type);
  }

  @override
  Future<Map<String, dynamic>> getJournalistProfile(String id,
      {bool isCurrentUser = false}) async {
    print('Get journalist profile request');
    return withConnectivity(() async {
      try {
        final response = await _apiService.get(
          isCurrentUser
              ? ApiRoutes.journalistMe
              : ApiRoutes.journalistProfile(id),
        );
        print('Get journalist profile response received');
        final data = response.data['data'] ?? response;
        final profileData = data as Map<String, dynamic>;
        profileData['type'] = 'journalist';
        print('Get journalist profile successful');
        return profileData;
      } catch (e) {
        print('Get journalist profile error');
        rethrow;
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getJournalistPosts(
    String id, {
    int page = 1,
    String? type,
    bool isCurrentUser = false,
  }) async {
    if (!isValidJournalistPostType(type)) {
      throw ArgumentError('Invalid post type: $type');
    }
    print('📰 getJournalistPosts called');
    return withConnectivity(() async {
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': AppConfig.defaultPageSize.toString(),
          'status': 'published',
          if (type != null) 'type': type,
        };
        final endpoint = isCurrentUser
            ? '${ApiRoutes.journalistMePosts}?${Uri(queryParameters: queryParams).query}'
            : '${ApiRoutes.journalistPosts(id)}?${Uri(queryParameters: queryParams).query}';
        final response = await _apiService.get(endpoint);
        dynamic responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          responseData = responseData['data'];
        }
        List<dynamic> posts = [];
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('posts')) {
          final postsData = responseData['posts'];
          if (postsData is List<dynamic>) {
            posts = postsData;
          }
        } else if (responseData is List<dynamic>) {
          posts = responseData;
        }
        final transformedPosts = posts.map((post) {
          final Map<String, dynamic> transformedPost =
              Map<String, dynamic>.from(post);
          if (!transformedPost.containsKey('imageUrl')) {
            transformedPost['imageUrl'] = '';
          }
          return transformedPost;
        }).toList();
        print('Get journalist posts successful');
        return List<Map<String, dynamic>>.from(transformedPosts);
      } catch (e) {
        final errorDetails = {
          'journalistId': id,
          'error': e.toString(),
          'error_type': e.runtimeType.toString(),
          'timestamp': DateTime.now().toIso8601String()
        };
        if (e is DioException) {
          errorDetails.addAll({
            'dio_error_type': e.type.toString(),
            'dio_error_message': e.message ?? 'No message',
            'request_url': e.requestOptions.uri.toString(),
            'response_status':
                e.response?.statusCode?.toString() ?? 'No status',
            'response_data': e.response?.data?.toString() ?? 'No data'
          });
        }
        print('Get journalist posts error');
        if (e is DioException && e.type == DioExceptionType.connectionError) {
          throw Exception(
              'Connection failed. Please check your internet connection and try again.');
        }
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> followJournalist(String id) async {
    print('Follow journalist attempt');
    return withConnectivity(() async {
      try {
        final response =
            await _apiService.post(ApiRoutes.journalistFollow(id), data: {});
        print('Follow journalist successful');
        return response.data['data'] ?? response;
      } catch (e) {
        print('Follow journalist error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> unfollowJournalist(String id) async {
    print('Unfollow journalist attempt');
    return withConnectivity(() async {
      try {
        final response =
            await _apiService.post(ApiRoutes.journalistUnfollow(id), data: {});
        print('Unfollow journalist successful');
        return response.data['data'] ?? response;
      } catch (e) {
        print('Unfollow journalist error');
        rethrow;
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getJournalists({
    int page = 1,
    String? specialty,
    String? search,
    bool suggested = false,
    String? politicalOrientation,
  }) async {
    print('Get journalists request');
    return withConnectivity(() async {
      try {
        final queryParams = {
          'page': page.toString(),
          'limit': AppConfig.defaultPageSize.toString(),
          if (specialty != null) 'specialty': specialty,
          if (search != null && search.isNotEmpty) 'search': search,
          if (suggested) 'suggested': 'true',
          if (politicalOrientation != null)
            'politicalOrientation': politicalOrientation,
        };
        final endpoint =
            '${ApiRoutes.journalists}?${Uri(queryParameters: queryParams).query}';
        final response = await _apiService.get(endpoint);
        final data = response.data['data'] ?? response;
        final journalists = (data['journalists'] ?? []) as List<dynamic>;
        print('Get journalists successful');
        final transformedJournalists = journalists.map((journalist) {
          final Map<String, dynamic> transformedJournalist =
              Map<String, dynamic>.from(journalist);
          transformedJournalist['isFollowing'] =
              transformedJournalist['isFollowing'] ?? false;
          transformedJournalist['followersCount'] =
              transformedJournalist['followersCount'] ?? 0;
          return transformedJournalist;
        }).toList();
        return transformedJournalists;
      } catch (e) {
        print('Get journalists error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getJournalistStats(String id,
      {String? period}) async {
    print('Get journalist stats request');
    return withConnectivity(() async {
      try {
        String endpoint = ApiRoutes.journalistStats(id);
        if (period != null) {
          endpoint += '?period=$period';
        }
        final response = await _apiService.get(endpoint);
        final data = response.data['data'] ?? response.data;
        print('Get journalist stats successful');
        return data;
      } catch (e) {
        print('Get journalist stats error');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> answerJournalistQuestion(
    String id,
    String questionId,
    String answer,
  ) async {
    print('Answer journalist question request');
    return withConnectivity(() async {
      try {
        final response = await _apiService.post(
          ApiRoutes.answerJournalistQuestionAlt(id, questionId),
          data: {'answer': answer},
        );
        print('Answer journalist question successful');
        return response.data['data'] ?? response;
      } catch (e) {
        print('Answer journalist question error');
        rethrow;
      }
    });
  }

  Future<void> respondToQuestion(
    String journalistId,
    String questionId,
    String answer,
  ) async {
    await answerJournalistQuestion(journalistId, questionId, answer);
  }

  Future<void> answerQuestion(
    String journalistId,
    String questionId,
    String answer,
  ) async {
    await answerJournalistQuestion(journalistId, questionId, answer);
  }

  @override
  Future<List<Map<String, dynamic>>> getJournalistFollowers(String id) async {
    print('Get journalist followers request');
    return withConnectivity(() async {
      try {
        final response = await _apiService
            .get(ApiRoutes.buildPath(ApiRoutes.journalistFollowers(id)));
        final data = response.data['data'] ?? response;
        final followers = (data['followers'] ?? []) as List<dynamic>;
        print('Get journalist followers successful');
        return List<Map<String, dynamic>>.from(followers);
      } catch (e) {
        print('Get journalist followers error');
        rethrow;
      }
    });
  }

  @override
  Future<bool> isFollowingJournalist(String id) async {
    print('Check following status request');
    return withConnectivity(() async {
      try {
        final response = await _apiService
            .get(ApiRoutes.buildPath(ApiRoutes.followStatus(id)));
        final data = response.data['data'] ?? response;
        final isFollowing = data['isFollowing'] ?? false;
        print('Check following status successful');
        return isFollowing;
      } catch (e) {
        print('Check following status error');
        return false;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getQuestions({
    int page = 1,
    int limit = 20,
    String? journalistId,
    String? status,
  }) async {
    return withConnectivity(() async {
      try {
        final queryParams = <String, String>{
          'page': page.toString(),
          'limit': limit.toString(),
          if (journalistId != null) 'journalistId': journalistId,
          if (status != null) 'status': status,
        };
        final uri = Uri.parse(ApiRoutes.buildPath(ApiRoutes.questions))
            .replace(queryParameters: queryParams);
        final response = await _apiService.get(uri.toString());
        print('Get questions response');
        if (response.data['questions'] != null) {
          return {
            'questions': response.data['questions'] as List,
            'currentPage': response.data['currentPage'] ?? page,
            'totalPages': response.data['totalPages'] ?? 1,
            'totalQuestions': response.data['totalQuestions'] ?? 0,
          };
        } else {
          throw Exception('Failed to load questions');
        }
      } catch (e) {
        print('Error fetching questions');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getQuestion(String questionId) async {
    return withConnectivity(() async {
      try {
        final response = await _apiService
            .get(ApiRoutes.buildPath(ApiRoutes.getQuestion(questionId)));
        if (response.data['question'] != null) {
          return response.data['question'];
        } else if (response.data != null) {
          return response.data;
        } else {
          throw Exception('Failed to load question');
        }
      } catch (e) {
        print('Error fetching question');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> createQuestion({
    required String title,
    required String content,
    required List<String> options,
    String? category,
    DateTime? expiresAt,
    bool allowMultipleVotes = false,
  }) async {
    return withConnectivity(() async {
      try {
        final data = {
          'title': title.trim(),
          'content': content.trim(),
          'options': options.map((o) => o.trim()).toList(),
          if (category != null) 'category': category,
          if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
          'allowMultipleVotes': allowMultipleVotes,
        };
        final response = await _apiService
            .post(ApiRoutes.buildPath(ApiRoutes.questions), data: data);
        if (response.data['question'] != null) {
          return response.data['question'];
        } else {
          throw Exception('Failed to create question');
        }
      } catch (e) {
        print('Error creating question');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> updateQuestion({
    required String questionId,
    String? title,
    String? content,
    List<String>? options,
    String? category,
    DateTime? expiresAt,
    bool? allowMultipleVotes,
  }) async {
    return withConnectivity(() async {
      try {
        final data = <String, dynamic>{};
        if (title != null) data['title'] = title.trim();
        if (content != null) data['content'] = content.trim();
        if (options != null) {
          data['options'] = options.map((o) => o.trim()).toList();
        }
        if (category != null) data['category'] = category;
        if (expiresAt != null) data['expiresAt'] = expiresAt.toIso8601String();
        if (allowMultipleVotes != null) {
          data['allowMultipleVotes'] = allowMultipleVotes;
        }
        final response = await _apiService.put(
          ApiRoutes.buildPath(ApiRoutes.updateQuestion(questionId)),
          data: data,
        );
        if (response.data['question'] != null) {
          return response.data['question'];
        } else {
          throw Exception('Failed to update question');
        }
      } catch (e) {
        print('Error updating question');
        rethrow;
      }
    });
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    return withConnectivity(() async {
      try {
        await _apiService
            .delete(ApiRoutes.buildPath(ApiRoutes.deleteQuestion(questionId)));
      } catch (e) {
        print('Error deleting question');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> voteOnQuestionOption({
    required String questionId,
    required String optionId,
  }) async {
    return withConnectivity(() async {
      try {
        final response = await _apiService.post(
          ApiRoutes.buildPath(ApiRoutes.voteQuestion(questionId)),
          data: {'optionId': optionId},
        );
        if (response.data['success'] == true) {
          return response.data;
        } else {
          throw Exception(response.data['message'] ?? 'Failed to vote');
        }
      } catch (e) {
        print('Error voting on question');
        rethrow;
      }
    });
  }

  @override
  Future<void> likeQuestion(String questionId) async {
    return withConnectivity(() async {
      try {
        await _apiService.post(
            ApiRoutes.buildPath(ApiRoutes.likeQuestion(questionId)),
            data: {});
      } catch (e) {
        print('Error liking question');
        rethrow;
      }
    });
  }

  @override
  Future<void> saveQuestion(String questionId) async {
    return withConnectivity(() async {
      try {
        await _apiService.post(
            ApiRoutes.buildPath(ApiRoutes.saveQuestion(questionId)),
            data: {});
      } catch (e) {
        print('Error saving question');
        rethrow;
      }
    });
  }

  @override
  Future<Map<String, dynamic>> getQuestionVoteStatus(String questionId) async {
    return withConnectivity(() async {
      try {
        final response = await _apiService
            .get(ApiRoutes.buildPath(ApiRoutes.hasVotedQuestion(questionId)));
        return {
          'hasVoted': response.data['hasVoted'] ?? false,
          'votedOption': response.data['votedOption'],
        };
      } catch (e) {
        print('Error getting vote status');
        return {
          'hasVoted': false,
          'votedOption': null,
        };
      }
    });
  }

  Map<String, dynamic> _transformShortToPost(Map<String, dynamic> shortData) {
    final Map<String, dynamic> postData = Map<String, dynamic>.from(shortData);
    postData['type'] = 'short';
    if (!postData.containsKey('domain') || postData['domain'] == null) {
      postData['domain'] = 'politique';
    }
    if (!postData.containsKey('status') || postData['status'] == null) {
      postData['status'] = 'published';
    }
    if (!postData.containsKey('content') || postData['content'] == null) {
      postData['content'] = postData['description'] ?? postData['title'] ?? '';
    }
    if (!postData.containsKey('tags') || postData['tags'] == null) {
      postData['tags'] = [];
    }
    if (!postData.containsKey('sources') || postData['sources'] == null) {
      postData['sources'] = [];
    }
    if (!postData.containsKey('politicalOrientation') ||
        postData['politicalOrientation'] == null) {
      postData['politicalOrientation'] = {
        'journalistChoice': 'neutral',
        'userVotes': {
          'extremely_conservative': 0,
          'conservative': 0,
          'neutral': 0,
          'progressive': 0,
          'extremely_progressive': 0,
        },
        'finalScore': 0.0,
        'dominantView': null,
        'hasVoted': false,
      };
    }
    if (!postData.containsKey('interactions') ||
        postData['interactions'] == null) {
      postData['interactions'] = {
        'likes': postData['likes'] ?? 0,
        'dislikes': postData['dislikes'] ?? 0,
        'comments': postData['comments'] ?? 0,
        'reports': 0,
        'bookmarks': postData['bookmarks'] ?? 0,
        'isLiked': postData['isLiked'] ?? false,
        'isBookmarked':
            postData['isSaved'] ?? postData['isBookmarked'] ?? false,
      };
    }
    if (!postData.containsKey('stats') || postData['stats'] == null) {
      postData['stats'] = {
        'views': postData['views'] ?? 0,
        'responses': postData['responses'] ?? 0,
        'shares': postData['shares'] ?? 0,
        'readTime': null,
        'completion': 0.0,
        'engagement': 0.0,
      };
    }
    if (!postData.containsKey('createdAt') || postData['createdAt'] == null) {
      postData['createdAt'] = DateTime.now().toIso8601String();
    }
    return postData;
  }

  @override
  Future<List<Post>> getShorts({
    int page = 1,
    int limit = 10,
    String? domain,
    String? politicalView,
    String? sort = '-createdAt',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort ?? '-createdAt',
      };
      if (domain != null) queryParams['domain'] = domain;
      if (politicalView != null) queryParams['politicalView'] = politicalView;
      final uri =
          Uri.parse(ApiRoutes.shorts).replace(queryParameters: queryParams);
      final response = await _apiService.get(uri.toString());
      if (response.data != null) {
        List<dynamic> shortsList = [];
        if (response.data['success'] == true && response.data['data'] != null) {
          if (response.data['data']['shorts'] != null) {
            shortsList = response.data['data']['shorts'] as List;
          } else if (response.data['data']['posts'] != null) {
            shortsList = response.data['data']['posts'] as List;
          }
        } else if (response.data['posts'] != null) {
          shortsList = response.data['posts'] as List;
        }
        if (shortsList.isEmpty) {
          return [];
        }
        return shortsList
            .map((shortData) => Post.fromJson(_transformShortToPost(shortData)))
            .toList();
      } else {
        throw Exception('Failed to load shorts');
      }
    } catch (e) {
      _logger.error('Error fetching shorts: $e');
      rethrow;
    }
  }

  @override
  Future<Post> getShort(String shortId) async {
    try {
      final response = await _apiService.get(ApiRoutes.getShort(shortId));
      if (response.data['short'] != null) {
        return Post.fromJson(_transformShortToPost(response.data['short']));
      } else {
        throw Exception('Failed to load short');
      }
    } catch (e) {
      _logger.error('Error fetching short: $e');
      rethrow;
    }
  }

  @override
  Future<Post> createShort({
    required String title,
    required String content,
    required String domain,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    Map<String, dynamic>? politicalOrientation,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'content': content,
        'domain': domain,
        'type': 'short',
      };
      if (videoUrl != null) body['videoUrl'] = videoUrl;
      if (thumbnailUrl != null) body['thumbnailUrl'] = thumbnailUrl;
      if (tags != null) body['tags'] = tags;
      if (politicalOrientation != null) {
        body['politicalOrientation'] = politicalOrientation;
      }
      final response = await _apiService.post(ApiRoutes.shorts, data: body);
      if (response.data['short'] != null) {
        return Post.fromJson(_transformShortToPost(response.data['short']));
      } else {
        throw Exception('Failed to create short');
      }
    } catch (e) {
      _logger.error('Error creating short: $e');
      rethrow;
    }
  }

  @override
  Future<Post> updateShort({
    required String shortId,
    String? title,
    String? content,
    String? domain,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    Map<String, dynamic>? politicalOrientation,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (content != null) body['content'] = content;
      if (domain != null) body['domain'] = domain;
      if (videoUrl != null) body['videoUrl'] = videoUrl;
      if (thumbnailUrl != null) body['thumbnailUrl'] = thumbnailUrl;
      if (tags != null) body['tags'] = tags;
      if (politicalOrientation != null) {
        body['politicalOrientation'] = politicalOrientation;
      }
      final response =
          await _apiService.put(ApiRoutes.updateShort(shortId), data: body);
      if (response.data['short'] != null) {
        return Post.fromJson(_transformShortToPost(response.data['short']));
      } else {
        throw Exception('Failed to update short');
      }
    } catch (e) {
      _logger.error('Error updating short: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteShort(String shortId) async {
    try {
      await _apiService.delete(ApiRoutes.deleteShort(shortId));
    } catch (e) {
      _logger.error('Error deleting short: $e');
      rethrow;
    }
  }

  @override
  Future<void> likeShort(String shortId) async {
    try {
      await _apiService.post(ApiRoutes.likeShort(shortId), data: {});
    } catch (e) {
      _logger.error('Error liking short: $e');
      rethrow;
    }
  }

  @override
  Future<void> dislikeShort(String shortId) async {
    try {
      await _apiService.post(ApiRoutes.dislikeShort(shortId), data: {});
    } catch (e) {
      _logger.error('Error disliking short: $e');
      rethrow;
    }
  }

  @override
  Future<List<Post>> getTrendingShorts({
    int page = 1,
    int limit = 10,
    String? domain,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': 'trending',
      };
      if (domain != null) queryParams['domain'] = domain;
      final uri =
          Uri.parse(ApiRoutes.shorts).replace(queryParameters: queryParams);
      final response = await _apiService.get(uri.toString());
      if (response.data != null &&
          response.data['success'] == true &&
          response.data['data'] != null &&
          response.data['data']['shorts'] != null) {
        return (response.data['data']['shorts'] as List)
            .map((shortData) => Post.fromJson(_transformShortToPost(shortData)))
            .toList();
      } else {
        throw Exception('Failed to load trending shorts');
      }
    } catch (e) {
      _logger.error('Error fetching trending shorts: $e');
      rethrow;
    }
  }

  @override
  Future<Post> saveShort(String shortId) async {
    try {
      final response =
          await _apiService.post(ApiRoutes.saveShort(shortId), data: {});
      if (response.data != null && response.data['success'] == true) {
        return getShort(shortId);
      } else {
        throw Exception('Failed to save short');
      }
    } catch (e) {
      _logger.error('Error saving short: $e');
      rethrow;
    }
  }

  @override
  Future<List<Post>> getSavedShorts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'saved': 'true',
      };
      final uri =
          Uri.parse(ApiRoutes.shorts).replace(queryParameters: queryParams);
      final response = await _apiService.get(uri.toString());
      if (response.data['shorts'] != null) {
        return (response.data['shorts'] as List)
            .map((shortData) => Post.fromJson(_transformShortToPost(shortData)))
            .toList();
      } else {
        throw Exception('Failed to load saved shorts');
      }
    } catch (e) {
      _logger.error('Error fetching saved shorts: $e');
      rethrow;
    }
  }

  @override
  Future<List<TrendingHashtag>> getTrendingHashtags({
    int limit = 10,
    String? timeframe,
    bool preferCache = false,
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    return withConnectivity(() async {
      final reqId = _newReqId();
      final sanitizedLimit = _sanitizeLimit(limit);
      final queryParams = <String, String>{
        'limit': sanitizedLimit.toString(),
        if (timeframe != null) 'timeframe': timeframe,
      };
      final uri = _buildUri(ApiRoutes.trendingHashtags, queryParams);
      final cacheKey = 'hashtags:${uri.toString()}';
      final ttl = const Duration(minutes: 3);
      final to = timeout ?? const Duration(seconds: 10);
      if (!forceRefresh && preferCache) {
        final cached = _cache.get(cacheKey);
        if (cached is List<TrendingHashtag>) {
          _log('[$reqId] cache-hit getTrendingHashtags', ctx: {
            'limit': sanitizedLimit,
            'timeframe': timeframe ?? 'default',
            'count': cached.length
          });
          return cached;
        }
      }
      final sw = Stopwatch()..start();
      try {
        return _inFlight.run<List<TrendingHashtag>>(cacheKey, () async {
          final response = await _withRetry(
            () => _apiService.get(uri.toString()).timeout(to),
          );
          final hashtags = ApiResponseHelper.extractList<TrendingHashtag>(
            response.data,
            (json) => TrendingHashtag.fromJson(json),
          );
          _cache.put(cacheKey, hashtags, ttl);
          _log('[$reqId] getTrendingHashtags ok (${sw.elapsedMilliseconds} ms)',
              ctx: {
                'limit': sanitizedLimit,
                'timeframe': timeframe ?? 'default',
                'count': hashtags.length
              });
          return hashtags;
        });
      } catch (e, _) {
        _log('[$reqId] getTrendingHashtags error', level: 1000, ctx: {
          'limit': sanitizedLimit,
          'timeframe': timeframe ?? 'default',
          'error': e.toString()
        });
        print('stack');
        rethrow;
      }
    });
  }

  @override
  Future<List<TrendingTopic>> getTrendingTopics({
    int limit = 10,
    String? category,
    String? timeframe,
    bool preferCache = false,
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    return withConnectivity(() async {
      final reqId = _newReqId();
      final sanitizedLimit = _sanitizeLimit(limit);
      final queryParams = <String, String>{
        'limit': sanitizedLimit.toString(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (timeframe != null) 'timeframe': timeframe,
      };
      final uri = _buildUri(ApiRoutes.trendingTopics, queryParams);
      final cacheKey = 'topics:${uri.toString()}';
      final ttl = const Duration(minutes: 3);
      final to = timeout ?? const Duration(seconds: 10);
      if (!forceRefresh && preferCache) {
        final cached = _cache.get(cacheKey);
        if (cached is List<TrendingTopic>) {
          _log('[$reqId] cache-hit getTrendingTopics', ctx: {
            'limit': sanitizedLimit,
            'category': category ?? 'all',
            'timeframe': timeframe ?? 'default',
            'count': cached.length
          });
          return cached;
        }
      }
      final sw = Stopwatch()..start();
      try {
        return _inFlight.run<List<TrendingTopic>>(cacheKey, () async {
          final response = await _withRetry(
            () => _apiService.get(uri.toString()).timeout(to),
          );
          final topics = ApiResponseHelper.extractList<TrendingTopic>(
            response.data,
            (json) => TrendingTopic.fromJson(json),
          );
          _cache.put(cacheKey, topics, ttl);
          _log('[$reqId] getTrendingTopics ok (${sw.elapsedMilliseconds} ms)',
              ctx: {
                'limit': sanitizedLimit,
                'category': category ?? 'all',
                'timeframe': timeframe ?? 'default',
                'count': topics.length
              });
          return topics;
        });
      } catch (e, _) {
        _log('[$reqId] getTrendingTopics error', level: 1000, ctx: {
          'limit': sanitizedLimit,
          'category': category ?? 'all',
          'timeframe': timeframe ?? 'default',
          'error': e.toString()
        });
        print('stack');
        rethrow;
      }
    });
  }

  @override
  Future<PersonalizedTrending> getPersonalizedTrending({
    int postsLimit = 10,
    int journalistsLimit = 5,
    int hashtagsLimit = 10,
    bool preferCache = false,
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    return withConnectivity(() async {
      final reqId = _newReqId();
      final qPosts = _sanitizeLimit(postsLimit);
      final qJourno = _sanitizeLimit(journalistsLimit);
      final qTags = _sanitizeLimit(hashtagsLimit);
      final queryParams = <String, String>{
        'postsLimit': qPosts.toString(),
        'journalistsLimit': qJourno.toString(),
        'hashtagsLimit': qTags.toString(),
      };
      final uri = _buildUri(ApiRoutes.trendingPersonalized, queryParams);
      final cacheKey = 'personalized:${uri.toString()}';
      final ttl = const Duration(minutes: 1);
      final to = timeout ?? const Duration(seconds: 10);
      if (!forceRefresh && preferCache) {
        final cached = _cache.get(cacheKey);
        if (cached is PersonalizedTrending) {
          _log('[$reqId] cache-hit getPersonalizedTrending', ctx: {
            'postsLimit': qPosts,
            'journalistsLimit': qJourno,
            'hashtagsLimit': qTags
          });
          return cached;
        }
      }
      final sw = Stopwatch()..start();
      try {
        return _inFlight.run<PersonalizedTrending>(cacheKey, () async {
          final response = await _withRetry(
            () => _apiService.get(uri.toString()).timeout(to),
          );
          final data = ApiResponseHelper.extractData<Map<String, dynamic>>(
              response.data);
          final result = PersonalizedTrending.fromJson(data ?? {});
          _cache.put(cacheKey, result, ttl);
          _log(
              '[$reqId] getPersonalizedTrending ok (${sw.elapsedMilliseconds} ms)',
              ctx: {
                'postsLimit': qPosts,
                'journalistsLimit': qJourno,
                'hashtagsLimit': qTags,
                'posts': result.posts.length,
                'journalists': result.journalists.length,
                'hashtags': result.hashtags.length,
                'topics': result.topics.length,
              });
          return result;
        });
      } catch (e, _) {
        _log('[$reqId] getPersonalizedTrending error', level: 1000, ctx: {
          'postsLimit': qPosts,
          'journalistsLimit': qJourno,
          'hashtagsLimit': qTags,
          'error': e.toString()
        });
        print('stack');
        rethrow;
      }
    });
  }

  @override
  Future<TrendingSearchResults> searchTrending({
    required String query,
    String? type,
    int limit = 20,
    bool preferCache = false,
    bool forceRefresh = false,
    bool debounce = false,
    Duration debounceDuration = const Duration(milliseconds: 350),
    Duration? timeout,
  }) async {
    return withConnectivity(() async {
      final reqId = _newReqId();
      final sanitizedLimit = _sanitizeLimit(limit);
      final trimmedQuery = query.trim();
      if (debounce) {
        await Future.delayed(debounceDuration);
      }
      final queryParams = <String, String>{
        'q': trimmedQuery,
        'limit': sanitizedLimit.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
      };
      final uri = _buildUri(ApiRoutes.trendingSearch, queryParams);
      final cacheKey = 'search:${uri.toString()}';
      final ttl = const Duration(seconds: 20);
      final to = timeout ?? const Duration(seconds: 10);
      if (!forceRefresh && preferCache) {
        final cached = _cache.get(cacheKey);
        if (cached is TrendingSearchResults) {
          _log('[$reqId] cache-hit searchTrending', ctx: {
            'q': trimmedQuery,
            'type': type ?? 'all',
            'results': cached.totalResults
          });
          return cached;
        }
      }
      final sw = Stopwatch()..start();
      try {
        return _inFlight.run<TrendingSearchResults>(cacheKey, () async {
          final response = await _withRetry(
            () => _apiService.get(uri.toString()).timeout(to),
          );
          final data = ApiResponseHelper.extractData<Map<String, dynamic>>(
              response.data);
          final result = TrendingSearchResults.fromJson(data ?? {});
          _cache.put(cacheKey, result, ttl);
          _log('[$reqId] searchTrending ok (${sw.elapsedMilliseconds} ms)',
              ctx: {
                'q': trimmedQuery,
                'type': type ?? 'all',
                'totalResults': result.totalResults,
                'hashtags': result.hashtags.length,
                'topics': result.topics.length,
                'posts': result.posts.length,
                'journalists': result.journalists.length,
              });
          return result;
        });
      } catch (e, _) {
        _log('[$reqId] searchTrending error', level: 1000, ctx: {
          'q': trimmedQuery,
          'type': type ?? 'all',
          'error': e.toString()
        });
        print('stack');
        rethrow;
      }
    });
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;
  const _CacheEntry(this.value, this.expiry);
  bool get isExpired => DateTime.now().isAfter(expiry);
}

class _LruCache<K, V> {
  final int capacity;
  final _map = <K, _CacheEntry<V>>{};
  _LruCache({this.capacity = 50}) : assert(capacity > 0);
  V? get(K key) {
    final entry = _map.remove(key);
    if (entry == null) return null;
    if (entry.isExpired) return null;
    _map[key] = entry;
    return entry.value;
  }

  void put(K key, V value, Duration ttl) {
    if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  void invalidate(K key) => _map.remove(key);
  void clear() => _map.clear();
}

class _InFlight {
  final _map = <String, Future<Object>>{};
  Future<T> run<T>(String key, Future<T> Function() action) {
    if (_map.containsKey(key)) {
      return _map[key]! as Future<T>;
    }
    final future = action();
    _map[key] = future.then<Object>((v) => v as Object).whenComplete(() {
      _map.remove(key);
    });
    return future;
  }
}

String _newReqId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(1 << 32)}';
int _sanitizeLimit(int limit) => limit.clamp(1, 100);
Uri _buildUri(String route, Map<String, String> queryParams) {
  return Uri.parse(ApiRoutes.buildPath(route))
      .replace(queryParameters: queryParams);
}

void _log(String message,
    {int level = 800,
    String name = 'PostRepository',
    Map<String, Object?>? ctx}) {
  final suffix = (ctx == null || ctx.isEmpty) ? '' : ' | ctx=$ctx';
  print('$message$suffix');
}

Future<T> _withRetry<T>(
  Future<T> Function() run, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 250),
  Duration maxDelay = const Duration(seconds: 2),
}) async {
  assert(maxAttempts >= 1);
  int attempt = 0;
  Object? lastError;
  final rand = math.Random();
  while (attempt < maxAttempts) {
    attempt++;
    try {
      return await run();
    } catch (e) {
      lastError = e;
      if (attempt >= maxAttempts) break;
      final delayMs = math.min(
        maxDelay.inMilliseconds,
        baseDelay.inMilliseconds * (1 << (attempt - 1)),
      );
      final jitter = rand.nextInt((delayMs * 0.25).toInt() + 1);
      await Future.delayed(Duration(milliseconds: delayMs + jitter));
    }
  }
  throw lastError ?? StateError('Unknown error in _withRetry');
}

@immutable
class TrendingHashtag {
  final String tag;
  final int count;
  final double trendScore;
  final String? description;
  final DateTime? lastUsed;
  final Map<String, dynamic>? metadata;
  const TrendingHashtag({
    required this.tag,
    required this.count,
    required this.trendScore,
    this.description,
    this.lastUsed,
    this.metadata,
  });
  static double _asDouble(Object? v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      tag: (json['tag'] as String?) ?? '',
      count: (json['count'] is String)
          ? int.tryParse(json['count'] as String) ?? 0
          : (json['count'] as int?) ?? 0,
      trendScore: _asDouble(json['trendScore']),
      description: json['description'] as String?,
      lastUsed: _parseDate(json['lastUsed']),
      metadata: (json['metadata'] is Map<String, dynamic>)
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'count': count,
      'trendScore': trendScore,
      'description': description,
      'lastUsed': lastUsed?.toIso8601String(),
      'metadata': metadata,
    };
  }

  TrendingHashtag copyWith({
    String? tag,
    int? count,
    double? trendScore,
    String? description,
    DateTime? lastUsed,
    Map<String, dynamic>? metadata,
  }) {
    return TrendingHashtag(
      tag: tag ?? this.tag,
      count: count ?? this.count,
      trendScore: trendScore ?? this.trendScore,
      description: description ?? this.description,
      lastUsed: lastUsed ?? this.lastUsed,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'TrendingHashtag(tag: $tag, count: $count, trendScore: $trendScore)';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendingHashtag &&
          runtimeType == other.runtimeType &&
          tag == other.tag &&
          count == other.count &&
          trendScore == other.trendScore &&
          description == other.description &&
          lastUsed == other.lastUsed;
  @override
  int get hashCode =>
      Object.hash(tag, count, trendScore, description, lastUsed);
}

@immutable
class TrendingTopic {
  final String id;
  final String name;
  final String category;
  final int postsCount;
  final double trendScore;
  final String? imageUrl;
  final String? description;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;
  const TrendingTopic({
    required this.id,
    required this.name,
    required this.category,
    required this.postsCount,
    required this.trendScore,
    this.imageUrl,
    this.description,
    this.createdAt,
    this.metadata,
  });
  static double _asDouble(Object? v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory TrendingTopic.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    return TrendingTopic(
      id: (rawId is String) ? rawId : (rawId?.toString() ?? ''),
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      postsCount: (json['postsCount'] is String)
          ? int.tryParse(json['postsCount'] as String) ?? 0
          : (json['postsCount'] as int?) ?? 0,
      trendScore: _asDouble(json['trendScore']),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      createdAt: _parseDate(json['createdAt']),
      metadata: (json['metadata'] is Map<String, dynamic>)
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'postsCount': postsCount,
      'trendScore': trendScore,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  TrendingTopic copyWith({
    String? id,
    String? name,
    String? category,
    int? postsCount,
    double? trendScore,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return TrendingTopic(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      postsCount: postsCount ?? this.postsCount,
      trendScore: trendScore ?? this.trendScore,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'TrendingTopic(id: $id, name: $name, category: $category, postsCount: $postsCount, trendScore: $trendScore)';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendingTopic &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          postsCount == other.postsCount &&
          trendScore == other.trendScore &&
          imageUrl == other.imageUrl &&
          description == other.description &&
          createdAt == other.createdAt;
  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        postsCount,
        trendScore,
        imageUrl,
        description,
        createdAt,
      );
}

@immutable
class PersonalizedTrending {
  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> journalists;
  final List<TrendingHashtag> hashtags;
  final List<TrendingTopic> topics;
  final DateTime generatedAt;
  const PersonalizedTrending({
    required this.posts,
    required this.journalists,
    required this.hashtags,
    required this.topics,
    required this.generatedAt,
  });
  static DateTime _parseGeneratedAt(Object? v) {
    if (v is DateTime) return v;
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt;
    }
    return DateTime.now();
  }

  factory PersonalizedTrending.fromJson(Map<String, dynamic> json) {
    return PersonalizedTrending(
      posts: (json['posts'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          const [],
      journalists: (json['journalists'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          const [],
      hashtags: (json['hashtags'] as List?)
              ?.map((e) =>
                  TrendingHashtag.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      topics: (json['topics'] as List?)
              ?.map((e) =>
                  TrendingTopic.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      generatedAt: _parseGeneratedAt(json['generatedAt']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'posts': posts,
      'journalists': journalists,
      'hashtags': hashtags.map((h) => h.toJson()).toList(),
      'topics': topics.map((t) => t.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  PersonalizedTrending copyWith({
    List<Map<String, dynamic>>? posts,
    List<Map<String, dynamic>>? journalists,
    List<TrendingHashtag>? hashtags,
    List<TrendingTopic>? topics,
    DateTime? generatedAt,
  }) {
    return PersonalizedTrending(
      posts: posts ?? this.posts,
      journalists: journalists ?? this.journalists,
      hashtags: hashtags ?? this.hashtags,
      topics: topics ?? this.topics,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  String toString() =>
      'PersonalizedTrending(posts: ${posts.length}, journalists: ${journalists.length}, hashtags: ${hashtags.length}, topics: ${topics.length})';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedTrending &&
          runtimeType == other.runtimeType &&
          posts == other.posts &&
          journalists == other.journalists &&
          hashtags == other.hashtags &&
          topics == other.topics &&
          generatedAt == other.generatedAt;
  @override
  int get hashCode =>
      Object.hash(posts, journalists, hashtags, topics, generatedAt);
}

@immutable
class TrendingSearchResults {
  final List<TrendingHashtag> hashtags;
  final List<TrendingTopic> topics;
  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> journalists;
  final int totalResults;
  const TrendingSearchResults({
    required this.hashtags,
    required this.topics,
    required this.posts,
    required this.journalists,
    required this.totalResults,
  });
  factory TrendingSearchResults.fromJson(Map<String, dynamic> json) {
    return TrendingSearchResults(
      hashtags: (json['hashtags'] as List?)
              ?.map((e) =>
                  TrendingHashtag.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      topics: (json['topics'] as List?)
              ?.map((e) =>
                  TrendingTopic.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const [],
      posts: (json['posts'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          const [],
      journalists: (json['journalists'] as List?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          const [],
      totalResults: (json['totalResults'] is String)
          ? int.tryParse(json['totalResults'] as String) ?? 0
          : (json['totalResults'] as int?) ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'hashtags': hashtags.map((h) => h.toJson()).toList(),
      'topics': topics.map((t) => t.toJson()).toList(),
      'posts': posts,
      'journalists': journalists,
      'totalResults': totalResults,
    };
  }

  TrendingSearchResults copyWith({
    List<TrendingHashtag>? hashtags,
    List<TrendingTopic>? topics,
    List<Map<String, dynamic>>? posts,
    List<Map<String, dynamic>>? journalists,
    int? totalResults,
  }) {
    return TrendingSearchResults(
      hashtags: hashtags ?? this.hashtags,
      topics: topics ?? this.topics,
      posts: posts ?? this.posts,
      journalists: journalists ?? this.journalists,
      totalResults: totalResults ?? this.totalResults,
    );
  }

  @override
  String toString() =>
      'TrendingSearchResults(total: $totalResults, hashtags: ${hashtags.length}, topics: ${topics.length}, posts: ${posts.length}, journalists: ${journalists.length})';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendingSearchResults &&
          runtimeType == other.runtimeType &&
          hashtags == other.hashtags &&
          topics == other.topics &&
          posts == other.posts &&
          journalists == other.journalists &&
          totalResults == other.totalResults;
  @override
  int get hashCode => Object.hash(
        hashtags,
        topics,
        posts,
        journalists,
        totalResults,
      );
}
