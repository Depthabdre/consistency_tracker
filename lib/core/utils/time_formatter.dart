import 'dart:math' as math;

String formatSecondsDynamic(int seconds) {
  final safeSeconds = math.max(0, seconds);
  final mins = safeSeconds ~/ 60;
  final secs = safeSeconds % 60;
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
