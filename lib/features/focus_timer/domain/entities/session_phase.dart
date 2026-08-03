import 'package:equatable/equatable.dart';

enum SessionPhaseType { focus, breakTime }

class SessionPhase extends Equatable {
  final SessionPhaseType type;
  final int durationSeconds;
  final int labelMinutes;

  const SessionPhase({
    required this.type,
    required this.durationSeconds,
    required this.labelMinutes,
  });

  @override
  List<Object?> get props => [type, durationSeconds, labelMinutes];
}

class FocusSessionPlan extends Equatable {
  final int totalTargetMinutes;
  final List<SessionPhase> phases;
  final int totalFocusSeconds;
  final int totalBreakSeconds;

  const FocusSessionPlan({
    required this.totalTargetMinutes,
    required this.phases,
    required this.totalFocusSeconds,
    required this.totalBreakSeconds,
  });

  @override
  List<Object?> get props => [
        totalTargetMinutes,
        phases,
        totalFocusSeconds,
        totalBreakSeconds,
      ];
}
