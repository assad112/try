import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  late WebViewController _webViewController;
  bool _isLoading = false;
  bool _showWebView = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              // Auto-fill email if provided
              final email = _emailController.text.trim();
              if (email.isNotEmpty) {
                await _autoFillEmail(email);
              }
            }
          },
        ),
      );
  }

  Future<void> _autoFillEmail(String email) async {
    try {
      final jsCode = '''
        (function() {
          var inputs = document.querySelectorAll('input[type="email"], input[type="text"], input[name*="email"], input[name*="login"]');
          for (var i = 0; i < inputs.length; i++) {
            var input = inputs[i];
            var name = (input.name || '').toLowerCase();
            var id = (input.id || '').toLowerCase();
            var type = (input.type || '').toLowerCase();
            
            if (type === 'email' || name.includes('email') || id.includes('email')) {
              input.value = '$email';
              input.dispatchEvent(new Event('input', { bubbles: true }));
              input.dispatchEvent(new Event('change', { bubbles: true }));
              return true;
            }
          }
          return false;
        })();
      ''';
      
      await Future.delayed(const Duration(milliseconds: 500));
      await _webViewController.runJavaScriptReturningResult(jsCode);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _handleResetPassword() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim();

    // Validate email
    final emailError = Validators.validateEmail(email);

    if (emailError != null) {
      setState(() {
        _emailError = emailError;
      });
      return;
    }

    // Show WebView with reset password page
    setState(() {
      _showWebView = true;
      _isLoading = true;
    });

    _webViewController.loadRequest(
      Uri.parse('https://erp.jeel.om/web/reset_password'),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFA21955),
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _showWebView
          ? AppBar(
              backgroundColor: const Color(0xFFA21955),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_showWebView) {
                    setState(() {
                      _showWebView = false;
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            )
          : null,
      body: _showWebView
          ? Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: LoadingAnimationWidget.discreteCircle(
                        color: const Color(0xFFA21955),
                        size: 40,
                        secondRingColor: const Color(0xFF0099A3),
                        thirdRingColor: const Color(0xFFA21955),
                      ),
                    ),
                  ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Top section with logo and menu icon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/JeeEngineering.png',
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 50,
                              width: 150,
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
                        // Menu icon
                        IconButton(
                          icon: const Icon(Icons.menu, size: 28),
                          onPressed: () {
                            // Menu action if needed
                          },
                        ),
                      ],
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Email field label
                        const Text(
                          'Your Email',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Email input field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: '',
                            errorText: _emailError,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF7B4B7E),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Reset Password button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B4B7E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? LoadingAnimationWidget.discreteCircle(
                                    color: Colors.white,
                                    size: 24,
                                    secondRingColor: const Color(0xFF7B4B7E),
                                    thirdRingColor: const Color(0xFF0099A3),
                                  )
                                : const Text(
                                    'Reset Password',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Back to Login link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
