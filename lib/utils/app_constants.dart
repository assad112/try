import 'package:flutter/material.dart';

/// ثوابت التطبيق
class AppConstants {
  // الألوان
  static const Color primaryColor = Color(0xFFA21955);
  static const Color secondaryColor = Color(0xFF0099A3);
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color successColor = Colors.green;

  // أحجام النصوص
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;

  // المسافات
  static const double paddingSmall = 8.0;
  static const double paddingNormal = 16.0;
  static const double paddingLarge = 24.0;

  // أحجام الحدود
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusNormal = 8.0;
  static const double borderRadiusLarge = 12.0;

  // مدة الرسوم المتحركة
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration snackBarLongDuration = Duration(seconds: 5);

  // URL الافتراضي للـ WebView
  static const String defaultWebViewUrl = 'https://erp.jeel.com.sa/';

  // رسائل عامة
  static const String appTitle = 'Jeel ERP';
  static const String loadingMessage = 'جارٍ التحميل...';
  static const String errorGeneric = 'حدث خطأ غير متوقع';
  static const String networkError = 'تحقق من اتصال الإنترنت';
  static const String tryAgainLater = 'حاول مرة أخرى لاحقاً';
}

/// أنماط النصوص
class AppTextStyles {
  static const TextStyle titleLarge = TextStyle(
    fontSize: AppConstants.fontSizeXLarge,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle bodyNormal = TextStyle(
    fontSize: AppConstants.fontSizeNormal,
    color: Colors.black87,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppConstants.fontSizeSmall,
    color: Colors.black54,
  );

  static TextStyle errorText = TextStyle(
    fontSize: AppConstants.fontSizeSmall,
    color: AppConstants.errorColor,
  );
}

/// زخارف الإدخال
class AppInputDecorations {
  static InputDecoration getInputDecoration({
    required String hint,
    String? label,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: Colors.grey),
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        borderSide: const BorderSide(
          color: AppConstants.secondaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        borderSide: const BorderSide(color: AppConstants.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
        borderSide: const BorderSide(color: AppConstants.errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingNormal,
        vertical: AppConstants.paddingNormal,
      ),
    );
  }
}
