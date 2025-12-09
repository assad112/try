import 'package:flutter/foundation.dart';

/// خدمة تسجيل الأحداث (Logging)
class AppLogger {
  static const String _prefix = '[Jeel ERP]';
  
  /// تسجيل معلومة
  static void info(String message, [Object? data]) {
    if (kDebugMode) {
      print('$_prefix [INFO] $message${data != null ? ' - $data' : ''}');
    }
  }
  
  /// تسجيل تحذير
  static void warning(String message, [Object? data]) {
    if (kDebugMode) {
      print('$_prefix [WARNING] $message${data != null ? ' - $data' : ''}');
    }
  }
  
  /// تسجيل خطأ
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix [ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }
  
  /// تسجيل محاولة دخول
  static void logLoginAttempt(String email, bool success) {
    info('Login attempt', {
      'email': _maskEmail(email),
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// تسجيل محاولة بصمة
  static void logBiometricAttempt(bool success) {
    info('Biometric attempt', {
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// تسجيل تسجيل خروج
  static void logLogout(String? email) {
    info('Logout', {
      'email': email != null ? _maskEmail(email) : 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// تسجيل قفل الحساب
  static void logAccountLockout(String email, int minutes) {
    warning('Account locked', {
      'email': _maskEmail(email),
      'duration_minutes': minutes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// إخفاء البريد الإلكتروني جزئياً للخصوصية
  static String _maskEmail(String email) {
    if (!email.contains('@')) return '***';
    final parts = email.split('@');
    if (parts[0].length <= 2) return '***@${parts[1]}';
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }
  
  /// تسجيل حدث مخصص
  static void logEvent(String eventName, [Map<String, dynamic>? data]) {
    info(eventName, data);
  }
}
