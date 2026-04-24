import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/chat/data/models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String claimId,
  });
  Future<List<ChatMessageModel>> getChatHistory(String claimId);
  Future<List<String>> getSuggestions(String claimId);

  /// Bulk-saves a full chat transcript to the `Conversations` /
  /// `ConversationMessages` tables via `POST /mobile/conversations`.
  ///
  /// [claimId] is optional — pass null when no local claim row has been
  /// created yet. When provided it must match a claim owned by the caller.
  Future<Map<String, dynamic>> saveConversation({
    String? threadId,
    String? claimId,
    String? externalReference,
    String? title,
    required List<Map<String, dynamic>> messages,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final DioClient _client;

  ChatRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required String claimId,
  }) async {
    final response = await _client.post(
      ApiConstants.chatSend,
      data: {'message': message, 'claimId': claimId},
    );
    return ChatMessageModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ChatMessageModel>> getChatHistory(String claimId) async {
    final response = await _client.get(
      ApiConstants.chatHistory.replaceFirst('{claimId}', claimId),
    );
    final list = response.data['data'] as List;
    return list
        .map((json) =>
            ChatMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> getSuggestions(String claimId) async {
    final response = await _client.get(
      ApiConstants.chatSuggestions,
      queryParameters: {'claimId': claimId},
    );
    final list = response.data['suggestions'] as List;
    return list.cast<String>();
  }

  @override
  Future<Map<String, dynamic>> saveConversation({
    String? threadId,
    String? claimId,
    String? externalReference,
    String? title,
    required List<Map<String, dynamic>> messages,
  }) async {
    final response = await _client.post(
      ApiConstants.saveConversation,
      data: {
        'threadId': ?threadId,
        'claimId': ?claimId,
        'externalReference': ?externalReference,
        'title': ?title,
        'messages': messages,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
