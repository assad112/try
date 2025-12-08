import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage(
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

  // حفظ معلومات تسجيل الدخول
  static Future<void> saveLoginInfo(String username, String password) async {
    try {
      // التأكد من أن القيم غير فارغة
      if (username.isEmpty || password.isEmpty) {
        throw Exception('اسم المستخدم وكلمة المرور مطلوبان');
      }

      // حفظ البيانات بشكل متسلسل للتأكد من الحفظ
      await _storage.write(key: _keyUsername, value: username);
      await Future.delayed(const Duration(milliseconds: 100));
      
      await _storage.write(key: _keyPassword, value: password);
      await Future.delayed(const Duration(milliseconds: 100));
      
      await _storage.write(key: _keyIsLoggedIn, value: 'true');
      await Future.delayed(const Duration(milliseconds: 100));

      // التحقق من الحفظ
      final savedUsername = await _storage.read(key: _keyUsername);
      final savedPassword = await _storage.read(key: _keyPassword);
      final isLoggedIn = await _storage.read(key: _keyIsLoggedIn);

      if (savedUsername != username || savedPassword != password || isLoggedIn != 'true') {
        throw Exception('فشل التحقق من حفظ البيانات');
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
  }
}

