import 'package:thot/features/posts/domain/entities/post.dart';
class PostDto {
  final String id;
  final String title;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String type;
  final String domain;
  final String status;
  final Map<String, dynamic> politicalOrientation;
  final Map<String, dynamic>? journalist;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> interactions;
  final String createdAt;
  final String content;
  final Map<String, dynamic>? metadata;
  final List<String> tags;
  final List<String> sources;
  final List<Map<String, dynamic>>? relatedPosts;
  final List<Map<String, dynamic>>? opposingPosts;
  final List<Map<String, dynamic>>? opposedByPosts;
  const PostDto({
    required this.id,
    required this.title,
    this.imageUrl,
    this.thumbnailUrl,
    this.videoUrl,
    required this.type,
    required this.domain,
    required this.status,
    required this.politicalOrientation,
    this.journalist,
    required this.stats,
    required this.interactions,
    required this.createdAt,
    required this.content,
    this.metadata,
    required this.tags,
    required this.sources,
    this.relatedPosts,
    this.opposingPosts,
    this.opposedByPosts,
  });
  factory PostDto.fromJson(Map<String, dynamic> json) {
    return PostDto(
      id: json['id'] as String? ?? json['_id'] as String,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      type: json['type'] as String? ?? 'article',
      domain: json['domain'] as String? ?? 'politique',
      status: json['status'] as String? ?? 'draft',
      politicalOrientation:
          json['politicalOrientation'] as Map<String, dynamic>? ?? {},
      journalist: json['journalist'] as Map<String, dynamic>?,
      stats: json['stats'] as Map<String, dynamic>? ?? {},
      interactions: json['interactions'] as Map<String, dynamic>? ?? {},
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      relatedPosts: (json['relatedPosts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      opposingPosts: (json['opposingPosts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      opposedByPosts: (json['opposedByPosts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id': id,
      'title': title,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      'type': type,
      'domain': domain,
      'status': status,
      'politicalOrientation': politicalOrientation,
      if (journalist != null) 'journalist': journalist,
      'stats': stats,
      'interactions': interactions,
      'createdAt': createdAt,
      'content': content,
      if (metadata != null) 'metadata': metadata,
      'tags': tags,
      'sources': sources,
      if (relatedPosts != null) 'relatedPosts': relatedPosts,
      if (opposingPosts != null) 'opposingPosts': opposingPosts,
      if (opposedByPosts != null) 'opposedByPosts': opposedByPosts,
    };
  }
  Post toDomain() {
    return Post.fromJson(toJson());
  }
  factory PostDto.fromDomain(Post post) {
    final json = post.toJson();
    return PostDto.fromJson(json);
  }
}