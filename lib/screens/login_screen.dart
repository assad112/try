import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../services/session_manager.dart';
import '../services/biometric_service.dart';
import '../utils/validators.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';
import 'webview_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _initialSetup();
  }

  /// Initial setup:
  /// 1) Check biometric availability
  /// 2) Check session validity
  /// 3) If valid session + biometric available → trigger biometric automatically
  /// Note: Data is filled only after successful biometric verification
  Future<void> _initialSetup() async {
    await _checkBiometricAvailability();
    
    // Load "Remember Me" preference
    final rememberMe = await SessionManager.getRememberMe();
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
      });
    }

    // Check session validity
    final isSessionValid = await SessionManager.isSessionValid();

    if (mounted && isSessionValid && _isBiometricAvailable && _rememberMe) {
      await _handleBiometricLogin();
    } else if (isSessionValid == false) {
      // Session expired, logout
      await SessionManager.logout();
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await BiometricService.isAvailable();
    if (!mounted) return;
    setState(() {
      _isBiometricAvailable = isAvailable;
    });
  }

  // This function was removed - data is now filled only after successful biometric verification
  // Future<void> _loadSavedCredentials() async {
  //   final username = await SessionManager.getUsername();
  //   final password = await SessionManager.getPassword();
  //
  //   if (!mounted) return;
  //
  //   if (username != null && password != null) {
  //     setState(() {
  //       _emailController.text = username;
  //       _passwordController.text = password;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Check lockout status
    final lockoutStatus = await SessionManager.checkLockoutStatus();
    if (lockoutStatus.isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lockoutStatus.message),
            backgroundColor: AppConstants.errorColor,
            duration: AppConstants.snackBarLongDuration,
          ),
        );
      }
      return;
    }
    
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate data
    final emailError = Validators.validateEmail(email);
    final passwordError = Validators.validatePassword(password);
    
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.info('Starting login process', email);
      
      // حفظ تفضيل "تذكرني"
      await SessionManager.setRememberMe(_rememberMe);
      
      // حفظ بيانات الدخول في التخزين الآمن (إذا كان تضكرني مفعل)
      if (_rememberMe) {
        await SessionManager.saveLoginInfo(email, password);
        await SessionManager.updateLastLogin();
      }
      
      await Future.delayed(const Duration(milliseconds: 200));

      final savedUsername = await SessionManager.getUsername();
      final savedPassword = await SessionManager.getPassword();
      final isLoggedIn = await SessionManager.isLoggedIn();

      if ((_rememberMe && savedUsername == email && savedPassword == password && isLoggedIn) || !_rememberMe) {
        // إعادة تعيين المحاولات الفاشلة عند النجاح
        await SessionManager.resetFailedAttempts();
        AppLogger.logLoginAttempt(email, true);
        
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // الانتقال إلى الـ WebView بدون تعبئة تلقائية (تسجيل دخول عادي)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WebViewScreen(shouldAutoFill: false),
          ),
        );
      } else {
        throw Exception('Failed to save data');
      }
    } catch (e) {
      // تسجيل محاولة فاشلة
      await SessionManager.recordFailedAttempt();
      AppLogger.logLoginAttempt(email, false);
      AppLogger.error('Login failed', e);
      
      final remaining = await SessionManager.getRemainingAttempts();
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'An error occurred: $e';
      if (remaining > 0 && remaining <= 3) {
        errorMessage += '\nRemaining attempts: $remaining';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppConstants.errorColor,
          duration: AppConstants.snackBarLongDuration,
        ),
      );
    }
  }

  /// دليل إرشادي لتفعيل البصمة
  void _showBiometricSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Enable biometrics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To use biometrics for login, follow these steps:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildGuideStep('1', 'Open phone settings'),
              _buildGuideStep('2', 'Choose "Security" or "Lock & security"'),
              _buildGuideStep('3', 'Enable a screen lock (pattern/PIN/password)'),
              _buildGuideStep('4', 'Register your fingerprint/Face ID'),
              _buildGuideStep('5', 'Reopen the app; the biometric button appears'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biometrics used here are the same as your device screen lock',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0099A3),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    final isLoggedIn = await SessionManager.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved credentials. Please log in first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final isBiometricAvailable = await BiometricService.isAvailable();
    if (!isBiometricAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Biometrics are unavailable. Please enable them in device settings.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isBiometricLoading = true;
      });
    }

    try {
      AppLogger.info('Attempting biometric authentication');
      final result = await BiometricService.authenticate();

      if (!result.success) {
        AppLogger.logBiometricAttempt(false);
        if (!mounted) return;
        setState(() {
          _isBiometricLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  'Biometric verification failed. Please try again or use normal login.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // إذا كان المستشعر مقفلاً نهائياً أو مؤقتاً، أوقف زر البصمة حتى لا يضلل المستخدم
        if (result.code == auth_error.permanentlyLockedOut ||
            result.code == auth_error.lockedOut) {
          setState(() {
            _isBiometricAvailable = false;
          });
        }
        return;
      }

      // عند نجاح البصمة
      AppLogger.logBiometricAttempt(true);
      final username = await SessionManager.getUsername();
      final password = await SessionManager.getPassword();

      if (!mounted) return;

      if (username == null || password == null) {
        setState(() {
          _isBiometricLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved credentials found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // تحديث آخر دخول
      await SessionManager.updateLastLogin();

      // تسجيل دخول تلقائي بعد نجاح البصمة
      setState(() {
        _emailController.text = username;
        _passwordController.text = password;
      });

      // محاكاة الضغط على زر Log in تلقائياً
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        await _handleLoginAfterBiometric(username, password);
      }
    } catch (e) {
      AppLogger.error('Biometric verification error', e);
      if (!mounted) return;
      setState(() {
        _isBiometricLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An error occurred during biometric verification. You can use "Log in" instead.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// دالة تسجيل الدخول التلقائي بعد نجاح البصمة
  Future<void> _handleLoginAfterBiometric(String email, String password) async {
    setState(() {
      _isLoading = true;
      _isBiometricLoading = false;
    });

    try {
      AppLogger.info('Automatic login after biometrics', email);
      
      // حفظ البيانات (تم حفظها مسبقاً، لكن للتأكد)
      await SessionManager.saveLoginInfo(email, password);
      await SessionManager.updateLastLogin();
      await SessionManager.resetFailedAttempts();
      
      AppLogger.logLoginAttempt(email, true);
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // الانتقال إلى WebView مع تفعيل تعبئة الفورم تلقائياً
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WebViewScreen(shouldAutoFill: true),
        ),
      );
    } catch (e) {
      await SessionManager.recordFailedAttempt();
      AppLogger.logLoginAttempt(email, false);
      AppLogger.error('Automatic login failed', e);
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isBiometricLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto login error: $e'),
          backgroundColor: AppConstants.errorColor,
          duration: AppConstants.snackBarLongDuration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // شريط علوي Magenta مع "Jeel ERP"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFA21955),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Jeel ERP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // BiometricChecker dialog hidden
                        // BiometricChecker.showBiometricDialog(context);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // صورة JeeEngineering.png ملاصقة للـ AppBar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/JeeEngineering.png',
                    height: 40,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      return Container(
                        height: 40,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // محتوى الصفحة
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // تنبيه البصمة
                    if (!_isBiometricAvailable)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.fingerprint_outlined, color: Colors.orange.shade700, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biometrics are disabled',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'For faster and more secure login, enable biometrics on your device.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.help_outline, color: Colors.orange.shade700),
                              onPressed: _showBiometricSetupGuide,
                              tooltip: 'How to enable biometrics?',
                            ),
                          ],
                        ),
                      ),

                    if (_isBiometricAvailable)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Biometrics enabled ✓ You can use the biometric button below for quick login.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // حقل Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _emailError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _emailError != null ? AppConstants.errorColor : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0099A3),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // حقل Password + Reset Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Reset Password',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _passwordError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _passwordError != null ? AppConstants.errorColor : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0099A3),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    // خيار "تذكرني"
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                          activeColor: AppConstants.secondaryColor,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: const Text(
                            'Remember me and use biometrics',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // زر Log in
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA21955),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? LoadingAnimationWidget.discreteCircle(
                                color: Colors.white,
                                size: 24,
                                secondRingColor: const Color(0xFFA21955),
                                thirdRingColor: const Color(0xFF0099A3),
                              )
                            : const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // أيقونة البصمة
                    if (_isBiometricAvailable) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: GestureDetector(
                          onTap: _isBiometricLoading
                              ? null
                              : _handleBiometricLogin,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0099A3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0099A3,
                                  ).withOpacity(0.3), // ← تم التعديل هنا
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: _isBiometricLoading
                                ? Center(
                                    child:
                                        LoadingAnimationWidget.discreteCircle(
                                          color: Colors.white,
                                          size: 30,
                                          secondRingColor: const Color(
                                            0xFF0099A3,
                                          ),
                                          thirdRingColor: Colors.white,
                                        ),
                                  )
                                : const Icon(
                                    Icons.fingerprint,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
