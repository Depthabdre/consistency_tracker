import 'dart:math' as math;

String formatSecondsDynamic(int seconds) {
  final safeSeconds = math.max(0, seconds);
  if (safeSeconds >= 60) {
    final mins = (safeSeconds / 60).ceil();
    return '${mins}m';
  } else {
    return '${safeSeconds}s';
  }
}
