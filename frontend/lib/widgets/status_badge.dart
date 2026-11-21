// =============================================================================
// DiaCare - Glucose Status Pill Badge Widget
// =============================================================================

import 'package:flutter/material.dart';
import '../core/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status; // 'Low', 'Normal', 'High'
  final double? fontSize;
  final EdgeInsets? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'low':
        bg = const Color(0xFFFEE2E2);
        text = AppConstants.statusDanger;
        icon = Icons.arrow_downward_rounded;
        break;
      case 'high':
        bg = const Color(0xFFFEE2E2);
        text = AppConstants.statusDanger;
        icon = Icons.arrow_upward_rounded;
        break;
      case 'warning':
        bg = const Color(0xFFFEF3C7);
        text = AppConstants.statusWarning;
        icon = Icons.warning_amber_rounded;
        break;
      case 'normal':
      default:
        bg = const Color(0xFFD1FAE5);
        text = AppConstants.statusNormal;
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: (fontSize ?? 12) + 2, color: text),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
