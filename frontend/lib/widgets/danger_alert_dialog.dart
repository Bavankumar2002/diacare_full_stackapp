// =============================================================================
// DiaCare - Urgent Glucose Danger Alert Dialog with Emergency Dialer
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/sugar_reading_model.dart';
import 'custom_button.dart';

class DangerAlertDialog extends StatelessWidget {
  final SugarAlertModel alert;
  final double readingValue;

  const DangerAlertDialog({
    super.key,
    required this.alert,
    required this.readingValue,
  });

  static Future<void> show(
    BuildContext context, {
    required SugarAlertModel alert,
    required double readingValue,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DangerAlertDialog(
        alert: alert,
        readingValue: readingValue,
      ),
    );
  }

  Future<void> _callEmergencyContact(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot initiate phone call to $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLow = alert.severity == 'low';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.statusDanger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppConstants.statusDanger,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isLow ? 'Hypoglycemia Alert!' : 'Critical High Sugar Alert!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.statusDanger,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.statusDanger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${readingValue.toStringAsFixed(0)} mg/dL',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppConstants.statusDanger,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              alert.advice,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade900,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          if (alert.emergencyPhone.isNotEmpty) ...[
            const SizedBox(height: 20),
            CustomButton(
              text: 'Call Emergency: ${alert.emergencyName.isNotEmpty ? alert.emergencyName : alert.emergencyPhone}',
              icon: Icons.phone_in_talk_rounded,
              backgroundColor: AppConstants.statusDanger,
              onPressed: () => _callEmergencyContact(context, alert.emergencyPhone),
            ),
          ],
          const SizedBox(height: 12),
          CustomButton(
            text: 'I Understand & Will Take Action',
            isOutlined: true,
            backgroundColor: const Color(0xFF64748B),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
