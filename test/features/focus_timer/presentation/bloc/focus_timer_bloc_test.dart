import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/features/focus_timer/data/repositories/focus_session_repository.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_event.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_state.dart';

class MockFocusSessionRepository extends Mock implements FocusSessionRepository {}

void main() {
  late FocusTimerBloc bloc;
  late MockFocusSessionRepository mockRepository;

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
}
