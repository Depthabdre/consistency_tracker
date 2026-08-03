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
    bloc = FocusTimerBloc(sessionRepository: mockRepository);
  });

  test('initial state should be FocusTimerInitialState', () {
    expect(bloc.state, isA<FocusTimerInitialState>());
  });

  test('StartFocusTimerEvent emits FocusTimerRunningState', () {
    bloc.add(const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 25));

    expect(
      bloc.stream,
      emits(isA<FocusTimerRunningState>()),
    );
  });

  group('CompleteFocusTimerEvent - Exact Elapsed Time Calculation', () {
    test('Positive: complete full session (1500s) logs 25 minutes', () async {
      when(() => mockRepository.saveSession(any()))
          .thenAnswer((_) async => const Result.success(true));

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
      when(() => mockRepository.saveSession(any()))
          .thenAnswer((_) async => const Result.success(true));

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
      when(() => mockRepository.saveSession(any()))
          .thenAnswer((_) async => const Result.success(true));

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
  });
}
