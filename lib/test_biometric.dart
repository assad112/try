import 'package:flutter/material.dart';
import 'services/biometric_service.dart';
import 'utils/biometric_checker.dart';

/// صفحة اختبار مستقلة لفحص البصمة
void main() {
  runApp(const BiometricTestApp());
}

class BiometricTestApp extends StatelessWidget {
  const BiometricTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اختبار البصمة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const BiometricTestScreen(),
    );
  }
}

class BiometricTestScreen extends StatefulWidget {
  const BiometricTestScreen({super.key});

  @override
  State<BiometricTestScreen> createState() => _BiometricTestScreenState();
}

class _BiometricTestScreenState extends State<BiometricTestScreen> {
  Map<String, dynamic>? _status;
  bool _isLoading = false;
  String? _authResult;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
    });

    final status = await BiometricService.checkBiometricStatus();

    setState(() {
      _status = status;
      _isLoading = false;
    });

    // طباعة النتيجة في Console
    await BiometricChecker.checkAndPrint();
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _authResult = null;
    });

    final result = await BiometricService.authenticate();

    setState(() {
      _authResult = result.success
          ? 'نجح التحقق ✅'
          : (result.message ?? 'فشل التحقق ❌');
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authResult!),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص البصمة'),
        backgroundColor: const Color(0xFFA21955),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _checkStatus),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildTestButtons(),
                  if (_authResult != null) ...[
                    const SizedBox(height: 20),
                    _buildResultCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (_status == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حالة البصمة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildStatusRow('دعم الجهاز', _status!['isDeviceSupported']),
            _buildStatusRow('إمكانية الفحص', _status!['canCheckBiometrics']),
            _buildStatusRow('بصمة حقيقية', _status!['hasRealBiometric']),
            _buildStatusRow('البصمة متاحة', _status!['isAvailable']),
            const SizedBox(height: 16),
            const Text(
              'الأنواع المتاحة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status!['availableBiometrics'].isEmpty
                    ? 'لا يوجد'
                    : (_status!['availableBiometrics'] as List).join('\n'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
            if (_status!['error'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status!['error'],
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
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
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _status?['isAvailable'] == true
              ? _testAuthentication
              : null,
          icon: const Icon(Icons.fingerprint),
          label: const Text('اختبار المصادقة بالبصمة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0099A3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            BiometricChecker.showBiometricDialog(context);
          },
          icon: const Icon(Icons.info_outline),
          label: const Text('عرض التفاصيل في Dialog'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _authResult!.contains('✅');

    return Card(
      elevation: 2,
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.cancel,
              color: isSuccess ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _authResult!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSuccess
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
