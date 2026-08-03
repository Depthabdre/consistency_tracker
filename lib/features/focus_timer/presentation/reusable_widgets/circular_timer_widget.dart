import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CircularProgressTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  const CircularProgressTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 240,
  });

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).clamp(0, 999);
    final secs = (seconds % 60).clamp(0, 59);
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = totalSeconds > 0
        ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: progress,
              accentColor: AppTheme.accentCyan,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(remainingSeconds),
                style: TextStyle(
                  fontSize: (size * 0.22).clamp(24.0, 64.0),
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              SizedBox(height: size * 0.04),
              Text(
                '${(totalSeconds ~/ 60)} mins goal',
                style: TextStyle(
                  fontSize: (size * 0.06).clamp(11.0, 14.0),
                  color: const Color(0xFFA0A0A0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _CircularProgressPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = (size.width * 0.04).clamp(6.0, 14.0);
    final radius = (size.width / 2) - strokeWidth;

    // Track Background Arc
    final backgroundPaint = Paint()
      ..color = const Color(0xFF404040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Active Remaining Progress Arc
    final activePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
