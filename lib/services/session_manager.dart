import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  // تخزين آمن مع إعدادات مخصصة للأندرويد و iOS
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLastLogin = 'last_login_timestamp';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyFailedAttempts = 'failed_attempts';
  static const String _keyLockoutTime = 'lockout_time';

  // مدة صلاحية الجلسة (7 أيام)
  static const Duration _sessionTimeout = Duration(days: 7);

  // الحد الأقصى لمحاولات الدخول الفاشلة
  static const int _maxFailedAttempts = 5;

  // مدة القفل بعد تجاوز المحاولات
  static const Duration _lockoutDuration = Duration(minutes: 15);

  // حفظ معلومات تسجيل الدخول
  static Future<void> saveLoginInfo(String username, String password) async {
    try {
      // التأكد من أن القيم غير فارغة
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Username and password are required');
      }

      // حفظ البيانات بشكل متسلسل للتأكد من الحفظ - فوري بدون تأخير
      await _storage.write(key: _keyUsername, value: username);

      await _storage.write(key: _keyPassword, value: password);

      await _storage.write(key: _keyIsLoggedIn, value: 'true');

      // التحقق من الحفظ
      final savedUsername = await _storage.read(key: _keyUsername);
      final savedPassword = await _storage.read(key: _keyPassword);
      final isLoggedIn = await _storage.read(key: _keyIsLoggedIn);

      if (savedUsername != username ||
          savedPassword != password ||
          isLoggedIn != 'true') {
        throw Exception('Failed to verify saved data');
      }
    } catch (e) {
      // في حالة الخطأ، حذف أي بيانات محفوظة جزئياً
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyIsLoggedIn);
      rethrow;
    }
  }

  // الحصول على اسم المستخدم المحفوظ
  static Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  // الحصول على كلمة المرور المحفوظة
  static Future<String?> getPassword() async {
    return await _storage.read(key: _keyPassword);
  }

  // التحقق من وجود جلسة تسجيل دخول
  static Future<bool> isLoggedIn() async {
    final isLoggedInValue = await _storage.read(key: _keyIsLoggedIn);
    return isLoggedInValue == 'true';
  }

  // تسجيل الخروج وحذف المعلومات المحفوظة
  static Future<void> logout() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyIsLoggedIn);
    await _storage.delete(key: _keyLastLogin);
    await _storage.delete(key: _keyRememberMe);
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutTime);
  }

  // حفظ تفضيل "تذكرني"
  static Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: _keyRememberMe, value: remember.toString());
  }

  // الحصول على تفضيل "تذكرني"
  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _keyRememberMe);
    return value == 'true';
  }

  // تحديث وقت آخر دخول
  static Future<void> updateLastLogin() async {
    await _storage.write(
      key: _keyLastLogin,
      value: DateTime.now().toIso8601String(),
    );
  }

  // التحقق من صلاحية الجلسة (لم تنته المهلة الزمنية)
  static Future<bool> isSessionValid() async {
    final isLoggedIn = await SessionManager.isLoggedIn();
    if (!isLoggedIn) return false;

    final lastLoginStr = await _storage.read(key: _keyLastLogin);
    if (lastLoginStr == null) return false;

    try {
      final lastLogin = DateTime.parse(lastLoginStr);
      final now = DateTime.now();
      final difference = now.difference(lastLogin);

      return difference < _sessionTimeout;
    } catch (e) {
      return false;
    }
  }

  // تسجيل محاولة فاشلة
  static Future<void> recordFailedAttempt() async {
    final attemptsStr = await _storage.read(key: _keyFailedAttempts);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    final newAttempts = attempts + 1;

    await _storage.write(
      key: _keyFailedAttempts,
      value: newAttempts.toString(),
    );

    // إذا تجاوز الحد الأقصى، قفل الحساب
    if (newAttempts >= _maxFailedAttempts) {
      final lockoutTime = DateTime.now().add(_lockoutDuration);
      await _storage.write(
        key: _keyLockoutTime,
        value: lockoutTime.toIso8601String(),
      );
    }
  }

  // إعادة تعيين محاولات الدخول الفاشلة
  static Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _keyFailedAttempts);
    await _storage.delete(key: _keyLockoutTime);
  }

  // التحقق من حالة القفل
  static Future<LockoutStatus> checkLockoutStatus() async {
    final lockoutTimeStr = await _storage.read(key: _keyLockoutTime);
    if (lockoutTimeStr == null) {
      return LockoutStatus(isLocked: false);
    }

    try {
      final lockoutTime = DateTime.parse(lockoutTimeStr);
      final now = DateTime.now();

      if (now.isAfter(lockoutTime)) {
        // انتهت مدة القفل، إعادة تعيين
        await resetFailedAttempts();
        return LockoutStatus(isLocked: false);
      }

      final remaining = lockoutTime.difference(now);
      return LockoutStatus(
        isLocked: true,
        remainingMinutes: remaining.inMinutes,
      );
    } catch (e) {
      return LockoutStatus(isLocked: false);
    }
  }

  // الحصول على عدد المحاولات الفاشلة
  static Future<int> getFailedAttempts() async {
    final attemptsStr = await _storage.read(key: _keyFailedAttempts);
    return int.tryParse(attemptsStr ?? '0') ?? 0;
  }

  // الحصول على عدد المحاولات المتبقية
  static Future<int> getRemainingAttempts() async {
    final failed = await getFailedAttempts();
    return _maxFailedAttempts - failed;
  }
}

/// حالة القفل
class LockoutStatus {
  final bool isLocked;
  final int remainingMinutes;

  LockoutStatus({required this.isLocked, this.remainingMinutes = 0});

  String get message {
    if (!isLocked) return '';
    return 'Account locked. Try again after $remainingMinutes minute(s).';
  }
}
