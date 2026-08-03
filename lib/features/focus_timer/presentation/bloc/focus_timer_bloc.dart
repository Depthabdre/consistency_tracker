import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../data/models/focus_session_model.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../domain/entities/session_phase.dart';
import '../../domain/usecases/calculate_chunks_usecase.dart';
import '../../domain/usecases/manage_timer_usecase.dart';
import 'focus_timer_event.dart';
import 'focus_timer_state.dart';

class FocusTimerBloc extends Bloc<FocusTimerEvent, FocusTimerState> {
  final FocusSessionRepository sessionRepository;
  final CalculateChunksUseCase calculateChunksUseCase;
  final ManageTimerUseCase manageTimerUseCase;
  final AudioService audioService;
  final NotificationService notificationService;

  Timer? _tickerTimer;
  AppSettings _activeSettings = AppSettings.defaults;
  int _accumulatedFocusSeconds = 0;

  FocusTimerBloc({
    required this.sessionRepository,
    CalculateChunksUseCase? calculateChunksUseCase,
    ManageTimerUseCase? manageTimerUseCase,
    AudioService? audioService,
    NotificationService? notificationService,
  })  : calculateChunksUseCase = calculateChunksUseCase ?? CalculateChunksUseCase(),
        manageTimerUseCase = manageTimerUseCase ?? ManageTimerUseCase(),
        audioService = audioService ?? AudioServiceImpl(),
        notificationService = notificationService ?? DummyNotificationService(),
        super(const FocusTimerInitialState()) {
    on<StartFocusTimerEvent>(_onStartTimer);
    on<TickFocusTimerEvent>(_onTickTimer);
    on<PauseFocusTimerEvent>(_onPauseTimer);
    on<ResumeFocusTimerEvent>(_onResumeTimer);
    on<CompleteFocusTimerEvent>(_onCompleteTimer);
  }

  Future<void> _onStartTimer(
    StartFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) async {
    _tickerTimer?.cancel();
    _activeSettings = event.settings ?? AppSettings.defaults;
    _accumulatedFocusSeconds = 0;

    final plan = calculateChunksUseCase(
      totalTargetMinutes: event.targetMinutes,
      settings: _activeSettings,
      skipBreaks: event.skipBreaks,
    );

    final firstPhase = plan.phases.first;
    final now = DateTime.now();
    final targetEndTime = manageTimerUseCase.buildTargetEndTime(
      from: now,
      durationSeconds: firstPhase.durationSeconds,
    );

    emit(FocusTimerRunningState(
      goalId: event.goalId,
      targetMinutes: event.targetMinutes,
      elapsedSeconds: 0,
      isTargetReached: false,
      phases: plan.phases,
      currentPhaseIndex: 0,
      remainingSecondsInPhase: firstPhase.durationSeconds,
      targetEndTime: targetEndTime,
    ));

    _startTicker();
  }

  Future<void> _onTickTimer(
    TickFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) async {
    if (state is! FocusTimerRunningState) return;

    final currentState = state as FocusTimerRunningState;
    if (currentState.targetEndTime == null) return;

    final now = event.now ?? DateTime.now();
    final remainingInPhase = manageTimerUseCase.calculateRemainingSeconds(
      now: now,
      targetEndTime: currentState.targetEndTime!,
    );

    final currentPhase = currentState.currentPhase;

    // Accumulate total overall elapsed seconds
    final int totalElapsedSeconds = currentState.elapsedSeconds + 1;
    final int targetSeconds = currentState.targetMinutes * 60;
    final bool isReached = totalElapsedSeconds >= targetSeconds;

    if (currentPhase?.type == SessionPhaseType.focus) {
      _accumulatedFocusSeconds += 1;
    }

    if (remainingInPhase > 0) {
      emit(FocusTimerRunningState(
        goalId: currentState.goalId,
        targetMinutes: currentState.targetMinutes,
        elapsedSeconds: totalElapsedSeconds,
        isTargetReached: isReached,
        phases: currentState.phases,
        currentPhaseIndex: currentState.currentPhaseIndex,
        remainingSecondsInPhase: remainingInPhase,
        targetEndTime: currentState.targetEndTime,
      ));
      return;
    }

    // Phase transition when remainingInPhase reaches 0
    await _advanceToNextPhaseOrComplete(currentState, emit);
  }

