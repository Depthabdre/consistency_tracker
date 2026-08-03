import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/time_formatter.dart';

enum SessionPhaseType { focus, breakTime }

class CircularProgressTimer extends StatefulWidget {
  const CircularProgressTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.phaseType = SessionPhaseType.focus,
    this.size = 280.0,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final SessionPhaseType phaseType;
  final double size;

  @override
  State<CircularProgressTimer> createState() => _CircularProgressTimerState();
}

class _CircularProgressTimerState extends State<CircularProgressTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.totalSeconds == 0
        ? 0
        : (1 - (widget.remainingSeconds / widget.totalSeconds)).clamp(0.0, 1.0);

    final Color activeColor = widget.phaseType == SessionPhaseType.breakTime
        ? const Color(0xFF7ED39A) // Soft green for breaks
        : const Color(0xFF53B5EA); // Modern Windows/macOS focus blue

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Deep glowing background ring
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(
                          alpha: 0.08 + (_pulseController.value * 0.07)),
                      blurRadius: 35,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),

          // Segmented Progress Circle (60 ticks around the clock)
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: SegmentedCircularProgressPainter(
              progress: progress,
              activeColor: activeColor,
              inactiveColor: const Color(0xFF33353A),
              segmentCount: 60,
              strokeWidth: widget.size * 0.021,
            ),
          ),

          // Inner Timer Text Layout
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatSecondsDynamic(widget.remainingSeconds),
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF9FAFB),
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (widget.remainingSeconds >= 600)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'm',
                        style: TextStyle(
                          fontSize: widget.size * 0.1,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA0A0A0),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.phaseType == SessionPhaseType.breakTime
                          ? Icons.coffee_outlined
                          : Icons.center_focus_strong_outlined,
                      size: widget.size * 0.05,
                      color: activeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.phaseType == SessionPhaseType.breakTime
                          ? 'BREAK Phase'
                          : 'FOCUS Session',
                      style: TextStyle(
                        letterSpacing: 1.0,
                        fontSize: widget.size * 0.042,
                        color: activeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SegmentedCircularProgressPainter extends CustomPainter {
  const SegmentedCircularProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.segmentCount,
    required this.strokeWidth,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final int segmentCount;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final double sweepAngle = (math.pi * 2) / segmentCount;
    final double gapAngle = sweepAngle * 0.35;
    final double actualSweep = sweepAngle - gapAngle;

    final Paint inactivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = inactiveColor;

    final Paint activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round
      ..color = activeColor;

    final int activeSegments = (progress * segmentCount).round();

    for (int i = 0; i < segmentCount; i++) {
      final double startAngle = -math.pi / 2 + (i * sweepAngle);
      final Paint currentPaint = i < activeSegments ? activePaint : inactivePaint;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        actualSweep,
        false,
        currentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SegmentedCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.segmentCount != segmentCount ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
