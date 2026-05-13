import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
  });
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({required super.message, this.fieldErrors});

  @override
  List<Object?> get props => [message, fieldErrors];
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
  });
}

enum BiometricFailureKind {
  cancelled,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  unavailable,
  unknown,
}

class BiometricFailure extends Failure {
  final BiometricFailureKind kind;

  const BiometricFailure({required this.kind, required super.message});

  const BiometricFailure.cancelled()
      : kind = BiometricFailureKind.cancelled,
        super(message: 'Biometric prompt cancelled.');

  const BiometricFailure.notEnrolled()
      : kind = BiometricFailureKind.notEnrolled,
        super(message: 'No biometrics enrolled on this device.');

  const BiometricFailure.lockedOut()
      : kind = BiometricFailureKind.lockedOut,
        super(message: 'Too many attempts. Try again in a moment.');

  const BiometricFailure.permanentlyLockedOut()
      : kind = BiometricFailureKind.permanentlyLockedOut,
        super(message: 'Biometrics locked. Unlock with your device passcode.');

  const BiometricFailure.passcodeNotSet()
      : kind = BiometricFailureKind.passcodeNotSet,
        super(message: 'Set a device passcode to use biometrics.');

  const BiometricFailure.unavailable()
      : kind = BiometricFailureKind.unavailable,
        super(message: 'Biometric authentication is not available on this device.');

  const BiometricFailure.unknown([String? message])
      : kind = BiometricFailureKind.unknown,
        super(message: message ?? 'Biometric authentication failed.');

  @override
  List<Object?> get props => [kind, message];
}
