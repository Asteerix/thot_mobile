sealed class MessagingFailure {
  final String message;
  const MessagingFailure(this.message);
}
class MessagingNetworkFailure extends MessagingFailure {
  const MessagingNetworkFailure([super.message = 'Network error']);
}
class MessagingServerFailure extends MessagingFailure {
  const MessagingServerFailure([super.message = 'Server error']);
}
class MessagingUnauthorizedFailure extends MessagingFailure {
  const MessagingUnauthorizedFailure([super.message = 'Unauthorized access']);
}
class ConversationNotFoundFailure extends MessagingFailure {
  const ConversationNotFoundFailure([super.message = 'Conversation not found']);
}