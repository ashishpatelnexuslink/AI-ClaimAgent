import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';
import 'package:claim_ai/features/claims/domain/repositories/claims_repository.dart';

class GetClaimDetailUseCase extends UseCase<ClaimEntity, String> {
  final ClaimsRepository repository;

  GetClaimDetailUseCase({required this.repository});

  @override
  Future<Either<Failure, ClaimEntity>> call(String claimId) {
    return repository.getClaimById(claimId);
  }
}
