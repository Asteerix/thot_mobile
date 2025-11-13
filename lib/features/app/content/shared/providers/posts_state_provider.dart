import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/features/app/content/shared/providers/post_repository_impl.dart';
import 'package:thot/core/di/service_locator.dart';
import 'package:thot/core/services/realtime/event_bus.dart';

class PostsStateProvider extends ChangeNotifier {
  PostRepositoryImpl get _postRepository =>
      ServiceLocator.instance.postRepository;
  final EventBus _eventBus = EventBus();
  StreamSubscription<SocketPostEvent>? _socketEventSubscription;
  final Map<String, Post> _postsCache = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String> _errors = {};
  PostsStateProvider() {
    _initializeSocketListeners();
  }
  void _initializeSocketListeners() {
    print('🔌 [POSTS_STATE_PROVIDER] Initializing Socket.IO listeners');
    _socketEventSubscription = _eventBus.on<SocketPostEvent>().listen((event) {
      print(
          '📡 [POSTS_STATE_PROVIDER] Received socket event | type: ${event.type}, data: ${event.data}');
      if (event.type == 'liked') {
        _handleSocketLikeEvent(event.data);
      } else if (event.type == 'updated') {
        _handleSocketPostUpdatedEvent(event.data);
      }
    });
  }

  void _handleSocketLikeEvent(Map<String, dynamic> data) {
    try {
      final postId = data['postId'] as String?;
      final userId = data['userId'] as String?;
      final isLiked = data['isLiked'] as bool?;
      final likeCount = data['likeCount'] as int?;
      print(
          '❤️ [POSTS_STATE_PROVIDER] Processing socket like event | postId: $postId, userId: $userId, isLiked: $isLiked, likeCount: $likeCount');
      if (postId == null || likeCount == null) {
        print('⚠️ [POSTS_STATE_PROVIDER] Invalid like event data');
        return;
      }
      final post = _postsCache[postId];
      if (post == null) {
        print(
            '⚠️ [POSTS_STATE_PROVIDER] Post not found in cache | postId: $postId');
        return;
      }
      final updatedPost = post.copyWith(
        interactions: post.interactions.copyWith(
          likes: likeCount,
        ),
      );
      _postsCache[postId] = updatedPost;
      notifyListeners();
      print(
          '✅ [POSTS_STATE_PROVIDER] Post like count updated from socket | postId: $postId, likeCount: $likeCount');
    } catch (e, stackTrace) {
      print(
          '❌ [POSTS_STATE_PROVIDER] Error handling socket like event | error: $e, stackTrace: $stackTrace');
    }
  }

  void _handleSocketPostUpdatedEvent(Map<String, dynamic> data) {
    try {
      final postId = data['postId'] as String?;
      print(
          '🔄 [POSTS_STATE_PROVIDER] Processing socket post updated event | postId: $postId');
      if (postId == null) {
        print('⚠️ [POSTS_STATE_PROVIDER] Invalid post updated event data');
        return;
      }
      print(
          'ℹ️ [POSTS_STATE_PROVIDER] Post updated event received, ignoring for now');
    } catch (e, stackTrace) {
      print(
          '❌ [POSTS_STATE_PROVIDER] Error handling socket post updated event | error: $e, stackTrace: $stackTrace');
    }
  }

  Post? getPost(String postId) => _postsCache[postId];
  bool isLoading(String postId) => _loadingStates[postId] ?? false;
  String? getError(String postId) => _errors[postId];
  void updatePost(Post post, {bool notify = true}) {
    _postsCache[post.id] = post;
    _errors.remove(post.id);
    if (notify) {
      notifyListeners();
    }
  }

  void updatePostSilently(Post post) {
    updatePost(post, notify: false);
  }

  void updatePosts(List<Post> posts) {
    for (final post in posts) {
      _postsCache[post.id] = post;
      _errors.remove(post.id);
    }
    notifyListeners();
  }

