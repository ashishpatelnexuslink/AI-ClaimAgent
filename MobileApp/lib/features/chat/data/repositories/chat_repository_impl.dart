import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/exceptions.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/network/network_info.dart';
import 'package:claim_ai/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:claim_ai/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:claim_ai/features/chat/domain/entities/chat_message_entity.dart';
import 'package:claim_ai/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String message,
    required String claimId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await remoteDataSource.sendMessage(
        message: message,
        claimId: claimId,
      );
      // Cache the assistant's response
      await localDataSource.cacheMessage(claimId, result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getChatHistory(
    String claimId,
  ) async {
    if (!await networkInfo.isConnected) {
      // Offline fallback: return cached messages
      final cached = await localDataSource.getCachedMessages(claimId);
      if (cached.isNotEmpty) {
        return Right(cached);
      }
      return const Left(NetworkFailure());
    }
    try {
      final messages = await remoteDataSource.getChatHistory(claimId);
      // Cache for offline access
      await localDataSource.cacheMessages(claimId, messages);
      return Right(messages);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSuggestions(String claimId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final suggestions = await remoteDataSource.getSuggestions(claimId);
      return Right(suggestions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
