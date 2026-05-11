import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics (fingerprint / face)
  Future<bool> isAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }

  /// Prompt user to authenticate with biometrics
  /// Returns true if authenticated successfully
  Future<bool> authenticate({String reason = 'Authenticate to continue'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      // Surface the platform-level reason in logs so silent prompt failures
      // (the original splash-gate bug) are diagnosable from adb logcat.
      debugPrint('[biometric] LocalAuthException code=${e.code.name} description=${e.description}');
      return false;
    } catch (e) {
      debugPrint('[biometric] unexpected error: $e');
      return false;
    }
  }
}
