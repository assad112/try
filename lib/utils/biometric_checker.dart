import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

/// أداة فحص حالة البصمة للاختبار
class BiometricChecker {
  /// فحص وعرض حالة البصمة في وحدة التحكم
  static Future<void> checkAndPrint() async {
    debugPrint('=== فحص حالة البصمة ===');

    final status = await BiometricService.checkBiometricStatus();

    debugPrint('دعم الجهاز: ${status['isDeviceSupported']}');
    debugPrint('إمكانية الفحص: ${status['canCheckBiometrics']}');
    debugPrint('وجود بصمة حقيقية: ${status['hasRealBiometric']}');
    debugPrint('الأنواع المتاحة: ${status['availableBiometrics']}');
    debugPrint('البصمة متاحة: ${status['isAvailable']}');

    if (status['error'] != null) {
      debugPrint('⚠️ خطأ: ${status['error']}');
    }

    debugPrint('========================');
  }

  /// عرض حالة البصمة في Dialog
  static Future<void> showBiometricDialog(BuildContext context) async {
    final status = await BiometricService.checkBiometricStatus();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حالة البصمة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusRow('دعم الجهاز', status['isDeviceSupported']),
              _buildStatusRow('إمكانية الفحص', status['canCheckBiometrics']),
              _buildStatusRow('بصمة حقيقية', status['hasRealBiometric']),
              _buildStatusRow('البصمة متاحة', status['isAvailable']),
              const SizedBox(height: 12),
              const Text(
                'الأنواع المتاحة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                status['availableBiometrics'].isEmpty
                    ? 'لا يوجد'
                    : (status['availableBiometrics'] as List).join('\n'),
                style: const TextStyle(fontSize: 12),
              ),
              if (status['error'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'خطأ: ${status['error']}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