  Future<void> _advanceToNextPhaseOrComplete(
    FocusTimerRunningState currentState,
    Emitter<FocusTimerState> emit,
  ) async {
    final nextIndex = currentState.currentPhaseIndex + 1;

    if (nextIndex >= currentState.phases.length) {
      _tickerTimer?.cancel();
      final focusMins = (_accumulatedFocusSeconds / 60).floor();
      final isTargetMet = _accumulatedFocusSeconds >= (currentState.targetMinutes * 60);

      final session = FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: currentState.goalId,
        durationMinutes: focusMins,
        timestamp: DateTime.now(),
        completedTargetMet: isTargetMet,
      );

      await sessionRepository.saveSession(session);
      await audioService.playTransitionSound(enabled: _activeSettings.soundEnabled);
      await notificationService.showPhaseNotification(
        title: 'Focus session complete',
        body: 'Great work! You reached your target time.',
        enabled: _activeSettings.notificationsEnabled,
      );

      emit(FocusTimerCompletedState(
        goalId: currentState.goalId,
        totalMinutesCompleted: focusMins,
      ));
      return;
    }

    final nextPhase = currentState.phases[nextIndex];
    final now = DateTime.now();
    final nextTargetEnd = manageTimerUseCase.buildTargetEndTime(
      from: now,
      durationSeconds: nextPhase.durationSeconds,
    );

    await audioService.playTransitionSound(enabled: _activeSettings.soundEnabled);
    await notificationService.showPhaseNotification(
      title: nextPhase.type == SessionPhaseType.breakTime ? 'Break time ☕' : 'Focus time 🎯',
      body: nextPhase.type == SessionPhaseType.breakTime
          ? 'Take a short break before your next focus block.'
          : 'Break is over. Ready to focus?',
      enabled: _activeSettings.notificationsEnabled,
    );

    emit(FocusTimerRunningState(
      goalId: currentState.goalId,
      targetMinutes: currentState.targetMinutes,
      elapsedSeconds: currentState.elapsedSeconds,
      isTargetReached: currentState.isTargetReached,
      phases: currentState.phases,
      currentPhaseIndex: nextIndex,
      remainingSecondsInPhase: nextPhase.durationSeconds,
      targetEndTime: nextTargetEnd,
    ));
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
        phases: currentState.phases,
        currentPhaseIndex: currentState.currentPhaseIndex,
        remainingSecondsInPhase: currentState.remainingSecondsInPhase,
      ));
    }
  }

  void _onResumeTimer(
    ResumeFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) {
    if (state is FocusTimerPausedState) {
      final currentState = state as FocusTimerPausedState;
      final now = DateTime.now();
      final targetEndTime = manageTimerUseCase.buildTargetEndTime(
        from: now,
        durationSeconds: currentState.remainingSecondsInPhase,
      );

      emit(FocusTimerRunningState(
        goalId: currentState.goalId,
        targetMinutes: currentState.targetMinutes,
        elapsedSeconds: currentState.elapsedSeconds,
        isTargetReached: currentState.elapsedSeconds >= (currentState.targetMinutes * 60),
        phases: currentState.phases,
        currentPhaseIndex: currentState.currentPhaseIndex,
        remainingSecondsInPhase: currentState.remainingSecondsInPhase,
        targetEndTime: targetEndTime,
      ));

      _startTicker();
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
      final targetMinutes = (state is FocusTimerRunningState)
          ? (state as FocusTimerRunningState).targetMinutes
          : (state as FocusTimerPausedState).targetMinutes;

      final focusMins = math.max(0, (_accumulatedFocusSeconds / 60).floor());
      final isTargetMet = _accumulatedFocusSeconds >= (targetMinutes * 60);

      final session = FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: goalId,
        durationMinutes: focusMins,
        timestamp: DateTime.now(),
        completedTargetMet: isTargetMet,
      );

      await sessionRepository.saveSession(session);

      emit(FocusTimerCompletedState(
        goalId: goalId,
        totalMinutesCompleted: focusMins,
      ));
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(TickFocusTimerEvent(timer.tick, now: DateTime.now()));
    });
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }
}

class DummyNotificationService implements NotificationService {
  @override
  Future<void> showPhaseNotification({
    required String title,
    required String body,
    required bool enabled,
    Function()? onUserInteraction,
  }) async {}
}
