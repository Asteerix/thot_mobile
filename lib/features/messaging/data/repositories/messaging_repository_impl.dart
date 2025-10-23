import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/either.dart';
import '../../domain/failures/messaging_failure.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
class MessagingRepositoryImpl implements MessagingRepository {
  final ApiClient _apiClient;
  MessagingRepositoryImpl(this._apiClient);
  @override
  Future<Either<MessagingFailure, List<Conversation>>> getConversations() async {
    try {
      final response = await _apiClient.get('/messages/conversations');
      final conversations = (response.data['conversations'] as List<dynamic>)
          .map((json) => Conversation.fromJson(json))
          .toList();
      return Right(conversations);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(MessagingUnauthorizedFailure());
      }
      return Left(MessagingNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(MessagingServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<MessagingFailure, Conversation>> getConversation(
      String conversationId) async {
    try {
      final response = await _apiClient.get('/messages/conversations/$conversationId');
      final conversation = Conversation.fromJson(response.data['conversation']);
      return Right(conversation);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(ConversationNotFoundFailure());
      }
      if (e.response?.statusCode == 401) {
        return const Left(MessagingUnauthorizedFailure());
      }
      return Left(MessagingNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(MessagingServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<MessagingFailure, List<Message>>> getMessages(
      String conversationId) async {
    try {
      final response = await _apiClient.get('/messages/$conversationId');
      final messages = (response.data['messages'] as List<dynamic>)
          .map((json) => Message.fromJson(json))
          .toList();
      return Right(messages);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(MessagingUnauthorizedFailure());
      }
      return Left(MessagingNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(MessagingServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<MessagingFailure, Message>> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '/messages',
        data: {
          'conversationId': conversationId,
          'receiverId': receiverId,
          'content': content,
        },
      );
      final message = Message.fromJson(response.data['message']);
      return Right(message);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(MessagingUnauthorizedFailure());
      }
      return Left(MessagingNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(MessagingServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<MessagingFailure, void>> markAsRead(String conversationId) async {
    try {
      await _apiClient.put('/messages/$conversationId/read');
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(MessagingUnauthorizedFailure());
      }
      return Left(MessagingNetworkFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(MessagingServerFailure(e.toString()));
    }
  }
}