import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/chat/domain/entities/chat_message_entity.dart';
import 'package:claim_ai/features/chat/domain/repositories/chat_repository.dart';

class SendMessageUseCase
    extends UseCase<ChatMessageEntity, SendMessageParams> {
  final ChatRepository repository;

  SendMessageUseCase({required this.repository});

  @override
  Future<Either<Failure, ChatMessageEntity>> call(SendMessageParams params) {
    return repository.sendMessage(
      message: params.message,
      claimId: params.claimId,
    );
  }
}

class SendMessageParams {
  final String message;
  final String claimId;

  const SendMessageParams({required this.message, required this.claimId});
}
