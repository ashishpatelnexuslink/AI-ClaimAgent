import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/notifications/domain/entities/pending_action_entity.dart';
import 'package:claim_ai/features/notifications/domain/repositories/notifications_repository.dart';

class GetPendingActionsUseCase
    extends UseCase<List<PendingActionEntity>, NoParams> {
  final NotificationsRepository repository;

  GetPendingActionsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<PendingActionEntity>>> call(NoParams params) {
    return repository.getPendingActions();
  }
}
