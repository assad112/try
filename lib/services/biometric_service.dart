import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// نتيجة التحقق بالبصمة مع كود/رسالة خطأ اختيارية
class BiometricAuthResult {
  final bool success;
  final String? code;
  final String? message;

  const BiometricAuthResult({required this.success, this.code, this.message});
}

/// Biometric/Face ID authentication service
/// Uses only real registered biometric (no PIN or Pattern)
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Internal function: checks if a real biometric type exists on device
  static Future<bool> _hasRealBiometric() async {
    final List<BiometricType> availableBiometrics = await _auth
        .getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return false;
    }

    final hasFingerprint = availableBiometrics.contains(
      BiometricType.fingerprint,
    );
    final hasFace = availableBiometrics.contains(BiometricType.face);
    final hasIris = availableBiometrics.contains(BiometricType.iris);
    // strong/weak available in newer local_auth versions
    final hasStrong = availableBiometrics.contains(BiometricType.strong);
    final hasWeak = availableBiometrics.contains(BiometricType.weak);

    // If any of these types exist, device has real biometric
    return hasFingerprint || hasFace || hasIris || hasStrong || hasWeak;
  }

  /// Check if biometric (or Face ID) is available and usable
  static Future<bool> isAvailable() async {
    try {
      // Does device support biometric?
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // Can check biometric (enabled in settings)?
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      // Is a real biometric type registered?
      final bool hasRealBiometric = await _hasRealBiometric();
      if (!hasRealBiometric) return false;

      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns available biometric types (for debugging or additional info)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Complete biometric status check (for testing and diagnostics)
  /// Returns detailed information about biometric status on device
  static Future<Map<String, dynamic>> checkBiometricStatus() async {
    final Map<String, dynamic> status = {
      'isDeviceSupported': false,
      'canCheckBiometrics': false,
      'hasRealBiometric': false,
      'availableBiometrics': <String>[],
      'isAvailable': false,
      'error': null,
    };

    try {
      // Check device support
      status['isDeviceSupported'] = await _auth.isDeviceSupported();

      // Check verification capability
      status['canCheckBiometrics'] = await _auth.canCheckBiometrics;

      // Get available biometric types
      final biometrics = await _auth.getAvailableBiometrics();
      status['availableBiometrics'] = biometrics
          .map((b) => b.toString())
          .toList();

      // Check for real biometric
      status['hasRealBiometric'] = await _hasRealBiometric();

      // Final status
      status['isAvailable'] = await isAvailable();
    } on PlatformException catch (e) {
      status['error'] = 'PlatformException: ${e.message}';
    } catch (e) {
      status['error'] = 'Error: $e';
    }

    return status;
  }

  /// Perform biometric/Face ID authentication with detailed error info
  static Future<BiometricAuthResult> authenticate() async {
    try {
      // Complete check before showing biometric screen
      final bool available = await isAvailable();
      if (!available) {
        return const BiometricAuthResult(
          success: false,
          code: 'NotAvailable',
          message: 'Biometrics are not available or enabled on this device.',
        );
      }

      // Determine biometric type for user message
      final availableBiometrics = await _auth.getAvailableBiometrics();
      String biometricLabel = 'biometric';

      if (availableBiometrics.contains(BiometricType.face)) {
        biometricLabel = 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometricLabel = 'fingerprint';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        biometricLabel = 'iris scan';
      }

      // Show official biometric screen from system
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            'Please use your registered $biometricLabel to verify your identity and sign in.',
        options: const AuthenticationOptions(
          biometricOnly: true, // Prevents PIN or Pattern use
          stickyAuth: true, // Continues trying if returning from background
          useErrorDialogs: true, // Shows default system error messages
        ),
      );

      return BiometricAuthResult(success: didAuthenticate);
    } on PlatformException catch (e) {
      String readableMessage =
          'Biometric verification failed. Please try again.';

      switch (e.code) {
        case auth_error.notEnrolled:
          readableMessage =
              'No biometric is enrolled. Please add one in device settings.';
          break;
        case auth_error.passcodeNotSet:
          readableMessage =
              'A device lock/biometric must be enabled in settings first.';
          break;
        case auth_error.lockedOut:
          readableMessage =
              'Biometric sensor temporarily locked after failed attempts. Try later or use normal login.';
          break;
        case auth_error.permanentlyLockedOut:
          readableMessage =
              'Biometrics permanently locked. Unlock in settings, then try again.';
          break;
        default:
          readableMessage =
              'Biometrics unavailable (${e.code}). Try again or use normal login.';
      }

      return BiometricAuthResult(
        success: false,
        code: e.code,
        message: readableMessage,
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        code: 'unknown_error',
        message: 'Biometric verification failed: $e',
      );
    }
  }
}
