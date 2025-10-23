import '../../domain/entities/message.dart';
class MessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final String createdAt;
  final bool isRead;
  final Map<String, dynamic>? senderProfile;
  final Map<String, dynamic>? receiverProfile;
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.senderProfile,
    this.receiverProfile,
  });
  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      isRead: json['isRead'] ?? false,
      senderProfile: json['senderProfile'],
      receiverProfile: json['receiverProfile'],
    );
  }
  Message toEntity() {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      createdAt: DateTime.parse(createdAt),
      isRead: isRead,
      senderProfile: senderProfile,
      receiverProfile: receiverProfile,
    );
  }
}