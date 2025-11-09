import 'package:thot/core/themes/app_colors.dart';
import 'package:flutter/material.dart';
class NotificationModel {
  final String id;
  final String recipientId;
  final String type;
  final String entityType;
  final String entityId;
  final String message;
  final bool read;
  final DateTime createdAt;
  final NotificationSender sender;
  final String? postId;
  final String? commentId;
  final NotificationPost? post;
  final NotificationComment? comment;
  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.sender,
    this.postId,
    this.commentId,
    this.post,
    this.comment,
  });
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String? postIdValue;
    NotificationPost? postValue;
    if (json['postId'] != null) {
      if (json['postId'] is String) {
        postIdValue = json['postId'];
      } else if (json['postId'] is Map) {
        postValue = NotificationPost.fromJson(json['postId']);
        postIdValue = postValue.id;
      }
    }
    String? commentIdValue;
    NotificationComment? commentValue;
    if (json['commentId'] != null) {
      if (json['commentId'] is String) {
        commentIdValue = json['commentId'];
      } else if (json['commentId'] is Map) {
        commentValue = NotificationComment.fromJson(json['commentId']);
        commentIdValue = commentValue.id;
      }
    }
    String recipientValue = '';
    if (json['recipient'] != null) {
      if (json['recipient'] is String) {
        recipientValue = json['recipient'];
      } else if (json['recipient'] is Map) {
        recipientValue = (json['recipient'] as Map)['_id']?.toString() ??
                        (json['recipient'] as Map)['id']?.toString() ?? '';
      }
    }
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      recipientId: recipientValue,
      type: json['type'] ?? '',
      entityType: json['entityType'] ?? '',
      entityId: json['entityId']?.toString() ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sender: NotificationSender.fromJson(json['sender']),
      postId: postIdValue,
      commentId: commentIdValue,
      post: postValue,
      comment: commentValue,
    );
  }
  IconData get icon {
    switch (type) {
      case 'post_like':
        return Icons.favorite;
      case 'comment_like':
        return Icons.favorite;
      case 'comment_reply':
        return Icons.comment;
      case 'new_follower':
        return Icons.person_add;
      case 'post_removed':
        return Icons.delete;
      case 'article_published':
        return Icons.article;
      case 'mention':
        return Icons.alternate_email;
      case 'new_post_from_followed':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }
  Color get iconColor => getIconColor();
  Color getIconColor([BuildContext? context]) {
    switch (type) {
      case 'post_like':
      case 'comment_like':
        return AppColors.red;
      case 'comment_reply':
      case 'mention':
        return AppColors.blue;
      case 'new_follower':
        return AppColors.success;
      case 'post_removed':
        return AppColors.orange;
      default:
        return context != null
            ? Theme.of(context).colorScheme.outline
            : AppColors.neutral;
    }
  }
  String getFormattedMessage() {
    return '${sender.username} $message';
  }
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays > 30) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'maintenant';
    }
  }
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? entityType,
    String? entityId,
    String? message,
    bool? read,
    DateTime? createdAt,
    NotificationSender? sender,
    String? postId,
    String? commentId,
    NotificationPost? post,
    NotificationComment? comment,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      post: post ?? this.post,
      comment: comment ?? this.comment,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipientId,
      'type': type,
      'entityType': entityType,
      'entityId': entityId,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'sender': sender.toJson(),
      if (postId != null) 'postId': postId,
      if (commentId != null) 'commentId': commentId,
      if (post != null) 'post': post!.toJson(),
      if (comment != null) 'comment': comment!.toJson(),
    };
  }
}
class NotificationSender {
  final String id;
  final String username;
  final String? profileImage;
  NotificationSender({
    required this.id,
    required this.username,
    this.profileImage,
  });
  factory NotificationSender.fromJson(dynamic json) {
    if (json is String) {
      return NotificationSender(
        id: json,
        username: 'Utilisateur',
        profileImage: null,
      );
    }
    final Map<String, dynamic> senderData = json as Map<String, dynamic>;
    return NotificationSender(
      id: senderData['_id'] ?? senderData['id'] ?? '',
      username: senderData['username'] ?? senderData['name'] ?? 'Utilisateur',
      profileImage: senderData['avatarUrl'] ?? senderData['profileImage'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}
class NotificationPost {
  final String id;
  final String title;
  final String type;
  final String? coverImage;
  final String? thumbnailUrl;
  NotificationPost({
    required this.id,
    required this.title,
    required this.type,
    this.coverImage,
    this.thumbnailUrl,
  });
  factory NotificationPost.fromJson(Map<String, dynamic> json) {
    return NotificationPost(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'article',
      coverImage: json['coverImage'],
      thumbnailUrl: json['coverImage'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      if (coverImage != null) 'coverImage': coverImage,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }
}
class NotificationComment {
  final String id;
  final String content;
  NotificationComment({
    required this.id,
    required this.content,
  });
  factory NotificationComment.fromJson(Map<String, dynamic> json) {
    return NotificationComment(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
    };
  }
}