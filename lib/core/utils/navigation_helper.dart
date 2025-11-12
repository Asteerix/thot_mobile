import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thot/features/app/content/shared/models/post.dart';
import 'package:thot/core/routing/route_names.dart';

/// Helper pour naviguer vers le bon écran de détail selon le type de post
class NavigationHelper {
  static void navigateToPostDetail(
    BuildContext context,
    String postId, {
    PostType? postType,
    Map<String, dynamic>? extraParams,
  }) {
    final extra = extraParams ?? {};
    extra['postId'] = postId;

    if (postType == PostType.question) {
      extra['questionId'] = postId;
      context.push(RouteNames.questionDetail, extra: extra);
    } else if (postType == PostType.video) {
      context.push(RouteNames.videoDetail, extra: extra);
    } else if (postType == PostType.podcast) {
      context.push(RouteNames.podcastDetail, extra: extra);
    } else {
      context.push(RouteNames.articleDetail, extra: extra);
    }
  }

  static void navigateToPost(
    BuildContext context,
    Post post, {
    Map<String, dynamic>? extraParams,
  }) {
    if (post.id.isEmpty || post.id.startsWith('invalid_post_id_')) return;

    navigateToPostDetail(
      context,
      post.id,
      postType: post.type,
      extraParams: extraParams,
    );
  }
}
