import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/exceptions.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/network/network_info.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_remote_datasource.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_local_datasource.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_summary_entity.dart';
import 'package:claim_ai/features/claims/domain/repositories/claims_repository.dart';

class ClaimsRepositoryImpl implements ClaimsRepository {
  final ClaimsRemoteDataSource remoteDataSource;
  final ClaimsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ClaimsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ClaimEntity>>> getClaims({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final claims = await remoteDataSource.getClaims(
          page: page,
          limit: limit,
          status: status,
          search: search,
        );
        if (page == 1) {
          await localDataSource.cacheClaims(claims);
        }
        return Right(claims);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
      }
    } else {
      try {
        final cached = await localDataSource.getCachedClaims();
        return Right(cached);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, ClaimEntity>> getClaimById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final claim = await remoteDataSource.getClaimById(id);
        await localDataSource.cacheClaim(claim);
        return Right(claim);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
      }
    } else {
      final cached = await localDataSource.getCachedClaim(id);
      if (cached != null) return Right(cached);
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, ClaimSummaryEntity>> getClaimSummary(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final summary = await remoteDataSource.getClaimSummary(id);
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, ClaimEntity>> updateClaimStatus({
    required String id,
    required String status,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final claim = await remoteDataSource.updateClaimStatus(
        id: id,
        status: status,
      );
      return Right(claim);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, ClaimSummaryEntity>> getDashboardSummary() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final summary = await remoteDataSource.getDashboardSummary();
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
