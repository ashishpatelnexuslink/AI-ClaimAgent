import 'package:claim_ai/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics (fingerprint / face).
  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Available biometric types enrolled on the device. Used to tailor the
  /// "Sign in with Face ID / Fingerprint" button copy on the login screen.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  /// Prompt the user to authenticate with biometrics.
  ///
  /// Returns [Unit] on success, or a typed [BiometricFailure] describing the
  /// failure reason so callers can show specific messages (cancelled,
  /// locked-out, not-enrolled, etc.).
  Future<Either<BiometricFailure, Unit>> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) return const Right(unit);
      return const Left(BiometricFailure.cancelled());
    } on LocalAuthException catch (e) {
      debugPrint(
        '[biometric] LocalAuthException code=${e.code.name} description=${e.description}',
      );
      return Left(_mapException(e));
    } catch (e) {
      debugPrint('[biometric] unexpected error: $e');
      return Left(BiometricFailure.unknown(e.toString()));
    }
  }

  BiometricFailure _mapException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
        return const BiometricFailure.cancelled();
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return const BiometricFailure.notEnrolled();
      case LocalAuthExceptionCode.noCredentialsSet:
        return const BiometricFailure.passcodeNotSet();
      case LocalAuthExceptionCode.temporaryLockout:
        return const BiometricFailure.lockedOut();
      case LocalAuthExceptionCode.biometricLockout:
        return const BiometricFailure.permanentlyLockedOut();
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
        return const BiometricFailure.unavailable();
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.authInProgress:
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return BiometricFailure.unknown(e.description);
    }
  }
}
