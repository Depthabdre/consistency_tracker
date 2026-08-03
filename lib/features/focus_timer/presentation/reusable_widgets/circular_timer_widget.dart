import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CircularTimerWidget extends StatelessWidget {
  final int elapsedSeconds;
  final int targetMinutes;
  final bool isRunning;
  final Color accentColor;

  const CircularTimerWidget({
    super.key,
    required this.elapsedSeconds,
    required this.targetMinutes,
    required this.isRunning,
    this.accentColor = AppTheme.primary,
  });

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalTargetSeconds = targetMinutes * 60;
    final progress = totalTargetSeconds > 0
        ? (elapsedSeconds / totalTargetSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glowing shadow pulse
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isRunning
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ]
                : [],
          ),
        ),
        // Circular Progress Painter
        CustomPaint(
          size: const Size(250, 250),
          painter: _TimerArcPainter(
            progress: progress,
            accentColor: accentColor,
          ),
        ),
        // Timer Text Content inside ring
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(elapsedSeconds),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  progress >= 1.0 ? Icons.check_circle : Icons.flag_outlined,
                  size: 16,
                  color: progress >= 1.0 ? AppTheme.success : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Target: ${targetMinutes}m',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: progress >= 1.0 ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _TimerArcPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Track Background Arc
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Active Progress Arc
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: [accentColor, accentColor.withValues(alpha: 0.6), accentColor],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
  }
}
