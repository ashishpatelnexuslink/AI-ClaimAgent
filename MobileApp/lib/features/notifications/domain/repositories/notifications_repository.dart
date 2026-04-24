import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/features/notifications/domain/entities/pending_action_entity.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<PendingActionEntity>>> getPendingActions();
  Future<Either<Failure, void>> markAsRead(String notificationId);
}
