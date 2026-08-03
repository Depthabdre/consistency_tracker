import 'package:equatable/equatable.dart';

abstract class FocusTimerState extends Equatable {
  const FocusTimerState();

  @override
  List<Object?> get props => [];
}

class FocusTimerInitialState extends FocusTimerState {
  const FocusTimerInitialState();
}

class FocusTimerRunningState extends FocusTimerState {
  final String goalId;
  final int targetMinutes;
  final int elapsedSeconds;
  final bool isTargetReached;

  const FocusTimerRunningState({
    required this.goalId,
    required this.targetMinutes,
    required this.elapsedSeconds,
    required this.isTargetReached,
  });

  @override
  List<Object?> get props => [goalId, targetMinutes, elapsedSeconds, isTargetReached];
}

class FocusTimerPausedState extends FocusTimerState {
  final String goalId;
  final int targetMinutes;
  final int elapsedSeconds;

  const FocusTimerPausedState({
    required this.goalId,
    required this.targetMinutes,
    required this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [goalId, targetMinutes, elapsedSeconds];
}

class FocusTimerCompletedState extends FocusTimerState {
  final String goalId;
  final int totalMinutesCompleted;

  const FocusTimerCompletedState({
    required this.goalId,
    required this.totalMinutesCompleted,
  });

  @override
  List<Object?> get props => [goalId, totalMinutesCompleted];
}
