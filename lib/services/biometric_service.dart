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

/// خدمة التعامل مع البصمة / Face ID
/// تعتمد على البصمة الحقيقية المسجلة في الجهاز فقط (بدون PIN أو Pattern)
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// دالة داخلية (خاصة): تتحقق إذا في نوع حقيقي من البصمة في الجهاز
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
    // strong / weak موجودة في الإصدارات الجديدة من local_auth
    final hasStrong = availableBiometrics.contains(BiometricType.strong);
    final hasWeak = availableBiometrics.contains(BiometricType.weak);

    // وجود أي نوع من هذه الأنواع يعني أن عند الجهاز بصمة حقيقية
    return hasFingerprint || hasFace || hasIris || hasStrong || hasWeak;
  }

  /// التحقق هل البصمة (أو Face ID) متاحة وقابلة للاستخدام
  static Future<bool> isAvailable() async {
    try {
      // هل الجهاز أصلاً يدعم البصمة؟
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // هل يمكن فحص البصمة (مفعّلة في الإعدادات)؟
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      // هل يوجد نوع حقيقي من البصمة مسجل؟
      final bool hasRealBiometric = await _hasRealBiometric();
      if (!hasRealBiometric) return false;

      return true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// إرجاع أنواع البصمة المتاحة (للاستخدام في الـ Debug أو معلومات إضافية)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// فحص شامل لحالة البصمة (للاختبار والتشخيص)
  /// يرجع معلومات مفصلة عن حالة البصمة في الجهاز
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
      // فحص دعم الجهاز
      status['isDeviceSupported'] = await _auth.isDeviceSupported();

      // فحص إمكانية التحقق
      status['canCheckBiometrics'] = await _auth.canCheckBiometrics;

      // الحصول على أنواع البصمة المتاحة
      final biometrics = await _auth.getAvailableBiometrics();
      status['availableBiometrics'] = biometrics
          .map((b) => b.toString())
          .toList();

      // فحص وجود بصمة حقيقية
      status['hasRealBiometric'] = await _hasRealBiometric();

      // الحالة النهائية
      status['isAvailable'] = await isAvailable();
    } on PlatformException catch (e) {
      status['error'] = 'PlatformException: ${e.message}';
    } catch (e) {
      status['error'] = 'Error: $e';
    }

    return status;
  }

  /// تنفيذ مصادقة البصمة/Face ID مع إرجاع تفاصيل الخطأ إن وجدت
  static Future<BiometricAuthResult> authenticate() async {
    try {
      // فحص متكامل قبل إظهار شاشة البصمة
      final bool available = await isAvailable();
      if (!available) {
        return const BiometricAuthResult(
          success: false,
          code: 'NotAvailable',
          message: 'البصمة غير متاحة على هذا الجهاز أو غير مفعّلة',
        );
      }

      // تحديد نوع البصمة للرسالة التي ستظهر للمستخدم
      final availableBiometrics = await _auth.getAvailableBiometrics();
      String biometricLabel = 'البصمة';

      if (availableBiometrics.contains(BiometricType.face)) {
        biometricLabel = 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometricLabel = 'البصمة';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        biometricLabel = 'البصمة';
      }

      // عرض شاشة البصمة الرسمية من النظام
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            'يرجى استخدام $biometricLabel المحفوظة في جهازك للتحقق من هويتك وتسجيل الدخول',
        options: const AuthenticationOptions(
          biometricOnly: true, // يمنع استخدام PIN أو Pattern
          stickyAuth: true, // يستمر في المحاولة عند الرجوع من الخلفية
          useErrorDialogs: true, // يعرض رسائل الخطأ الافتراضية من النظام
        ),
      );

      return BiometricAuthResult(success: didAuthenticate);
    } on PlatformException catch (e) {
      String readableMessage = 'فشل التحقق من البصمة. حاول مرة أخرى.';

      switch (e.code) {
        case auth_error.notEnrolled:
          readableMessage =
              'لا توجد بصمة مسجلة. يرجى إضافة بصمة من إعدادات الجهاز.';
          break;
        case auth_error.passcodeNotSet:
          readableMessage =
              'يجب تفعيل قفل الشاشة/البصمة في إعدادات الجهاز أولاً.';
          break;
        case auth_error.lockedOut:
          readableMessage =
              'تم قفل مستشعر البصمة مؤقتاً بعد محاولات فاشلة. حاول لاحقاً أو استخدم تسجيل الدخول العادي.';
          break;
        case auth_error.permanentlyLockedOut:
          readableMessage =
              'تم قفل البصمة نهائياً. افتح القفل من إعدادات الجهاز ثم جرّب مجدداً.';
          break;
        default:
          readableMessage =
              'تعذّر استخدام البصمة (${e.code}). يمكنك المحاولة مرة أخرى أو استخدام تسجيل الدخول العادي.';
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
        message: 'تعذر التحقق بالبصمة: $e',
      );
    }
  }
}
