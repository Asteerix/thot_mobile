import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';
import 'package:thot/core/infrastructure/dependency_injection.dart';
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return ServiceLocator.instance.messagingRepository;
});
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.watch(messagingRepositoryProvider);
  final result = await repository.getConversations();
  return result.fold(
    (failure) => [],
    (conversations) => conversations,
  );
});
final conversationMessagesProvider = FutureProvider.family<List<Message>, String>(
  (ref, conversationId) async {
    final repository = ref.watch(messagingRepositoryProvider);
    final result = await repository.getMessages(conversationId);
    return result.fold(
      (failure) => [],
      (messages) => messages,
    );
  },
);
final sendMessageProvider = Provider((ref) {
  return ({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    final repository = ref.read(messagingRepositoryProvider);
    final result = await repository.sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      content: content,
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => ref.invalidate(conversationMessagesProvider(conversationId)),
    );
  };
});