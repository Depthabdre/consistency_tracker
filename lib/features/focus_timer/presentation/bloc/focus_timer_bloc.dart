import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/focus_session_model.dart';
import '../../data/repositories/focus_session_repository.dart';
import 'focus_timer_event.dart';
import 'focus_timer_state.dart';

class FocusTimerBloc extends Bloc<FocusTimerEvent, FocusTimerState> {
  final FocusSessionRepository sessionRepository;
  Timer? _tickerTimer;

  FocusTimerBloc({required this.sessionRepository})
      : super(const FocusTimerInitialState()) {
    on<StartFocusTimerEvent>(_onStartTimer);
    on<TickFocusTimerEvent>(_onTickTimer);
    on<PauseFocusTimerEvent>(_onPauseTimer);
    on<ResumeFocusTimerEvent>(_onResumeTimer);
    on<CompleteFocusTimerEvent>(_onCompleteTimer);
  }

  void _onStartTimer(
    StartFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) {
    _tickerTimer?.cancel();
    emit(FocusTimerRunningState(
      goalId: event.goalId,
      targetMinutes: event.targetMinutes,
      elapsedSeconds: 0,
      isTargetReached: false,
    ));

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(TickFocusTimerEvent(timer.tick));
    });
  }

  void _onTickTimer(
    TickFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) {
    if (state is FocusTimerRunningState) {
      final currentState = state as FocusTimerRunningState;
      final newElapsedSeconds = currentState.elapsedSeconds + 1;
      final targetSeconds = currentState.targetMinutes * 60;
      final isReached = newElapsedSeconds >= targetSeconds;

      emit(FocusTimerRunningState(
        goalId: currentState.goalId,
        targetMinutes: currentState.targetMinutes,
        elapsedSeconds: newElapsedSeconds,
        isTargetReached: isReached,
      ));
    }
  }

  void _onPauseTimer(
    PauseFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) {
    if (state is FocusTimerRunningState) {
      final currentState = state as FocusTimerRunningState;
      _tickerTimer?.cancel();
      emit(FocusTimerPausedState(
        goalId: currentState.goalId,
        targetMinutes: currentState.targetMinutes,
        elapsedSeconds: currentState.elapsedSeconds,
      ));
    }
  }

  void _onResumeTimer(
    ResumeFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) {
    if (state is FocusTimerPausedState) {
      final currentState = state as FocusTimerPausedState;
      emit(FocusTimerRunningState(
        goalId: currentState.goalId,
        targetMinutes: currentState.targetMinutes,
        elapsedSeconds: currentState.elapsedSeconds,
        isTargetReached: currentState.elapsedSeconds >= (currentState.targetMinutes * 60),
      ));

      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        add(TickFocusTimerEvent(timer.tick));
      });
    }
  }

  Future<void> _onCompleteTimer(
    CompleteFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) async {
    _tickerTimer?.cancel();
    if (state is FocusTimerRunningState || state is FocusTimerPausedState) {
      final goalId = (state is FocusTimerRunningState)
          ? (state as FocusTimerRunningState).goalId
          : (state as FocusTimerPausedState).goalId;
      final elapsedSeconds = (state is FocusTimerRunningState)
          ? (state as FocusTimerRunningState).elapsedSeconds
          : (state as FocusTimerPausedState).elapsedSeconds;
      final targetMinutes = (state is FocusTimerRunningState)
          ? (state as FocusTimerRunningState).targetMinutes
          : (state as FocusTimerPausedState).targetMinutes;

      final durationMinutes = (elapsedSeconds / 60).ceil();
      final isTargetMet = elapsedSeconds >= (targetMinutes * 60);

      final session = FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: goalId,
        durationMinutes: durationMinutes,
        timestamp: DateTime.now(),
        completedTargetMet: isTargetMet,
      );

      await sessionRepository.saveSession(session);

      emit(FocusTimerCompletedState(
        goalId: goalId,
        totalMinutesCompleted: durationMinutes,
      ));
    }
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }
}
