import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/focus_timer/data/models/focus_session_model.dart';
import 'package:consistency_tracker/features/focus_timer/data/repositories/focus_session_repository.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_event.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_state.dart';

class MockFocusSessionRepository extends Mock implements FocusSessionRepository {}

void main() {
  late FocusTimerBloc bloc;
  late MockFocusSessionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FocusSessionModel(
      id: 's1',
      goalId: 'g1',
      durationMinutes: 25,
      timestamp: DateTime.now(),
      completedTargetMet: true,
    ));
  });

  setUp(() {
    mockRepository = MockFocusSessionRepository();
    when(() => mockRepository.saveSession(any()))
        .thenAnswer((_) async => const Result.success(true));
    bloc = FocusTimerBloc(sessionRepository: mockRepository);
  });

  test('Positive: initial state should be FocusTimerInitialState', () {
    expect(bloc.state, isA<FocusTimerInitialState>());
  });

  test('Positive: StartFocusTimerEvent emits FocusTimerRunningState', () {
    bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));

    expect(
      bloc.stream,
      emits(isA<FocusTimerRunningState>()),
    );
  });

  group('CompleteFocusTimerEvent - Exact Elapsed Time Calculation', () {
    test('Positive: complete full session (1500s) logs 25 minutes', () async {
      bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));
      bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 1500));

      expect(
        bloc.stream,
        emitsThrough(
          isA<FocusTimerCompletedState>().having(
            (s) => s.totalMinutesCompleted,
            'totalMinutesCompleted',
            equals(25),
          ),
        ),
      );
    });

    test('Partial/Early Stop: stop session after 120s logs exactly 2 minutes', () async {
      bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));
      bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 120));

      expect(
        bloc.stream,
        emitsThrough(
          isA<FocusTimerCompletedState>().having(
            (s) => s.totalMinutesCompleted,
            'totalMinutesCompleted',
            equals(2),
          ),
        ),
      );
    });

    test('Edge Case: stop session after 45s logs 0 minutes', () async {
      bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));
      bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 45));

      expect(
        bloc.stream,
        emitsThrough(
          isA<FocusTimerCompletedState>().having(
            (s) => s.totalMinutesCompleted,
            'totalMinutesCompleted',
            equals(0),
          ),
        ),
      );
    });

    test('Edge Case: negative elapsed seconds (-100s) clamps to 0 minutes', () async {
      bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));
      bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: -100));

      expect(
        bloc.stream,
        emitsThrough(
          isA<FocusTimerCompletedState>().having(
            (s) => s.totalMinutesCompleted,
            'totalMinutesCompleted',
            equals(0),
          ),
        ),
      );
    });
  });

  group('Negative & Unusual State Transitions', () {
    test('Negative: PauseFocusTimerEvent while initial state does nothing', () {
      bloc.add(const PauseFocusTimerEvent());
      expect(bloc.state, isA<FocusTimerInitialState>());
    });

    test('Negative: ResumeFocusTimerEvent while initial state does nothing', () {
      bloc.add(const ResumeFocusTimerEvent());
      expect(bloc.state, isA<FocusTimerInitialState>());
    });
  });

  group('Monkey / Chaos Sequence', () {
    test('Chaos: Rapid sequence Start -> Pause -> Resume -> Pause -> Complete', () async {
      bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 30));
      bloc.add(const PauseFocusTimerEvent());
      bloc.add(const ResumeFocusTimerEvent());
      bloc.add(const PauseFocusTimerEvent());
      bloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 300));

      expect(
        bloc.stream,
        emitsThrough(
          isA<FocusTimerCompletedState>().having(
            (s) => s.totalMinutesCompleted,
            'Chaos sequence total minutes',
            equals(5),
          ),
        ),
      );
    });
  });
}
