import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_summary_entity.dart';
import 'package:claim_ai/features/claims/domain/repositories/claims_repository.dart';

class GetDashboardSummaryUseCase
    extends UseCase<ClaimSummaryEntity, NoParams> {
  final ClaimsRepository repository;

  GetDashboardSummaryUseCase({required this.repository});

  @override
  Future<Either<Failure, ClaimSummaryEntity>> call(NoParams params) {
    return repository.getDashboardSummary();
  }
}
