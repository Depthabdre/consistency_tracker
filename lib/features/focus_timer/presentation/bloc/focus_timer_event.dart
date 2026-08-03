import 'package:equatable/equatable.dart';
import '../../../settings/domain/entities/app_settings.dart';

abstract class FocusTimerEvent extends Equatable {
  const FocusTimerEvent();

  @override
  List<Object?> get props => [];
}

class StartFocusTimerEvent extends FocusTimerEvent {
  final String goalId;
  final int targetMinutes;
  final AppSettings? settings;
  final bool skipBreaks;

  const StartFocusTimerEvent({
    required this.goalId,
    required this.targetMinutes,
    this.settings,
    this.skipBreaks = false,
  });

  @override
  List<Object?> get props => [goalId, targetMinutes, settings, skipBreaks];
}

class TickFocusTimerEvent extends FocusTimerEvent {
  final int elapsedSeconds;
  final DateTime? now;

  const TickFocusTimerEvent(this.elapsedSeconds, {this.now});

  @override
  List<Object?> get props => [elapsedSeconds, now];
}

class PauseFocusTimerEvent extends FocusTimerEvent {
  const PauseFocusTimerEvent();
}

class ResumeFocusTimerEvent extends FocusTimerEvent {
  const ResumeFocusTimerEvent();
}

class CompleteFocusTimerEvent extends FocusTimerEvent {
  final int? elapsedSeconds;

  const CompleteFocusTimerEvent({this.elapsedSeconds});

  @override
  List<Object?> get props => [elapsedSeconds];
}
