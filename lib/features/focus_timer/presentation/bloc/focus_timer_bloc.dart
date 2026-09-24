import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../data/datasources/active_session_store.dart';
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
  final ActiveSessionStore activeSessionStore;

  Timer? _tickerTimer;
  AppSettings _activeSettings = AppSettings.defaults;
  int _accumulatedFocusSeconds = 0;

  FocusTimerBloc({
    required this.sessionRepository,
    CalculateChunksUseCase? calculateChunksUseCase,
    ManageTimerUseCase? manageTimerUseCase,
    AudioService? audioService,
    NotificationService? notificationService,
    ActiveSessionStore? activeSessionStore,
  }) : calculateChunksUseCase =
           calculateChunksUseCase ?? CalculateChunksUseCase(),
       manageTimerUseCase = manageTimerUseCase ?? ManageTimerUseCase(),
       audioService = audioService ?? AudioServiceImpl(),
       notificationService = notificationService ?? DummyNotificationService(),
       activeSessionStore =
           activeSessionStore ?? const NoopActiveSessionStore(),
       super(const FocusTimerInitialState()) {
    on<StartFocusTimerEvent>(_onStartTimer);
    on<TickFocusTimerEvent>(_onTickTimer);
    on<PauseFocusTimerEvent>(_onPauseTimer);
    on<ResumeFocusTimerEvent>(_onResumeTimer);
    on<CompleteFocusTimerEvent>(_onCompleteTimer);
    on<RestoreFocusTimerEvent>(_onRestore);
  }

  Future<void> _persist() async {
    final s = state;
    final ActiveSessionSnapshot snapshot;
    if (s is FocusTimerRunningState) {
      snapshot = ActiveSessionSnapshot(
        goalId: s.goalId,
        targetMinutes: s.targetMinutes,
        phases: s.phases,
        currentPhaseIndex: s.currentPhaseIndex,
        remainingSecondsInPhase: s.remainingSecondsInPhase,
        elapsedSeconds: s.elapsedSeconds,
        accumulatedFocusSeconds: _accumulatedFocusSeconds,
        paused: false,
        targetEndTime: s.targetEndTime,
        soundEnabled: _activeSettings.soundEnabled,
        notificationsEnabled: _activeSettings.notificationsEnabled,
      );
    } else if (s is FocusTimerPausedState) {
      snapshot = ActiveSessionSnapshot(
        goalId: s.goalId,
        targetMinutes: s.targetMinutes,
        phases: s.phases,
        currentPhaseIndex: s.currentPhaseIndex,
        remainingSecondsInPhase: s.remainingSecondsInPhase,
        elapsedSeconds: s.elapsedSeconds,
        accumulatedFocusSeconds: _accumulatedFocusSeconds,
        paused: true,
        soundEnabled: _activeSettings.soundEnabled,
        notificationsEnabled: _activeSettings.notificationsEnabled,
      );
    } else {
      return;
    }
    try {
      await activeSessionStore.save(snapshot);
    } catch (_) {}
  }

  Future<void> _clearPersisted() async {
    try {
      await activeSessionStore.clear();
    } catch (_) {}
  }

  Future<void> _onRestore(
    RestoreFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) async {
    if (state is FocusTimerRunningState || state is FocusTimerPausedState) {
      return;
    }
    final ActiveSessionSnapshot? snap;
    try {
      snap = await activeSessionStore.load();
    } catch (_) {
      return;
    }
    if (snap == null) return;

    _activeSettings = AppSettings.defaults.copyWith(
      soundEnabled: snap.soundEnabled,
      notificationsEnabled: snap.notificationsEnabled,
    );
    _accumulatedFocusSeconds = snap.accumulatedFocusSeconds;

    if (snap.paused || snap.targetEndTime == null) {
      emit(
        FocusTimerPausedState(
          goalId: snap.goalId,
          targetMinutes: snap.targetMinutes,
          elapsedSeconds: snap.elapsedSeconds,
          phases: snap.phases,
          currentPhaseIndex: snap.currentPhaseIndex,
          remainingSecondsInPhase: snap.remainingSecondsInPhase,
        ),
      );
      return;
    }

    final now = event.now ?? DateTime.now();
    var index = snap.currentPhaseIndex;
    var phaseEnd = snap.targetEndTime!;
    var remaining = snap.remainingSecondsInPhase;
    var elapsed = snap.elapsedSeconds;

    // Fast-forward through phases that finished while the app was closed.
    while (!now.isBefore(phaseEnd)) {
      if (snap.phases[index].type == SessionPhaseType.focus) {
        _accumulatedFocusSeconds += remaining;
      }
      elapsed += remaining;
      index++;
      if (index >= snap.phases.length) {
        await _finishSession(
          emit,
          goalId: snap.goalId,
          targetMinutes: snap.targetMinutes,
        );
        return;
      }
      remaining = snap.phases[index].durationSeconds;
      phaseEnd = phaseEnd.add(Duration(seconds: remaining));
    }

    // Time already spent in the current phase is counted by the first tick.
    final phaseDuration = snap.phases[index].durationSeconds;
    final startedPhaseEarlier = index != snap.currentPhaseIndex;
    if (startedPhaseEarlier) {
      final spent = phaseDuration - phaseEnd.difference(now).inSeconds;
      if (snap.phases[index].type == SessionPhaseType.focus) {
        _accumulatedFocusSeconds += spent;
      }
      elapsed += spent;
      remaining = phaseDuration - spent;
    }

    emit(
      FocusTimerRunningState(
        goalId: snap.goalId,
        targetMinutes: snap.targetMinutes,
        elapsedSeconds: elapsed,
        isTargetReached: elapsed >= snap.targetMinutes * 60,
        phases: snap.phases,
        currentPhaseIndex: index,
        remainingSecondsInPhase: remaining,
        targetEndTime: phaseEnd,
      ),
    );
    await _persist();
    _startTicker();
  }

  Future<void> _finishSession(
    Emitter<FocusTimerState> emit, {
    required String goalId,
    required int targetMinutes,
  }) async {
    _tickerTimer?.cancel();
    final focusMins = (_accumulatedFocusSeconds / 60).floor();
    await sessionRepository.saveSession(
      FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: goalId,
        durationMinutes: focusMins,
        timestamp: DateTime.now(),
        completedTargetMet: _accumulatedFocusSeconds >= targetMinutes * 60,
      ),
    );
    await _clearPersisted();
    emit(
      FocusTimerCompletedState(
        goalId: goalId,
        totalMinutesCompleted: focusMins,
      ),
    );
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

    emit(
      FocusTimerRunningState(
        goalId: event.goalId,
        targetMinutes: event.targetMinutes,
        elapsedSeconds: 0,
        isTargetReached: false,
        phases: plan.phases,
        currentPhaseIndex: 0,
        remainingSecondsInPhase: firstPhase.durationSeconds,
        targetEndTime: targetEndTime,
      ),
    );

    await _persist();
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

    // Calculate actual elapsed seconds in this tick based on remaining seconds change
    final int delta = remainingInPhase > 0
        ? math.max(1, currentState.remainingSecondsInPhase - remainingInPhase)
        : currentState.remainingSecondsInPhase;

    // Accumulate total overall elapsed seconds
    final int totalElapsedSeconds = currentState.elapsedSeconds + delta;
    final int targetSeconds = currentState.targetMinutes * 60;
    final bool isReached = totalElapsedSeconds >= targetSeconds;

    if (currentPhase?.type == SessionPhaseType.focus) {
      _accumulatedFocusSeconds += delta;
    }

    if (remainingInPhase > 0) {
      emit(
        FocusTimerRunningState(
          goalId: currentState.goalId,
          targetMinutes: currentState.targetMinutes,
          elapsedSeconds: totalElapsedSeconds,
          isTargetReached: isReached,
          phases: currentState.phases,
          currentPhaseIndex: currentState.currentPhaseIndex,
          remainingSecondsInPhase: remainingInPhase,
          targetEndTime: currentState.targetEndTime,
        ),
      );
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
      final isTargetMet =
          _accumulatedFocusSeconds >= (currentState.targetMinutes * 60);

      final session = FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: currentState.goalId,
        durationMinutes: focusMins,
        timestamp: DateTime.now(),
        completedTargetMet: isTargetMet,
      );

      await sessionRepository.saveSession(session);
      await _clearPersisted();
      await audioService.playTransitionSound(
        enabled: _activeSettings.soundEnabled,
      );
      await notificationService.showPhaseNotification(
        title: 'Focus session complete',
        body: 'Your focus time has been logged.',
        enabled: _activeSettings.notificationsEnabled,
      );

      emit(
        FocusTimerCompletedState(
          goalId: currentState.goalId,
          totalMinutesCompleted: focusMins,
        ),
      );
      return;
    }

    final nextPhase = currentState.phases[nextIndex];
    final now = DateTime.now();
    final nextTargetEnd = manageTimerUseCase.buildTargetEndTime(
      from: now,
      durationSeconds: nextPhase.durationSeconds,
    );

    await audioService.playTransitionSound(
      enabled: _activeSettings.soundEnabled,
    );
    await notificationService.showPhaseNotification(
      title: nextPhase.type == SessionPhaseType.breakTime
          ? 'Break time'
          : 'Back to focus',
      body: nextPhase.type == SessionPhaseType.breakTime
          ? 'Take a short break before your next focus block.'
          : 'Break is over. Ready to focus?',
      enabled: _activeSettings.notificationsEnabled,
    );

    emit(
      FocusTimerRunningState(
        goalId: currentState.goalId,
        targetMinutes: currentState.targetMinutes,
        elapsedSeconds: currentState.elapsedSeconds,
        isTargetReached: currentState.isTargetReached,
        phases: currentState.phases,
        currentPhaseIndex: nextIndex,
        remainingSecondsInPhase: nextPhase.durationSeconds,
        targetEndTime: nextTargetEnd,
      ),
    );
    await _persist();
  }

  Future<void> _onPauseTimer(
    PauseFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) async {
    if (state is FocusTimerRunningState) {
      final currentState = state as FocusTimerRunningState;
      _tickerTimer?.cancel();
      emit(
        FocusTimerPausedState(
          goalId: currentState.goalId,
          targetMinutes: currentState.targetMinutes,
          elapsedSeconds: currentState.elapsedSeconds,
          phases: currentState.phases,
          currentPhaseIndex: currentState.currentPhaseIndex,
          remainingSecondsInPhase: currentState.remainingSecondsInPhase,
        ),
      );
      await _persist();
    }
  }

  Future<void> _onResumeTimer(
    ResumeFocusTimerEvent event,
    Emitter<FocusTimerState> emit,
  ) async {
    if (state is FocusTimerPausedState) {
      final currentState = state as FocusTimerPausedState;
      final now = DateTime.now();
      final targetEndTime = manageTimerUseCase.buildTargetEndTime(
        from: now,
        durationSeconds: currentState.remainingSecondsInPhase,
      );

      emit(
        FocusTimerRunningState(
          goalId: currentState.goalId,
          targetMinutes: currentState.targetMinutes,
          elapsedSeconds: currentState.elapsedSeconds,
          isTargetReached:
              currentState.elapsedSeconds >= (currentState.targetMinutes * 60),
          phases: currentState.phases,
          currentPhaseIndex: currentState.currentPhaseIndex,
          remainingSecondsInPhase: currentState.remainingSecondsInPhase,
          targetEndTime: targetEndTime,
        ),
      );

      await _persist();
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

      final effectiveFocusSeconds =
          (event.elapsedSeconds != null &&
              event.elapsedSeconds! > 0 &&
              _accumulatedFocusSeconds == 0)
          ? event.elapsedSeconds!
          : _accumulatedFocusSeconds;
      final focusMins = math.max(0, (effectiveFocusSeconds / 60).floor());
      final isTargetMet = effectiveFocusSeconds >= (targetMinutes * 60);

      final session = FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: goalId,
        durationMinutes: focusMins,
        timestamp: DateTime.now(),
        completedTargetMet: isTargetMet,
      );

      await sessionRepository.saveSession(session);
      await _clearPersisted();

      emit(
        FocusTimerCompletedState(
          goalId: goalId,
          totalMinutesCompleted: focusMins,
        ),
      );
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
