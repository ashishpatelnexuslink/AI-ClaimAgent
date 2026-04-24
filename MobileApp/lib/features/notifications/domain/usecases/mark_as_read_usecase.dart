import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/notifications/domain/repositories/notifications_repository.dart';

class MarkAsReadUseCase extends UseCase<void, String> {
  final NotificationsRepository repository;

  MarkAsReadUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
