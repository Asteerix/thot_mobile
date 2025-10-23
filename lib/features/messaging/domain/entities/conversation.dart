import 'message.dart';
class Conversation {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final Map<String, dynamic>? otherUserProfile;
  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.otherUserProfile,
  });
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      otherUserProfile: json['otherUserProfile'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
      'otherUserProfile': otherUserProfile,
    };
  }
}