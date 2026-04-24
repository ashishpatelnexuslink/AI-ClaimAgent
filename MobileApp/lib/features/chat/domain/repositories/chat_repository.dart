import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/features/chat/domain/entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String message,
    required String claimId,
  });

  Future<Either<Failure, List<ChatMessageEntity>>> getChatHistory(
    String claimId,
  );

  Future<Either<Failure, List<String>>> getSuggestions(String claimId);
}
