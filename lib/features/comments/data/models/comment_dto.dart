class CommentAuthorDto {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final String role;
  const CommentAuthorDto({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
    required this.isVerified,
    required this.role,
  });
  factory CommentAuthorDto.fromJson(Map<String, dynamic> json) {
    return CommentAuthorDto(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['name'] as String? ?? 'Unknown',
      name: json['name'] as String? ?? json['username'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'role': role,
    };
  }
}
class CommentDto {
  final String id;
  final String postId;
  final CommentAuthorDto author;
  final String content;
  final int likesCount;
  final bool isLiked;
  final int replyCount;
  final String? parentCommentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isDeleted;
  final DateTime? deletedAt;
  final String? status;
  final bool? isEdited;
  const CommentDto({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.likesCount,
    required this.isLiked,
    this.replyCount = 0,
    this.parentCommentId,
    this.createdAt,
    this.updatedAt,
    this.isDeleted,
    this.deletedAt,
    this.status,
    this.isEdited,
  });
  factory CommentDto.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return CommentDto(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: authorJson != null
          ? CommentAuthorDto.fromJson(authorJson)
          : CommentAuthorDto(
              id: 'unknown',
              username: 'Unknown',
              name: 'Unknown',
              isVerified: false,
              role: 'user',
            ),
      content: json['content'] as String,
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      replyCount: json['replyCount'] as int? ?? 0,
      parentCommentId: json['parentCommentId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      status: json['status'] as String?,
      isEdited: json['isEdited'] as bool?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'author': author.toJson(),
      'content': content,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'replyCount': replyCount,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      if (status != null) 'status': status,
      if (isEdited != null) 'isEdited': isEdited,
    };
  }
}