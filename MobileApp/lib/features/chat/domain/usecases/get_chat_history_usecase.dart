import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/chat/domain/entities/chat_message_entity.dart';
import 'package:claim_ai/features/chat/domain/repositories/chat_repository.dart';

class GetChatHistoryUseCase
    extends UseCase<List<ChatMessageEntity>, String> {
  final ChatRepository repository;

  GetChatHistoryUseCase({required this.repository});

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> call(String claimId) {
    return repository.getChatHistory(claimId);
  }
}
