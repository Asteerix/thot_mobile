import '../../../../core/utils/either.dart';
import '../failures/messaging_failure.dart';
import '../entities/message.dart';
import '../entities/conversation.dart';
abstract class MessagingRepository {
  Future<Either<MessagingFailure, List<Conversation>>> getConversations();
  Future<Either<MessagingFailure, Conversation>> getConversation(String conversationId);
  Future<Either<MessagingFailure, List<Message>>> getMessages(String conversationId);
  Future<Either<MessagingFailure, Message>> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  });
  Future<Either<MessagingFailure, void>> markAsRead(String conversationId);
}