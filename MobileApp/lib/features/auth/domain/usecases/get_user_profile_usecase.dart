import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';

class GetUserProfileUseCase extends UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetUserProfileUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getUserProfile();
  }
}
