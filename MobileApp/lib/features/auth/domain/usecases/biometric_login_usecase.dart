import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/services/biometric_service.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/core/usecases/usecase.dart';
import 'package:claim_ai/features/auth/domain/entities/user_entity.dart';
import 'package:claim_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class BiometricLoginUseCase extends UseCase<UserEntity, NoParams> {
  final AuthRepository repository;
  final BiometricService biometricService;
  final LocalStorage localStorage;

  BiometricLoginUseCase({
    required this.repository,
    required this.biometricService,
    required this.localStorage,
  });

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    if (!await localStorage.hasStoredSession()) {
      return const Left(AuthFailure(message: 'No saved session. Please sign in again.'));
    }
    if (!await localStorage.isBiometricEnabled()) {
      return const Left(AuthFailure(message: 'Biometric login is disabled.'));
    }
    if (!await biometricService.isAvailable()) {
      return const Left(BiometricFailure.unavailable());
    }

    final authResult = await biometricService.authenticate(
      reason: 'Sign in to ClaimAI',
    );
    final authFailure = authResult.fold<Failure?>((f) => f, (_) => null);
    if (authFailure != null) return Left(authFailure);

    final refreshResult = await repository.refreshTokens();
    final refreshFailure = refreshResult.fold<Failure?>((f) => f, (_) => null);
    if (refreshFailure != null) return Left(refreshFailure);

    final profileResult = await repository.getUserProfile();
    final profileFailure = profileResult.fold<Failure?>((f) => f, (_) => null);
    if (profileFailure != null) return Left(profileFailure);

    final user = profileResult.getOrElse(() => throw StateError('unreachable'));
    if (!user.isBiometricEnabled) {
      // Server revoked biometric — wipe local flag and force OTP.
      await localStorage.clearBiometricFlag();
      return const Left(AuthFailure(
        message: 'Biometric login was disabled. Please sign in again.',
      ));
    }
    return Right(user);
  }
}
