import 'dart:math' as math;

class ManageTimerUseCase {
  DateTime buildTargetEndTime({
    required DateTime from,
    required int durationSeconds,
  }) {
    return from.add(Duration(seconds: durationSeconds));
  }

  int calculateRemainingSeconds({
    required DateTime now,
    required DateTime targetEndTime,
  }) {
    final diff = targetEndTime.difference(now).inSeconds;
    return math.max(0, diff);
  }
}
