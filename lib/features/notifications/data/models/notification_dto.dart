class NotificationSenderDto {
  final String id;
  final String? username;
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final String role;
  const NotificationSenderDto({
    required this.id,
    this.username,
    required this.name,
    this.avatarUrl,
    required this.isVerified,
    required this.role,
  });
  factory NotificationSenderDto.fromJson(Map<String, dynamic> json) {
    return NotificationSenderDto(
      id: json['id'] as String? ?? json['_id'] as String,
      username: json['username'] as String?,
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'role': role,
    };
  }
}
class NotificationDto {
  final String id;
  final String recipientId;
  final NotificationSenderDto? sender;
  final String title;
  final String message;
  final String type;
  final String entityType;
  final String entityId;
  final String? postId;
  final String? commentId;
  final bool isRead;
  final DateTime? createdAt;
  const NotificationDto({
    required this.id,
    required this.recipientId,
    this.sender,
    required this.title,
    required this.message,
    required this.type,
    required this.entityType,
    required this.entityId,
    this.postId,
    this.commentId,
    required this.isRead,
    this.createdAt,
  });
  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'] as Map<String, dynamic>?;
    return NotificationDto(
      id: json['id'] as String? ?? json['_id'] as String,
      recipientId: json['recipient'] as String? ?? json['recipientId'] as String? ?? json['userId'] as String,
      sender: senderJson != null ? NotificationSenderDto.fromJson(senderJson) : null,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      entityType: json['entityType'] as String? ?? 'post',
      entityId: json['entityId'] as String? ?? '',
      postId: json['postId'] as String?,
      commentId: json['commentId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      if (sender != null) 'sender': sender!.toJson(),
      'title': title,
      'message': message,
      'type': type,
      'entityType': entityType,
      'entityId': entityId,
      if (postId != null) 'postId': postId,
      if (commentId != null) 'commentId': commentId,
      'isRead': isRead,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}