import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  // التحقق من توفر البصمة/Face ID
  static Future<bool> isAvailable() async {
    try {
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) {
        return false;
      }
      
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // الحصول على أنواع البصمة المتاحة
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // تنفيذ المصادقة البيومترية
  static Future<bool> authenticate() async {
    try {
      // التحقق من توفر البصمة أولاً
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'يرجى استخدام البصمة أو Face ID للمتابعة',
        options: const AuthenticationOptions(
          biometricOnly: false, // السماح باستخدام PIN كبديل
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}

