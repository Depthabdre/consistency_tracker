import 'package:equatable/equatable.dart';
import '../../domain/entities/session_phase.dart';

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
  final List<SessionPhase> phases;
  final int currentPhaseIndex;
  final int remainingSecondsInPhase;
  final DateTime? targetEndTime;

  const FocusTimerRunningState({
    required this.goalId,
    required this.targetMinutes,
    required this.elapsedSeconds,
    required this.isTargetReached,
    this.phases = const [],
    this.currentPhaseIndex = 0,
    this.remainingSecondsInPhase = 0,
    this.targetEndTime,
  });

  SessionPhase? get currentPhase =>
      phases.isNotEmpty && currentPhaseIndex < phases.length
      ? phases[currentPhaseIndex]
      : null;

  @override
  List<Object?> get props => [
    goalId,
    targetMinutes,
    elapsedSeconds,
    isTargetReached,
    phases,
    currentPhaseIndex,
    remainingSecondsInPhase,
    targetEndTime,
  ];
}

class FocusTimerPausedState extends FocusTimerState {
  final String goalId;
  final int targetMinutes;
  final int elapsedSeconds;
  final List<SessionPhase> phases;
  final int currentPhaseIndex;
  final int remainingSecondsInPhase;

  const FocusTimerPausedState({
    required this.goalId,
    required this.targetMinutes,
    required this.elapsedSeconds,
    this.phases = const [],
    this.currentPhaseIndex = 0,
    this.remainingSecondsInPhase = 0,
  });

  SessionPhase? get currentPhase =>
      phases.isNotEmpty && currentPhaseIndex < phases.length
      ? phases[currentPhaseIndex]
      : null;

  @override
  List<Object?> get props => [
    goalId,
    targetMinutes,
    elapsedSeconds,
    phases,
    currentPhaseIndex,
    remainingSecondsInPhase,
  ];
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
