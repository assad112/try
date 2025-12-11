import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadCredentials();
    _startLoadingTimeout(); // مؤقت لإخفاء شاشة التحميل
  }

  // مؤقت لإخفاء شاشة التحميل بعد 1 ثانية - يعمل حتى بدون بيانات محفوظة
  void _startLoadingTimeout() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
      // تعبئة فورية - بدون تأخير
      if (mounted && !_hasAutoFilled) {
        _autoFillFormWithRetry();
      }
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasAutoFilled = false;
            });
          },
          onPageFinished: (String url) {
            // لا نخفي شاشة التحميل فوراً - نتركها للـ timeout
            // هذا يضمن عدم ظهور صفحة تسجيل الدخول
            // تعبئة الفورم تلقائياً بعد تحميل الصفحة
            // محاولات سريعة جداً
            if (_username != null && _password != null) {
              // محاولة متعددة فورية
              Future.delayed(const Duration(milliseconds: 10), () {
                if (mounted && !_hasAutoFilled) {
                  _autoFillFormWithRetry();
                }
              });
              Future.delayed(const Duration(milliseconds: 20), () {
                if (mounted && !_hasAutoFilled) {
                  _autoFillFormWithRetry();
                }
              });
              Future.delayed(const Duration(milliseconds: 30), () {
                if (mounted && !_hasAutoFilled) {
                  _autoFillFormWithRetry();
                }
              });
            }
          },
          onProgress: (int progress) {
            // محاولة تعبئة الفورم عند 100% من التحميل
            if (progress == 100 && _username != null && _password != null) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted && !_hasAutoFilled) {
                  _autoFillFormWithRetry();
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://erp.jeel.om/'));
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

      // إذا فشلت، نحاول مرة أخرى فوراً
      if (retryCount < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 20 + (retryCount * 10)));
        await _autoFillFormWithRetry(retryCount: retryCount + 1);
      } else {
        // محاولة أخيرة بالطريقة البديلة
        await _tryAlternativeAutoFill();
      }
    } catch (e) {
      // في حالة الخطأ، نحاول مرة أخرى فوراً
      if (retryCount < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 20 + (retryCount * 10)));
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
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showBiometricSettings() async {
    final isAvailable = await BiometricService.isAvailable();
    final biometricTypes = await BiometricService.getAvailableBiometrics();
    final isEnabled = await SessionManager.getRememberMe();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                title: const Text('Biometric Status'),
                subtitle: Text(isAvailable ? 'Available' : 'Not Available'),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              if (isAvailable) ...[
                const Text(
                  'Available Biometric Types:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...biometricTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(type.toString().split('.').last),
                        ],
                      ),
                    )),
                const Divider(),
                SwitchListTile(
                  title: const Text('Enable Biometric Login'),
                  value: isEnabled,
                  onChanged: (value) async {
                    await SessionManager.setRememberMe(value);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Biometric enabled'
                            : 'Biometric disabled'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await BiometricService.authenticate();
                    if (mounted) {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            result.success ? 'Test Successful' : 'Test Failed',
                          ),
                          content: Text(
                            result.success
                                ? 'Biometric is working correctly!'
                                : result.message ?? 'An error occurred',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Test Biometric'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0099A3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeel ERP'),
        centerTitle: true,
        backgroundColor: const Color(0xFFA21955),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'المزيد',
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'clear_cache') {
                _clearCache();
              } else if (value == 'biometric') {
                _showBiometricSettings();
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
                value: 'biometric',
                child: Row(
                  children: [
                    Icon(Icons.fingerprint, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Biometric Settings'),
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
        ],
      ),
    );
  }
}
