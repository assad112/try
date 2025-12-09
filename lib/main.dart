import 'package:flutter/material.dart';
import 'services/session_manager.dart';
import 'services/biometric_service.dart';
import 'screens/login_screen.dart';
import 'screens/webview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق تسجيل الدخول',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA21955),
          primary: const Color(0xFFA21955),
          secondary: const Color(0xFF0099A3),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFA21955),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // انتظار قصير لعرض شاشة البداية
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // ========== التحقق من وجود بيانات دخول محفوظة ==========
    // إذا كانت هناك بيانات محفوظة من تسجيل الدخول الطبيعي السابق
    // سيتم تفعيل البصمة تلقائياً
    final isLoggedIn = await SessionManager.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // ========== تفعيل البصمة تلقائياً ==========
      // إذا كانت هناك بيانات محفوظة، يتم تفعيل البصمة تلقائياً
      // المستخدم لا يحتاج إلى إدخال البيانات مرة أخرى
      await _handleBiometricAuthentication();
    } else {
      // إذا لم تكن هناك بيانات محفوظة، الانتقال إلى صفحة تسجيل الدخول
      // المستخدم يحتاج إلى تسجيل الدخول الطبيعي أولاً
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _handleBiometricAuthentication() async {
    try {
      // ========== تفعيل البصمة تلقائياً ==========
      // عند فتح التطبيق، إذا كانت هناك بيانات محفوظة
      // يتم تفعيل البصمة تلقائياً بدون الحاجة لإدخال البيانات
      final isBiometricAvailable = await BiometricService.isAvailable();

      if (!mounted) return;

      if (isBiometricAvailable) {
        // طلب البصمة/Face ID الحقيقية مباشرة عند فتح التطبيق
        try {
          final result = await BiometricService.authenticate();

          if (!mounted) return;

          if (result.success) {
            // ========== عند نجاح البصمة الحقيقية ==========
            // البيانات محفوظة في الهاتف، والبصمة نجحت
            // الانتقال مباشرة إلى WebView مع تفعيل تعبئة الفورم تلقائياً
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    const WebViewScreen(shouldAutoFill: true),
              ),
            );
          } else {
            // إذا فشلت البصمة أو ألغاها المستخدم
            // العودة إلى صفحة تسجيل الدخول (البيانات لا تزال محفوظة)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } catch (e) {
          // في حالة حدوث خطأ، الانتقال إلى صفحة تسجيل الدخول
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } else {
        // إذا لم تكن البصمة متاحة على الجهاز
        // الانتقال مباشرة إلى WebView (البيانات محفوظة)
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const WebViewScreen(shouldAutoFill: false),
            ),
          );
        }
      }
    } catch (e) {
      // في حالة حدوث خطأ عام، الانتقال إلى صفحة تسجيل الدخول
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة logo.png
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // نص "Jeel ERP"
            const Text(
              'Jeel ERP',
              style: TextStyle(
                color: Color(0xFFA21955),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // مؤشر التحميل الدائري
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFA21955),
                ),
                backgroundColor: const Color(0xFF0099A3).withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