  Future<Post?> loadPost(String postId) async {
    if (_postsCache.containsKey(postId) && !_errors.containsKey(postId)) {
      return _postsCache[postId];
    }
    if (_loadingStates[postId] == true) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _postsCache[postId];
    }
    _loadingStates[postId] = true;
    _errors.remove(postId);
    notifyListeners();
    try {
      final postData = await _postRepository.getPost(postId);
      final post = Post.fromJson(postData);
      _postsCache[postId] = post;
      _loadingStates[postId] = false;
      notifyListeners();
      return post;
    } catch (e) {
      print('Error loading post');
      _errors[postId] = e.toString();
      _loadingStates[postId] = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleLike(String postId) async {
    final post = _postsCache[postId];
    if (post == null) {
      print(
          '⚠️ [POSTS_STATE_PROVIDER] toggleLike called but post not in cache | postId: $postId');
      return;
    }
    final originalPost = post;
    final wasLiked = post.interactions.isLiked;
    final originalLikesCount = post.interactions.likes;
    print(
        '🎯 [POSTS_STATE_PROVIDER] toggleLike START | postId: $postId, currentIsLiked: $wasLiked, currentLikes: $originalLikesCount');
    final optimisticPost = post.copyWith(
      interactions: post.interactions.copyWith(
        isLiked: !wasLiked,
        likes: wasLiked ? originalLikesCount - 1 : originalLikesCount + 1,
      ),
    );
    _postsCache[postId] = optimisticPost;
    _errors.remove(postId);
    notifyListeners();
    print(
        '✅ [POSTS_STATE_PROVIDER] Optimistic update applied | postId: $postId, newIsLiked: ${!wasLiked}, newLikes: ${wasLiked ? originalLikesCount - 1 : originalLikesCount + 1}');
    try {
      print('📡 [POSTS_STATE_PROVIDER] Calling API likePost | postId: $postId');
      final responseData = await _postRepository.likePost(postId);
      final updatedPost = Post.fromJson(responseData);
      print(
          '📥 [POSTS_STATE_PROVIDER] API response received | postId: $postId, responseIsLiked: ${updatedPost.interactions.isLiked}, responseLikes: ${updatedPost.interactions.likes}');
      _postsCache[postId] = updatedPost;
      _errors.remove(postId);
      notifyListeners();
      print(
          '✅ [POSTS_STATE_PROVIDER] Like toggled successfully | postId: $postId, finalIsLiked: ${updatedPost.interactions.isLiked}, finalLikes: ${updatedPost.interactions.likes}');
    } catch (e) {
      print(
          '❌ [POSTS_STATE_PROVIDER] Error toggling like, rolling back | postId: $postId, error: $e');
      _postsCache[postId] = originalPost;
      _errors[postId] = e.toString();
      notifyListeners();
      print(
          '🔄 [POSTS_STATE_PROVIDER] Rollback complete | postId: $postId, isLiked: $wasLiked, likes: $originalLikesCount');
      rethrow;
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final post = _postsCache[postId];
    if (post == null) return;
    final originalPost = post;
    final wasSaved = post.interactions.isSaved;
    final originalBookmarksCount = post.interactions.bookmarks;
    print(
        '🔖 [POSTS_STATE_PROVIDER] toggleBookmark START | postId: $postId, currentIsSaved: $wasSaved, currentBookmarks: $originalBookmarksCount');
    final optimisticPost = post.copyWith(
      interactions: post.interactions.copyWith(
        isSaved: !wasSaved,
        bookmarks:
            wasSaved ? originalBookmarksCount - 1 : originalBookmarksCount + 1,
      ),
    );
    _postsCache[postId] = optimisticPost;
    _errors.remove(postId);
    notifyListeners();
    print(
        '✅ [POSTS_STATE_PROVIDER] Optimistic update applied | postId: $postId, newIsSaved: ${!wasSaved}, newBookmarks: ${wasSaved ? originalBookmarksCount - 1 : originalBookmarksCount + 1}');
    try {
      print('📡 [POSTS_STATE_PROVIDER] Calling API savePost | postId: $postId');
      final responseData = await _postRepository.savePost(postId);
      final updatedPost = Post.fromJson(responseData);
      print(
          '📥 [POSTS_STATE_PROVIDER] API response received | postId: $postId, responseIsSaved: ${updatedPost.interactions.isSaved}, responseBookmarks: ${updatedPost.interactions.bookmarks}');
      _postsCache[postId] = updatedPost;
      _errors.remove(postId);
      notifyListeners();
      print(
          '✅ [POSTS_STATE_PROVIDER] Bookmark toggled successfully | postId: $postId, finalIsSaved: ${updatedPost.interactions.isSaved}, finalBookmarks: ${updatedPost.interactions.bookmarks}');
    } catch (e) {
      print(
          '❌ [POSTS_STATE_PROVIDER] Error toggling bookmark, rolling back | postId: $postId, error: $e');
      _postsCache[postId] = originalPost;
      _errors.remove(postId);
      notifyListeners();
      print(
          '🔄 [POSTS_STATE_PROVIDER] Rollback complete | postId: $postId, isSaved: $wasSaved, bookmarks: $originalBookmarksCount');
      rethrow;
    }
  }

  Future<void> votePoliticalOrientation(
      String postId, String orientation) async {
    final post = _postsCache[postId];
    if (post == null) return;
    final originalPost = post;
    final originalOrientation = Map<String, int>.from(
      post.politicalOrientation.userVotes,
    );
    final newOrientation = Map<String, int>.from(originalOrientation);
    newOrientation[orientation] = (newOrientation[orientation] ?? 0) + 1;
    final optimisticPost = post.copyWith(
      politicalOrientation: post.politicalOrientation.copyWith(
        userVotes: newOrientation,
        hasVoted: true,
      ),
    );
    updatePost(optimisticPost);
    try {
      final responseData = await _postRepository.votePoliticalOrientation(
        postId,
        orientation,
      );
      final updatedPost = Post.fromJson(responseData);
      updatePost(updatedPost);
      print('Political vote successful');
    } catch (e) {
      updatePost(originalPost);
      print('Error voting political orientation');
      rethrow;
    }
  }

  void updateCommentCount(String postId, int newCount) {
    final post = _postsCache[postId];
    if (post == null) return;
    final updatedPost = post.copyWith(
      interactions: post.interactions.copyWith(
        comments: newCount,
      ),
    );
    updatePost(updatedPost);
    print('Comment count updated');
  }

  void incrementCommentCount(String postId) {
    final post = _postsCache[postId];
    if (post != null) {
      updateCommentCount(postId, post.interactions.comments + 1);
    }
  }

  void decrementCommentCount(String postId) {
    final post = _postsCache[postId];
    if (post != null) {
      updateCommentCount(postId, math.max(0, post.interactions.comments - 1));
    }
  }

  Future<void> refreshPost(String postId) async {
    _errors.remove(postId);
    await loadPost(postId);
  }

  void clearCache() {
    _postsCache.clear();
    _loadingStates.clear();
    _errors.clear();
    notifyListeners();
  }

  void removePost(String postId) {
    _postsCache.remove(postId);
    _loadingStates.remove(postId);
    _errors.remove(postId);
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    try {
      print('🗑️ [POSTS_STATE_PROVIDER] Deleting post | postId: $postId');
      await _postRepository.deletePost(postId);
      removePost(postId);
      print('✅ [POSTS_STATE_PROVIDER] Post deleted successfully | postId: $postId');
    } catch (e) {
      print('❌ [POSTS_STATE_PROVIDER] Error deleting post | postId: $postId, error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('🔌 [POSTS_STATE_PROVIDER] Disposing Socket.IO listeners');
    _socketEventSubscription?.cancel();
    super.dispose();
  }
}
