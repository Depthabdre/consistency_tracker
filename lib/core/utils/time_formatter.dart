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

/// Countdown clock format: `m:ss`, or `h:mm:ss` for an hour or more.
String formatClock(int seconds) {
  final s = math.max(0, seconds);
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$sec';
  return '${m.toString().padLeft(2, '0')}:$sec';
}

/// Compact human duration: `45m`, `1h 20m`, `3h`.
String formatMinutes(int minutes) {
  final m = math.max(0, minutes);
  if (m < 60) return '${m}m';
  final h = m ~/ 60;
  final rem = m % 60;
  return rem == 0 ? '${h}h' : '${h}h ${rem}m';
}

/// `9:05 PM` style wall-clock time.
String formatTimeOfDay(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}
