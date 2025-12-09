# تطبيق Jeel ERP - تسجيل الدخول بالبصمة

تطبيق Flutter لتسجيل الدخول مع دعم البصمة/Face ID والتحقق الآمن.

## المميزات

- ✅ تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
- ✅ **البصمة/Face ID** - التحقق البيومتري الحقيقي عند فتح التطبيق
- ✅ حفظ آمن للبيانات باستخدام `flutter_secure_storage`
- ✅ WebView لعرض موقع ERP
- ✅ تعبئة تلقائية لنموذج تسجيل الدخول في WebView
- ✅ تصميم عصري بألوان مخصصة

## المكتبات المستخدمة

### 1. **local_auth: ^2.3.0** - البصمة/Face ID
```yaml
local_auth: ^2.3.0
```
- **الوظيفة**: التحقق البيومتري (البصمة/Face ID)
- **الاستخدام**: 
  - عند فتح التطبيق لأول مرة (إذا كانت هناك جلسة محفوظة)
  - في صفحة تسجيل الدخول
- **الصلاحيات المطلوبة**:
  - Android: `USE_BIOMETRIC`, `USE_FINGERPRINT`
  - iOS: `NSFaceIDUsageDescription`
- **الموقع**: https://pub.dev/packages/local_auth

### 2. **flutter_secure_storage: ^9.2.4** - التخزين الآمن
```yaml
flutter_secure_storage: ^9.2.4
```
- **الوظيفة**: حفظ بيانات تسجيل الدخول بشكل آمن
- **الميزات**:
  - تشفير البيانات على Android و iOS
  - استخدام Keychain على iOS
  - استخدام EncryptedSharedPreferences على Android
- **الموقع**: https://pub.dev/packages/flutter_secure_storage

### 3. **webview_flutter: ^4.9.0** - عرض الويب
```yaml
webview_flutter: ^4.9.0
```
- **الوظيفة**: عرض موقع ERP في التطبيق
- **الميزات**:
  - تعبئة تلقائية لنموذج تسجيل الدخول
  - دعم JavaScript
- **الموقع**: https://pub.dev/packages/webview_flutter

### 4. **loading_animation_widget: ^1.3.0** - الرسوم المتحركة
```yaml
loading_animation_widget: ^1.3.0
```
- **الوظيفة**: رسوم متحركة للتحميل
- **الاستخدام**: `discreteCircle` بألوان مخصصة
- **الموقع**: https://pub.dev/packages/loading_animation_widget

## كيفية عمل البصمة/Face ID

### عند فتح التطبيق:
1. يتم التحقق من وجود جلسة محفوظة
2. إذا كانت موجودة، يتم طلب البصمة/Face ID **مباشرة**
3. عند النجاح: الانتقال إلى WebView
4. عند الفشل: الانتقال إلى صفحة تسجيل الدخول

### في صفحة تسجيل الدخول:
1. زر البصمة يظهر تلقائياً إذا كانت متاحة
2. عند الضغط: طلب البصمة/Face ID
3. عند النجاح: تعبئة البيانات تلقائياً والانتقال إلى WebView

## الإعدادات المطلوبة

### Android:
- **minSdk**: 23 (للدعم الكامل للبصمة)
- **الصلاحيات**:
  ```xml
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
  ```

### iOS:
- **الوصف المطلوب**:
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>نحتاج إلى Face ID للتحقق من هويتك وتسجيل الدخول بشكل آمن</string>
  ```

## التثبيت

```bash
# تثبيت المكتبات
flutter pub get

# تشغيل التطبيق
flutter run
```

## البنية البرمجية

```
lib/
├── main.dart                    # نقطة البداية + SplashScreen
├── screens/
│   ├── login_screen.dart        # صفحة تسجيل الدخول
│   └── webview_screen.dart      # صفحة WebView
└── services/
    ├── biometric_service.dart   # خدمة البصمة/Face ID
    └── session_manager.dart     # إدارة الجلسة
```

## الألوان المستخدمة

- **Primary (Magenta)**: `#A21955`
- **Secondary (Teal)**: `#0099A3`

## الموقع المستهدف

- **URL**: https://erp.jeel.om/

## الترخيص

Copyright © Jeel
