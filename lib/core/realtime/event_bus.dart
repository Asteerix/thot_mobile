import 'dart:async';
class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();
  final _controller = StreamController<AppEvent>.broadcast();
  Stream<T> on<T extends AppEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }
  void fire(AppEvent event) {
    _controller.add(event);
  }
  void dispose() {
    _controller.close();
  }
}
abstract class AppEvent {
  final DateTime timestamp;
  AppEvent() : timestamp = DateTime.now();
}
class PostCreatedEvent extends AppEvent {
  final String postId;
  final String postType;
  final String? journalistId;
  PostCreatedEvent({
    required this.postId,
    required this.postType,
    this.journalistId,
  });
}
class PostUpdatedEvent extends AppEvent {
  final String postId;
  PostUpdatedEvent({required this.postId});
}
class PostLikedEvent extends AppEvent {
  final String postId;
  final bool isLiked;
  final int likeCount;
  PostLikedEvent({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
  });
}
class PostBookmarkedEvent extends AppEvent {
  final String postId;
  final bool isBookmarked;
  final int bookmarkCount;
  PostBookmarkedEvent({
    required this.postId,
    required this.isBookmarked,
    required this.bookmarkCount,
  });
}
class PostVotedEvent extends AppEvent {
  final String postId;
  final String vote;
  final String dominantView;
  final Map<String, int> voteDistribution;
  PostVotedEvent({
    required this.postId,
    required this.vote,
    required this.dominantView,
    required this.voteDistribution,
  });
}
class PostCommentedEvent extends AppEvent {
  final String postId;
  final int commentCount;
  PostCommentedEvent({
    required this.postId,
    required this.commentCount,
  });
}
class PostDeletedEvent extends AppEvent {
  final String postId;
  PostDeletedEvent({required this.postId});
}
class ProfileUpdatedEvent extends AppEvent {
  final String userId;
  ProfileUpdatedEvent({required this.userId});
}
class RetryAttemptEvent extends AppEvent {
  final String action;
  final int attemptNumber;
  final int maxAttempts;
  RetryAttemptEvent({
    required this.action,
    required this.attemptNumber,
    required this.maxAttempts,
  });
}
enum CommentEventType { created, updated, deleted, liked, unliked }
class SocketCommentEvent extends AppEvent {
  final CommentEventType type;
  final dynamic data;
  SocketCommentEvent({
    required this.type,
    required this.data,
  });
}
class TypingIndicatorEvent extends AppEvent {
  final String userId;
  final String username;
  final String postId;
  final bool isTyping;
  TypingIndicatorEvent({
    required this.userId,
    required this.username,
    required this.postId,
    this.isTyping = true,
  });
}
class SocketNotificationEvent extends AppEvent {
  final Map<String, dynamic> notification;
  SocketNotificationEvent({required this.notification});
}
class SocketPostEvent extends AppEvent {
  final String type;
  final Map<String, dynamic> data;
  SocketPostEvent({
    required this.type,
    required this.data,
  });
}