import '../../../settings/domain/entities/app_settings.dart';
import '../entities/session_phase.dart';

class CalculateChunksUseCase {
  FocusSessionPlan call({
    required int totalTargetMinutes,
    required AppSettings settings,
    bool skipBreaks = false,
  }) {
    final int safeTargetMinutes = totalTargetMinutes <= 0
        ? 5
        : totalTargetMinutes;

    if (skipBreaks || settings.breakDurationMinutes <= 0) {
      final singlePhase = SessionPhase(
        type: SessionPhaseType.focus,
        durationSeconds: safeTargetMinutes * 60,
        labelMinutes: safeTargetMinutes,
      );
      return FocusSessionPlan(
        totalTargetMinutes: safeTargetMinutes,
        phases: [singlePhase],
        totalFocusSeconds: safeTargetMinutes * 60,
        totalBreakSeconds: 0,
      );
    }

    final int focusMins = settings.focusDurationMinutes <= 0
        ? 25
        : settings.focusDurationMinutes;
    final int breakMins = settings.breakDurationMinutes;

    final List<SessionPhase> phases = [];
    int remainingMinsToChunk = safeTargetMinutes;
    int totalFocusSecs = 0;
    int totalBreakSecs = 0;

    while (remainingMinsToChunk > 0) {
      final int currentFocusMins = remainingMinsToChunk > focusMins
          ? focusMins
          : remainingMinsToChunk;
      final int focusSecs = currentFocusMins * 60;

      phases.add(
        SessionPhase(
          type: SessionPhaseType.focus,
          durationSeconds: focusSecs,
          labelMinutes: currentFocusMins,
        ),
      );
      totalFocusSecs += focusSecs;
      remainingMinsToChunk -= currentFocusMins;

      // Add a break phase if there is still remaining target focus time left
      if (remainingMinsToChunk > 0 && breakMins > 0) {
        final int breakSecs = breakMins * 60;
        phases.add(
          SessionPhase(
            type: SessionPhaseType.breakTime,
            durationSeconds: breakSecs,
            labelMinutes: breakMins,
          ),
        );
        totalBreakSecs += breakSecs;
      }
    }

    return FocusSessionPlan(
      totalTargetMinutes: safeTargetMinutes,
      phases: phases,
      totalFocusSeconds: totalFocusSecs,
      totalBreakSeconds: totalBreakSecs,
    );
  }
}
