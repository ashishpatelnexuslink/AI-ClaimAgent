import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';
import 'package:claim_ai/features/claims/domain/repositories/claims_repository.dart';

class GetClaimsUseCase extends UseCase<List<ClaimEntity>, GetClaimsParams> {
  final ClaimsRepository repository;

  GetClaimsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<ClaimEntity>>> call(GetClaimsParams params) {
    return repository.getClaims(
      page: params.page,
      limit: params.limit,
      status: params.status,
      search: params.search,
    );
  }
}

class GetClaimsParams {
  final int page;
  final int limit;
  final String? status;
  final String? search;

  const GetClaimsParams({
    this.page = 1,
    this.limit = 20,
    this.status,
    this.search,
  });
}
