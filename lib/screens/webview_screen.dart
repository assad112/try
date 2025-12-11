import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../services/session_manager.dart';
import '../services/biometric_service.dart';
import '../utils/app_logger.dart';
import 'login_screen.dart';

class WebViewScreen extends StatefulWidget {
  final bool shouldAutoFill;

  const WebViewScreen({super.key, this.shouldAutoFill = false});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _username;
  String? _password;
  bool _hasAutoFilled = false;
  int _autoFillAttempts = 0;
  static const int _maxAutoFillAttempts = 3;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final username = await SessionManager.getUsername();
    final password = await SessionManager.getPassword();
    setState(() {
      _username = username;
      _password = password;
    });

    // إذا كانت هناك بيانات محفوظة، نفعّل التعبئة التلقائية دائماً
    if (username != null && password != null && !widget.shouldAutoFill) {
      // تعبئة فورية بدون تأخير - INSTANT
      if (mounted && !_hasAutoFilled) {
        _autoFillFormWithRetry();
      }
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false) // Disable zoom for faster rendering
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // إذا كانت هناك بيانات محفوظة، نبقي شاشة التحميل لإخفاء صفحة تسجيل الدخول
            if (_username != null && _password != null && !_hasAutoFilled) {
              // نبقي شاشة التحميل ونحاول التعبئة التلقائية فوراً
              if (mounted && !_hasAutoFilled) {
                _autoFillAndLoginInBackground();
              }
            } else if (_hasAutoFilled) {
              // تم تسجيل الدخول - نخفي شاشة التحميل
              setState(() {
                _isLoading = false;
              });
            }
          },
          onProgress: (int progress) {
            // إبقاء شاشة التحميل إذا كانت هناك بيانات محفوظة
            if (progress == 100 &&
                _username != null &&
                _password != null &&
                !_hasAutoFilled) {
              // محاولة التعبئة فوراً
              if (mounted && !_hasAutoFilled) {
                _autoFillAndLoginInBackground();
              }
            }
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://erp.jeel.om/'));
  }

  // دالة جديدة لتسجيل الدخول في الخلفية دون إظهار صفحة تسجيل الدخول
  Future<void> _autoFillAndLoginInBackground() async {
    if (_username == null || _password == null || _hasAutoFilled) return;

    // Check max attempts
    if (_autoFillAttempts >= _maxAutoFillAttempts) {
      // تجاوزنا عدد المحاولات - نبقي شاشة التحميل لأنها أفضل من إظهار صفحة تسجيل الدخول
      return;
    }

    _autoFillAttempts++;

    // Escape القيم بشكل آمن
    final escapedUsername = _username!
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    final escapedPassword = _password!
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');

    // JavaScript لتعبئة وتسجيل الدخول تلقائياً في الخلفية
    final jsCode =
        '''
      (function() {
        try {
          var username = '$escapedUsername';
          var password = '$escapedPassword';
          var usernameFilled = false;
          var passwordFilled = false;
          
          // البحث عن حقول تسجيل الدخول
          var allInputs = document.querySelectorAll('input');
          
          for (var i = 0; i < allInputs.length; i++) {
            var input = allInputs[i];
            var type = (input.type || '').toLowerCase();
            var name = (input.name || '').toLowerCase();
            var id = (input.id || '').toLowerCase();
            var placeholder = (input.placeholder || '').toLowerCase();
            
            // حقل اسم المستخدم/الإيميل
            if (!usernameFilled && (type === 'text' || type === 'email')) {
              var isEmailField = 
                name.includes('email') || name.includes('user') || name.includes('login') ||
                id.includes('email') || id.includes('user') || id.includes('login') ||
                placeholder.includes('email') || placeholder.includes('user') || placeholder.includes('login');
              
              if (isEmailField || i === 0) {
                input.value = username;
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
                usernameFilled = true;
              }
            }
            
            // حقل كلمة المرور
            if (!passwordFilled && type === 'password') {
              input.value = password;
              input.dispatchEvent(new Event('input', { bubbles: true }));
              input.dispatchEvent(new Event('change', { bubbles: true }));
              passwordFilled = true;
            }
            
            if (usernameFilled && passwordFilled) break;
          }
          
          // إذا تم ملء الحقول، اضغط على زر تسجيل الدخول فوراً
          if (usernameFilled && passwordFilled) {
            setTimeout(function() {
              var buttons = document.querySelectorAll('button, input[type="submit"]');
              
              for (var i = 0; i < buttons.length; i++) {
                var btn = buttons[i];
                var text = (btn.textContent || btn.innerText || btn.value || '').toLowerCase();
                
                if (text.includes('log in') || text.includes('login') || text.includes('sign in') || text.includes('submit')) {
                  btn.click();
                  return true;
                }
              }
              
              // إذا لم نجد زر، نرسل الفورم
              var forms = document.querySelectorAll('form');
              if (forms.length > 0) {
                forms[0].submit();
              }
              return true;
            }, 50);
          }
          
          return usernameFilled && passwordFilled;
        } catch (e) {
          return false;
        }
      })();
    ''';

    try {
      final result = await _controller.runJavaScriptReturningResult(jsCode);

      if (result.toString() == 'true') {
        setState(() {
          _hasAutoFilled = true;
        });

        // فوري بدون تأخير - ULTRA FAST

        // Hide loading indicator
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // فوري بدون تأخير - INSTANT RETRY
        if (mounted && !_hasAutoFilled) {
          _autoFillAndLoginInBackground();
        }
      }
    } catch (e) {
      // فوري بدون تأخير - INSTANT RETRY
      if (mounted && !_hasAutoFilled) {
        _autoFillAndLoginInBackground();
      }
    }
  }

  // دالة محسّنة مع محاولات متعددة وضغط زر Log in تلقائياً
  Future<void> _autoFillFormWithRetry({int retryCount = 0}) async {
    if (_username == null || _password == null) return;

    const maxRetries = 5;
    if (retryCount >= maxRetries || _hasAutoFilled) return;

    // Escape القيم بشكل أفضل
    final escapedUsername = _username!
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    final escapedPassword = _password!
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');

    // JavaScript محسّن لتعبئة الفورم وضغط زر تسجيل الدخول تلقائياً
    final jsCode =
        '''
      (function() {
        try {
          var usernameFilled = false;
          var passwordFilled = false;
          var username = '$escapedUsername';
          var password = '$escapedPassword';
          
          // البحث عن جميع الحقول
          var allInputs = document.querySelectorAll('input');
          
          for (var i = 0; i < allInputs.length; i++) {
            var input = allInputs[i];
            var type = (input.type || '').toLowerCase();
            var name = (input.name || '').toLowerCase();
            var id = (input.id || '').toLowerCase();
            var placeholder = (input.placeholder || '').toLowerCase();
            var className = (input.className || '').toLowerCase();
            var autocomplete = (input.autocomplete || '').toLowerCase();
            
            // البحث عن حقل اسم المستخدم/الإيميل
            if (!usernameFilled && (type === 'text' || type === 'email')) {
              var isEmailField = 
                name.includes('email') || name.includes('user') || name.includes('login') || name.includes('username') ||
                id.includes('email') || id.includes('user') || id.includes('login') || id.includes('username') ||
                placeholder.includes('email') || placeholder.includes('user') || placeholder.includes('login') ||
                className.includes('email') || className.includes('user') || className.includes('login') ||
                autocomplete.includes('email') || autocomplete.includes('username');
              
              if (isEmailField || (i === 0 && type === 'text')) {
                input.value = username;
                input.setAttribute('value', username);
                input.dispatchEvent(new Event('input', { bubbles: true, cancelable: true }));
                input.dispatchEvent(new Event('change', { bubbles: true, cancelable: true }));
                input.dispatchEvent(new Event('keyup', { bubbles: true, cancelable: true }));
                input.dispatchEvent(new Event('keydown', { bubbles: true, cancelable: true }));
                input.focus();
                setTimeout(function() { input.blur(); }, 100);
                usernameFilled = true;
              }
            }
            
            // البحث عن حقل كلمة المرور
            if (!passwordFilled && type === 'password') {
              input.value = password;
              input.setAttribute('value', password);
              input.dispatchEvent(new Event('input', { bubbles: true, cancelable: true }));
              input.dispatchEvent(new Event('change', { bubbles: true, cancelable: true }));
              input.dispatchEvent(new Event('keyup', { bubbles: true, cancelable: true }));
              input.dispatchEvent(new Event('keydown', { bubbles: true, cancelable: true }));
              passwordFilled = true;
            }
            
            if (usernameFilled && passwordFilled) break;
          }
          
          // إذا لم نجد الحقول بالطريقة العادية، نبحث في جميع الحقول النصية
          if (!usernameFilled) {
            var textInputs = document.querySelectorAll('input[type="text"], input[type="email"]');
            if (textInputs.length > 0) {
              var firstTextInput = textInputs[0];
              firstTextInput.value = username;
              firstTextInput.setAttribute('value', username);
              firstTextInput.dispatchEvent(new Event('input', { bubbles: true, cancelable: true }));
              firstTextInput.dispatchEvent(new Event('change', { bubbles: true, cancelable: true }));
              usernameFilled = true;
            }
          }
          
          // إذا تم تعبئة الحقول، نضغط على زر تسجيل الدخول تلقائياً
          if (usernameFilled && passwordFilled) {
            setTimeout(function() {
              // البحث عن زر تسجيل الدخول
              var buttons = document.querySelectorAll('button, input[type="submit"], a.btn, .btn, [role="button"]');
              var loginButton = null;
              
              for (var i = 0; i < buttons.length; i++) {
                var btn = buttons[i];
                var text = (btn.textContent || btn.innerText || btn.value || '').toLowerCase();
                var className = (btn.className || '').toLowerCase();
                var id = (btn.id || '').toLowerCase();
                var name = (btn.name || '').toLowerCase();
                
                if (text.includes('log in') || text.includes('login') || text.includes('sign in') || 
                    text.includes('submit') || text.includes('enter') || text.includes('تسجيل') ||
                    className.includes('login') || className.includes('submit') ||
                    id.includes('login') || id.includes('submit') ||
                    name.includes('login') || name.includes('submit')) {
                  loginButton = btn;
                  break;
                }
              }
              
              if (loginButton) {
                loginButton.click();
                return true;
              }
              
              // إذا لم نجد زر، نحاول إرسال الفورم مباشرة
              var forms = document.querySelectorAll('form');
              if (forms.length > 0) {
                forms[0].submit();
                return true;
              }
            }, 500);
          }
          
          return usernameFilled && passwordFilled;
        } catch (e) {
          console.error('Auto-fill error: ' + e);
          return false;
        }
      })();
    ''';

    try {
      final result = await _controller.runJavaScriptReturningResult(jsCode);

      // إذا نجحت العملية
      if (result.toString() == 'true') {
        setState(() {
          _hasAutoFilled = true;
        });
        return;
      }

      // إذا فشلت، نحاول مرة أخرى بعد تأخير
      if (retryCount < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 50 + (retryCount * 20)));
        await _autoFillFormWithRetry(retryCount: retryCount + 1);
      } else {
        // محاولة أخيرة بالطريقة البديلة
        await _tryAlternativeAutoFill();
      }
    } catch (e) {
      // في حالة الخطأ، نحاول مرة أخرى
      if (retryCount < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 50 + (retryCount * 20)));
        await _autoFillFormWithRetry(retryCount: retryCount + 1);
      } else {
        await _tryAlternativeAutoFill();
      }
    }
  }

  Future<void> _tryAlternativeAutoFill() async {
    if (_username == null || _password == null || _hasAutoFilled) return;

    // Escape القيم بشكل أفضل
    final escapedUsername = _username!
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
    final escapedPassword = _password!
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');

    // طريقة بديلة: البحث في جميع الحقول
    final alternativeJs =
        '''
      (function() {
        try {
          var inputs = document.querySelectorAll('input');
          var usernameFilled = false;
          var passwordFilled = false;
          
          for (var i = 0; i < inputs.length; i++) {
            var input = inputs[i];
            var type = (input.type || '').toLowerCase();
            var name = (input.name || '').toLowerCase();
            var id = (input.id || '').toLowerCase();
            var placeholder = (input.placeholder || '').toLowerCase();
            var className = (input.className || '').toLowerCase();
            
            // البحث عن حقل اسم المستخدم (أول حقل نصي غير كلمة مرور)
            if (!usernameFilled && (type === 'text' || type === 'email')) {
              if (name.includes('user') || name.includes('email') || name.includes('login') || 
                  id.includes('user') || id.includes('email') || id.includes('login') ||
                  placeholder.includes('email') || placeholder.includes('user') ||
                  className.includes('email') || className.includes('user') || className.includes('login') ||
                  (i === 0 && type === 'text')) {
                input.value = '$escapedUsername';
                input.dispatchEvent(new Event('input', { bubbles: true }));
                input.dispatchEvent(new Event('change', { bubbles: true }));
                input.dispatchEvent(new Event('blur', { bubbles: true }));
                input.focus();
                usernameFilled = true;
              }
            }
            
            // البحث عن حقل كلمة المرور
            if (!passwordFilled && type === 'password') {
              input.value = '$escapedPassword';
              input.dispatchEvent(new Event('input', { bubbles: true }));
              input.dispatchEvent(new Event('change', { bubbles: true }));
              input.dispatchEvent(new Event('blur', { bubbles: true }));
              passwordFilled = true;
            }
            
            if (usernameFilled && passwordFilled) break;
          }
          
          return usernameFilled && passwordFilled;
        } catch (e) {
          return false;
        }
      })();
    ''';

    try {
      final result = await _controller.runJavaScriptReturningResult(
        alternativeJs,
      );
      if (result.toString() == 'true') {
        setState(() {
          _hasAutoFilled = true;
        });
      }
    } catch (e) {
      // في حالة الفشل، لا نفعل شيء
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm logout'),
        content: const Text('Do you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final username = _username;
      AppLogger.logLogout(username);
      await SessionManager.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      await _controller.clearCache();
      await _controller.clearLocalStorage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // إعادة تحميل الصفحة
        await _controller.reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSettings() async {
    // التحقق من حالة البصمة
    final biometricAvailable = await BiometricService.isAvailable();
    final biometricTypes = await BiometricService.getAvailableBiometrics();
    final rememberMe = await SessionManager.getRememberMe();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Color(0xFFA21955)),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFF0099A3)),
                  title: const Text('App Version'),
                  subtitle: const Text('1.7.2 - Hidden Login Page'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF0099A3)),
                  title: const Text('Logged in as'),
                  subtitle: Text(_username ?? 'Unknown'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.web, color: Color(0xFF0099A3)),
                  title: const Text('Website'),
                  subtitle: const Text('erp.jeel.om'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Biometric Authentication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA21955),
                      ),
                    ),
                    if (biometricAvailable)
                      IconButton(
                        icon: const Icon(Icons.verified_user, color: Color(0xFF0099A3)),
                        tooltip: 'Test Biometric',
                        onPressed: () async {
                          Navigator.pop(context);
                          await _testBiometric();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(
                    Icons.fingerprint,
                    color: biometricAvailable ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  title: const Text('Biometric Status'),
                  subtitle: Text(
                    biometricAvailable ? 'Available & Enabled ✓' : 'Disabled or Not Available ✗',
                    style: TextStyle(
                      color: biometricAvailable ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (biometricTypes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Available Biometric Types:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...biometricTypes.map((type) => Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Row(
                            children: [
                              Icon(
                                _getBiometricIcon(type),
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getBiometricName(type),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  value: rememberMe,
                  onChanged: (value) async {
                    await SessionManager.setRememberMe(value);
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                value ? Icons.check_circle : Icons.info,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  value
                                      ? 'Biometric auto-login enabled ✓'
                                      : 'Manual login required each time',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: value ? Colors.green : Colors.orange,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  title: const Text('Auto-Login with Biometrics'),
                  subtitle: Text(
                    rememberMe
                        ? 'Enabled - Login automatically on app start'
                        : 'Disabled - Enter credentials manually',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  activeColor: const Color(0xFF0099A3),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!biometricAvailable) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enable fingerprint or face unlock on your device to use biometric authentication',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (biometricAvailable)
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _testBiometric();
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Test'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBiometricIcon(dynamic type) {
    final typeStr = type.toString().toLowerCase();
    if (typeStr.contains('face')) return Icons.face;
    if (typeStr.contains('fingerprint')) return Icons.fingerprint;
    if (typeStr.contains('iris')) return Icons.visibility;
    return Icons.security;
  }

  String _getBiometricName(dynamic type) {
    final typeStr = type.toString().toLowerCase();
    if (typeStr.contains('face')) return 'Face Recognition';
    if (typeStr.contains('fingerprint')) return 'Fingerprint';
    if (typeStr.contains('iris')) return 'Iris Scanner';
    if (typeStr.contains('strong')) return 'Strong Biometric';
    if (typeStr.contains('weak')) return 'Weak Biometric';
    return type.toString().split('.').last;
  }

  Future<void> _testBiometric() async {
    try {
      final result = await BiometricService.authenticate();
      
      if (!mounted) return;
      
      if (result.success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 12),
                const Text('Success!'),
              ],
            ),
            content: const Text(
              'Biometric authentication successful! Your biometric sensor is working correctly.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 12),
                const Text('Failed'),
              ],
            ),
            content: Text(
              result.message ?? 'Biometric authentication failed. Please try again.',
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
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing biometric: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeel ERP'),
        centerTitle: true,
        backgroundColor: const Color(0xFFA21955),
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFA21955), // نفس لون AppBar
          statusBarIconBrightness: Brightness.light, // أيقونات بيضاء
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'clear_cache') {
                _clearCache();
              } else if (value == 'settings') {
                _showSettings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Clear Cache'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: const Color(0xFFA21955),
                  size: 60,
                  secondRingColor: const Color(0xFF0099A3),
                  thirdRingColor: Colors.white,
                ),
              ),
            ),
          // زر لتعبئة الفورم يدوياً (للاستخدام في حالة فشل التعبئة التلقائية)
          if (!_isLoading &&
              _username != null &&
              _password != null &&
              !_hasAutoFilled)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  _autoFillFormWithRetry();
                },
                backgroundColor: const Color(0xFFA21955),
                tooltip: 'Fill form',
                child: const Icon(Icons.auto_fix_high, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
