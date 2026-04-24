import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_summary_entity.dart';

abstract class ClaimsRepository {
  Future<Either<Failure, List<ClaimEntity>>> getClaims({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  });

  Future<Either<Failure, ClaimEntity>> getClaimById(String id);

  Future<Either<Failure, ClaimSummaryEntity>> getClaimSummary(String id);

  Future<Either<Failure, ClaimEntity>> updateClaimStatus({
    required String id,
    required String status,
  });

  Future<Either<Failure, ClaimSummaryEntity>> getDashboardSummary();
}
