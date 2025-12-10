/// أدوات التحقق من صحة البيانات
class Validators {
  /// التحقق من البريد الإلكتروني
  static String? validateEmail(String? value) {
    // بناءً على طلب المستخدم: عدم وضع أي شروط، قبول أي قيمة
    return null;
  }

  /// التحقق من كلمة المرور
  static String? validatePassword(String? value) {
    // بناءً على طلب المستخدم: عدم وضع أي شروط، قبول أي قيمة
    return null;
  }

  /// التحقق من قوة كلمة المرور (للتسجيل الجديد)
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    int strength = 0;

    // الطول
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // أحرف كبيرة
    if (password.contains(RegExp(r'[A-Z]'))) strength++;

    // أحرف صغيرة
    if (password.contains(RegExp(r'[a-z]'))) strength++;

    // أرقام
    if (password.contains(RegExp(r'[0-9]'))) strength++;

    // رموز خاصة
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// رسالة قوة كلمة المرور
  static String getPasswordStrengthMessage(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'ضعيفة - استخدم أحرف كبيرة وصغيرة وأرقام';
      case PasswordStrength.medium:
        return 'متوسطة - أضف رموز خاصة لتحسين الأمان';
      case PasswordStrength.strong:
        return 'قوية ✓';
    }
  }

  /// لون مؤشر قوة كلمة المرور
  static int getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return 0xFF9E9E9E; // رمادي
      case PasswordStrength.weak:
        return 0xFFF44336; // أحمر
      case PasswordStrength.medium:
        return 0xFFFF9800; // برتقالي
      case PasswordStrength.strong:
        return 0xFF4CAF50; // أخضر
    }
  }
}

/// مستويات قوة كلمة المرور
enum PasswordStrength { empty, weak, medium, strong }
