import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/exceptions.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/network/network_info.dart';
import 'package:claim_ai/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:claim_ai/features/notifications/domain/entities/pending_action_entity.dart';
import 'package:claim_ai/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PendingActionEntity>>> getPendingActions() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final actions = await remoteDataSource.getPendingActions();
      return Right(actions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
