import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/focus_timer/domain/usecases/manage_timer_usecase.dart';

void main() {
  late ManageTimerUseCase useCase;

  setUp(() {
    useCase = ManageTimerUseCase();
  });

  group('ManageTimerUseCase Unit Tests', () {
    test(
      'Positive: buildTargetEndTime adds durationSeconds to from DateTime',
      () {
        final now = DateTime(2026, 8, 1, 10, 0, 0);
        final targetEnd = useCase.buildTargetEndTime(
          from: now,
          durationSeconds: 1500,
        );

        expect(targetEnd, equals(DateTime(2026, 8, 1, 10, 25, 0)));
      },
    );

    test(
      'Positive: calculateRemainingSeconds returns accurate remaining difference',
      () {
        final now = DateTime(2026, 8, 1, 10, 10, 0);
        final targetEnd = DateTime(2026, 8, 1, 10, 25, 0);

        final remaining = useCase.calculateRemainingSeconds(
          now: now,
          targetEndTime: targetEnd,
        );

        expect(remaining, equals(900));
      },
    );

    test(
      'Boundary: calculateRemainingSeconds clamps negative difference to 0',
      () {
        final now = DateTime(2026, 8, 1, 10, 30, 0);
        final targetEnd = DateTime(2026, 8, 1, 10, 25, 0);

        final remaining = useCase.calculateRemainingSeconds(
          now: now,
          targetEndTime: targetEnd,
        );

        expect(remaining, equals(0));
      },
    );
  });
}
