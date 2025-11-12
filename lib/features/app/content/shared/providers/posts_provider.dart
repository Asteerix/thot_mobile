import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thot/features/app/content/shared/models/post.dart';

class PostsState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });
  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  PostsNotifier() : super(PostsState());
  void setPosts(List<Post> posts) {
    state = state.copyWith(posts: posts);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void addPost(Post post) {
    state = state.copyWith(posts: [...state.posts, post]);
  }

  void updatePost(Post post) {
    final posts = state.posts.map((p) => p.id == post.id ? post : p).toList();
    state = state.copyWith(posts: posts);
  }

  void deletePost(String postId) {
    final posts = state.posts.where((p) => p.id != postId).toList();
    state = state.copyWith(posts: posts);
  }
}

final postsStateProvider =
    StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  return PostsNotifier();
});

class PostRepository {}
