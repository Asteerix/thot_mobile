class CommentAuthor {
  final String id;
  final String username;
  final String name;
  final String? avatar;
  final String? avatarUrl;
  final bool isVerified;
  final bool isJournalist;
  CommentAuthor({
    required this.id,
    required this.username,
    required this.name,
    this.avatar,
    this.avatarUrl,
    this.isVerified = false,
    this.isJournalist = false,
  });
}

class Comment {
  final String id;
  final String postId;
  final String content;
  final CommentAuthor author;
  final int likes;
  final bool isLiked;
  final int replyCount;
  final String? parentComment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletionReason;
  Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.author,
    this.likes = 0,
    this.isLiked = false,
    this.replyCount = 0,
    this.parentComment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.deletedAt,
    this.deletionReason,
  });
  String get text => content;
  String get username => author.username;
  String? get avatar => author.avatarUrl ?? author.avatar;
  Comment copyWith({
    String? id,
    String? postId,
    String? content,
    CommentAuthor? author,
    int? likes,
    bool? isLiked,
    int? replyCount,
    String? parentComment,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletionReason,
    int? likesCount,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      author: author ?? this.author,
      likes: likes ?? likesCount ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      replyCount: replyCount ?? this.replyCount,
      parentComment: parentComment ?? this.parentComment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletionReason: deletionReason ?? this.deletionReason,
    );
  }
}
