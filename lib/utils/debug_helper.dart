import 'package:flutter/foundation.dart';
import '../services/session_manager.dart';

class DebugHelper {
  // دالة لاختبار حفظ البيانات (للاستخدام في التطوير فقط)
  static Future<void> testSaveAndRead() async {
    if (kDebugMode) {
      print('=== بدء اختبار حفظ البيانات ===');

      // اختبار الحفظ
      try {
        await SessionManager.saveLoginInfo('test_user', 'test_password');
        print('✓ تم حفظ البيانات');
      } catch (e) {
        print('✗ فشل في حفظ البيانات: $e');
        return;
      }

      // فوري بدون تأخير - ULTRA FAST

      // اختبار القراءة
      try {
        final username = await SessionManager.getUsername();
        final password = await SessionManager.getPassword();
        final isLoggedIn = await SessionManager.isLoggedIn();

        print('اسم المستخدم المحفوظ: $username');
        print('كلمة المرور المحفوظة: ${password != null ? "***" : "null"}');
        print('حالة تسجيل الدخول: $isLoggedIn');

        if (username == 'test_user' &&
            password == 'test_password' &&
            isLoggedIn) {
          print('✓ تم التحقق من البيانات بنجاح');
        } else {
          print('✗ البيانات المحفوظة لا تطابق البيانات المدخلة');
        }
      } catch (e) {
        print('✗ فشل في قراءة البيانات: $e');
      }

      print('=== انتهاء اختبار حفظ البيانات ===');
    }
  }
}
