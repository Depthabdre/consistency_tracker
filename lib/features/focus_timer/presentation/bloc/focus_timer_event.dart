import 'package:equatable/equatable.dart';

abstract class FocusTimerEvent extends Equatable {
  const FocusTimerEvent();

  @override
  List<Object?> get props => [];
}

class StartFocusTimerEvent extends FocusTimerEvent {
  final String goalId;
  final int targetMinutes;

  const StartFocusTimerEvent({
    required this.goalId,
    required this.targetMinutes,
  });

  @override
  List<Object?> get props => [goalId, targetMinutes];
}

class TickFocusTimerEvent extends FocusTimerEvent {
  final int elapsedSeconds;

  const TickFocusTimerEvent(this.elapsedSeconds);

  @override
  List<Object?> get props => [elapsedSeconds];
}

class PauseFocusTimerEvent extends FocusTimerEvent {
  const PauseFocusTimerEvent();
}

class ResumeFocusTimerEvent extends FocusTimerEvent {
  const ResumeFocusTimerEvent();
}

class CompleteFocusTimerEvent extends FocusTimerEvent {
  const CompleteFocusTimerEvent();
}
