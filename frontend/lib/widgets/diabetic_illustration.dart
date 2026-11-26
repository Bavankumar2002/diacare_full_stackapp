// =============================================================================
// DiaCare - Diabetic App Hero & Pre-loader Vector Illustration
// =============================================================================

import 'package:flutter/material.dart';
import '../core/constants.dart';

class DiabeticIllustration extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showBadges;

  const DiabeticIllustration({
    super.key,
    this.size = 260,
    this.animate = true,
    this.showBadges = true,
  });

  @override
  State<DiabeticIllustration> createState() => _DiabeticIllustrationState();
}

class _DiabeticIllustrationState extends State<DiabeticIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final scale = s / 260.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatOffset = widget.animate ? _floatAnimation.value : 0.0;
        final pulseScale = widget.animate ? _pulseAnimation.value : 1.0;

        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Soft Ambient Glowing Background Rings
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: s * 0.92,
                  height: s * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppConstants.primaryTeal.withValues(alpha: 0.16),
                        const Color(0xFF10B981).withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.2, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Decorative ambient circles
              Positioned(
                top: 20 * scale,
                right: 25 * scale,
                child: Container(
                  width: 32 * scale,
                  height: 32 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  ),
                ),
              ),
              Positioned(
                bottom: 30 * scale,
                left: 20 * scale,
                child: Container(
                  width: 44 * scale,
                  height: 44 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.primaryTeal.withValues(alpha: 0.14),
                  ),
                ),
              ),

              // 2. Main Glucometer & Blood Sugar Device (Floating)
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blood Test Strip at top of device
                    Container(
                      width: 36 * scale,
                      height: 26 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Metallic sensor pins
                          Positioned(
                            top: 3 * scale,
                            child: Container(
                              width: 14 * scale,
                              height: 4 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAB308),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Crimson Blood Sample Drop with Highlight
                          Positioned(
                            bottom: 2 * scale,
                            child: Container(
                              width: 16 * scale,
                              height: 16 * scale,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFB91C1C),
                                  ],
                                  center: Alignment(-0.3, -0.3),
                                ),
                              ),
                              child: Align(
                                alignment: const Alignment(-0.4, -0.4),
                                child: Container(
                                  width: 4 * scale,
                                  height: 4 * scale,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Modern Diabetes Smart Monitor Body
                    Container(
                      width: 156 * scale,
                      height: 182 * scale,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32 * scale),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF8FAFC),
                            Color(0xFFEDF8F9),
                          ],
                        ),
                        border: Border.all(
                          color: AppConstants.primaryTeal.withValues(alpha: 0.35),
                          width: 2.2 * scale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryTeal.withValues(alpha: 0.18),
                            blurRadius: 24 * scale,
                            spreadRadius: 2,
                            offset: Offset(0, 10 * scale),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 9 * scale,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 132 * scale,
                            height: 160 * scale,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                            // Top Device Brand Accent & LED
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8 * scale,
                                      height: 8 * scale,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4 * scale),
                                    Text(
                                      'DiaCare',
                                      style: TextStyle(
                                        fontSize: 10 * scale,
                                        fontWeight: FontWeight.w800,
                                        color: AppConstants.primaryTeal,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.bluetooth_connected_rounded,
                                  size: 13 * scale,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),

                            // Digital LCD Display Screen
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 6 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(
                                  color: const Color(0xFF1E293B),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Sugar Value + Unit
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '104',
                                        style: TextStyle(
                                          fontSize: 34 * scale,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(width: 4 * scale),
                                      Text(
                                        'mg/dL',
                                        style: TextStyle(
                                          fontSize: 11 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Status Badge: Normal (70-140)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 2.5 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(10 * scale),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6 * scale,
                                          height: 6 * scale,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 4 * scale),
                                        Text(
                                          'NORMAL',
                                          style: TextStyle(
                                            fontSize: 9 * scale,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF34D399),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: 4 * scale),

                                  // Heartbeat ECG Pulse wave
                                  SizedBox(
                                    width: double.infinity,
                                    height: 12 * scale,
                                    child: CustomPaint(
                                      painter: _EcgWavePainter(scale: scale),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Physical Button Accents
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildDeviceButton(
                                  icon: Icons.power_settings_new_rounded,
                                  scale: scale,
                                ),
                                _buildDeviceButton(
                                  label: 'M',
                                  scale: scale,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ),

              // 3. Floating Surrounding Healthcare Badges
              if (widget.showBadges) ...[
                // Top-Left: Low Glycemic Diet / Nutrition
                Positioned(
                  top: 18 * scale,
                  left: 6 * scale,
                  child: Transform.translate(
                    offset: Offset(0, -floatOffset * 0.7),
                    child: _buildFloatingBadge(
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      label: 'Low GI Diet',
                      scale: scale,
                    ),
                  ),
                ),

                // Top-Right: Verified Glucose Care
                Positioned(
                  top: 14 * scale,
                  right: 4 * scale,
                  child: Transform.translate(
                    offset: Offset(0, floatOffset * 0.8),
                    child: _buildFloatingBadge(
                      icon: Icons.verified_rounded,
                      iconColor: AppConstants.primaryTeal,
                      bgColor: const Color(0xFFE2F6F8),
                      label: 'Care Tested',
                      scale: scale,
                    ),
                  ),
                ),

                // Bottom-Right: Medicine & Insulin Reminder
                Positioned(
                  bottom: 18 * scale,
                  right: 8 * scale,
                  child: Transform.translate(
                    offset: Offset(0, -floatOffset * 0.6),
                    child: _buildFloatingBadge(
                      icon: Icons.medication_rounded,
                      iconColor: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      label: 'Med Alerts',
                      scale: scale,
                    ),
                  ),
                ),

                // Bottom-Left: Blood Sugar Log
                Positioned(
                  bottom: 22 * scale,
                  left: 4 * scale,
                  child: Transform.translate(
                    offset: Offset(0, floatOffset * 0.7),
                    child: _buildFloatingBadge(
                      icon: Icons.water_drop_rounded,
                      iconColor: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEE2E2),
                      label: 'Auto Track',
                      scale: scale,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceButton({
    IconData? icon,
    String? label,
    required double scale,
  }) {
    return Container(
      width: 24 * scale,
      height: 24 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 13 * scale, color: const Color(0xFF475569))
            : Text(
                label ?? '',
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                ),
              ),
      ),
    );
  }

  Widget _buildFloatingBadge({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: 5 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4 * scale),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 13 * scale),
          ),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgWavePainter extends CustomPainter {
  final double scale;
  _EcgWavePainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF34D399)
      ..strokeWidth = 1.6 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final h = size.height;
    final w = size.width;

    path.moveTo(0, h * 0.5);
    path.lineTo(w * 0.25, h * 0.5);
    path.lineTo(w * 0.32, h * 0.2);
    path.lineTo(w * 0.40, h * 0.85);
    path.lineTo(w * 0.50, h * 0.05);
    path.lineTo(w * 0.58, h * 0.95);
    path.lineTo(w * 0.65, h * 0.4);
    path.lineTo(w * 0.72, h * 0.5);
    path.lineTo(w, h * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
