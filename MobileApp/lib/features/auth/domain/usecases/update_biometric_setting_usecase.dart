import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/services/biometric_service.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateBiometricSettingUseCase extends UseCase<UserEntity, bool> {
  final AuthRepository repository;
  final BiometricService biometricService;

  UpdateBiometricSettingUseCase({
    required this.repository,
    required this.biometricService,
  });

  @override
  Future<Either<Failure, UserEntity>> call(bool isEnabled) async {
    if (isEnabled) {
      // Verify the user before enabling so we don't trust a borrowed phone.
      if (!await biometricService.isAvailable()) {
        return const Left(BiometricFailure.unavailable());
      }
      final authResult = await biometricService.authenticate(
        reason: 'Verify your identity to enable biometric login',
      );
      final authFailure = authResult.fold<Failure?>((f) => f, (_) => null);
      if (authFailure != null) return Left(authFailure);
    }
    return repository.updateBiometricEnabled(isEnabled);
  }
}
