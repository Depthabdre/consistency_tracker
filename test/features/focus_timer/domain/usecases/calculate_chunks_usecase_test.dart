import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/focus_timer/domain/entities/session_phase.dart';
import 'package:consistency_tracker/features/focus_timer/domain/usecases/calculate_chunks_usecase.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';

void main() {
  late CalculateChunksUseCase useCase;

  setUp(() {
    useCase = CalculateChunksUseCase();
  });

  group('CalculateChunksUseCase Unit Tests', () {
    test(
      'Positive: 60 min target with 25 min focus & 5 min break creates 5 phases',
      () {
        const settings = AppSettings(
          focusDurationMinutes: 25,
          breakDurationMinutes: 5,
          soundEnabled: true,
          notificationsEnabled: true,
        );

        final plan = useCase(totalTargetMinutes: 60, settings: settings);

        expect(plan.totalTargetMinutes, equals(60));
        expect(plan.phases.length, equals(5));
        expect(plan.phases[0].type, equals(SessionPhaseType.focus));
        expect(plan.phases[0].labelMinutes, equals(25));
        expect(plan.phases[1].type, equals(SessionPhaseType.breakTime));
        expect(plan.phases[1].labelMinutes, equals(5));
        expect(plan.phases[2].type, equals(SessionPhaseType.focus));
        expect(plan.phases[2].labelMinutes, equals(25));
        expect(plan.phases[3].type, equals(SessionPhaseType.breakTime));
        expect(plan.phases[3].labelMinutes, equals(5));
        expect(plan.phases[4].type, equals(SessionPhaseType.focus));
        expect(plan.phases[4].labelMinutes, equals(10));
      },
    );

    test(
      'Continuous Focus Mode: skipBreaks == true creates single Focus phase',
      () {
        const settings = AppSettings(
          focusDurationMinutes: 25,
          breakDurationMinutes: 5,
          soundEnabled: true,
          notificationsEnabled: true,
        );

        final plan = useCase(
          totalTargetMinutes: 60,
          settings: settings,
          skipBreaks: true,
        );

        expect(plan.phases.length, equals(1));
        expect(plan.phases[0].type, equals(SessionPhaseType.focus));
        expect(plan.phases[0].labelMinutes, equals(60));
        expect(plan.totalBreakSeconds, equals(0));
      },
    );

    test('Edge Case: breakDurationMinutes == 0 creates single Focus phase', () {
      const settings = AppSettings(
        focusDurationMinutes: 25,
        breakDurationMinutes: 0,
        soundEnabled: true,
        notificationsEnabled: true,
      );

      final plan = useCase(totalTargetMinutes: 45, settings: settings);

      expect(plan.phases.length, equals(1));
      expect(plan.phases[0].type, equals(SessionPhaseType.focus));
      expect(plan.phases[0].labelMinutes, equals(45));
    });
  });
}
