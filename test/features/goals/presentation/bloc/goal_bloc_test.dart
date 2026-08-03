import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/errors/failures.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_event.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_state.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late GoalBloc goalBloc;
  late MockGoalRepository mockGoalRepository;

  const testGoal = GoalModel(
    id: '1',
    title: 'Daily Flutter',
    description: 'Build consistency tracker app',
    targetMinutes: 30,
    reminderTimeHour: 9,
    reminderTimeMinute: 0,
    motivationalQuote: 'Keep building!',
    colorHex: '#6366F1',
  );

  setUpAll(() {
    registerFallbackValue(testGoal);
  });

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    goalBloc = GoalBloc(goalRepository: mockGoalRepository);
  });

  test('initial state should be GoalInitialState', () {
    expect(goalBloc.state, equals(const GoalInitialState()));
  });

  blocTest<GoalBloc, GoalState>(
    'Positive: emits [GoalLoadingState, GoalLoadedState] when LoadGoalsEvent succeeds',
    build: () {
      when(() => mockGoalRepository.getGoals())
          .thenAnswer((_) async => const Result.success([testGoal]));
      return goalBloc;
    },
    act: (bloc) => bloc.add(const LoadGoalsEvent()),
    expect: () => [
      const GoalLoadingState(),
      const GoalLoadedState([testGoal]),
    ],
    verify: (_) {
      verify(() => mockGoalRepository.getGoals()).called(1);
    },
  );

  blocTest<GoalBloc, GoalState>(
    'Negative: emits [GoalLoadingState, GoalErrorState] when LoadGoalsEvent fails',
    build: () {
      when(() => mockGoalRepository.getGoals()).thenAnswer(
        (_) async => const Result.failure(CacheFailure('Failed to load goals')),
      );
      return goalBloc;
    },
    act: (bloc) => bloc.add(const LoadGoalsEvent()),
    expect: () => [
      const GoalLoadingState(),
      const GoalErrorState('Failed to load goals'),
    ],
  );

  blocTest<GoalBloc, GoalState>(
    'Positive: AddGoalEvent triggers save and reloads goals list',
    build: () {
      when(() => mockGoalRepository.saveGoal(any()))
          .thenAnswer((_) async => const Result.success(true));
      when(() => mockGoalRepository.getGoals())
          .thenAnswer((_) async => const Result.success([testGoal]));
      return goalBloc;
    },
    act: (bloc) => bloc.add(const AddGoalEvent(testGoal)),
    expect: () => [
      const GoalLoadingState(),
      const GoalLoadedState([testGoal]),
    ],
    verify: (_) {
      verify(() => mockGoalRepository.saveGoal(testGoal)).called(1);
      verify(() => mockGoalRepository.getGoals()).called(1);
    },
  );

  blocTest<GoalBloc, GoalState>(
    'Negative: AddGoalEvent emits GoalErrorState when save fails',
    build: () {
      when(() => mockGoalRepository.saveGoal(any())).thenAnswer(
        (_) async => const Result.failure(CacheFailure('Save failed')),
      );
      return goalBloc;
    },
    act: (bloc) => bloc.add(const AddGoalEvent(testGoal)),
    expect: () => [
      const GoalLoadingState(),
      const GoalErrorState('Save failed'),
    ],
  );

  blocTest<GoalBloc, GoalState>(
    'Positive: DeleteGoalEvent deletes goal and reloads goals list',
    build: () {
      when(() => mockGoalRepository.deleteGoal('1'))
          .thenAnswer((_) async => const Result.success(true));
      when(() => mockGoalRepository.getGoals())
          .thenAnswer((_) async => const Result.success([]));
      return goalBloc;
    },
    act: (bloc) => bloc.add(const DeleteGoalEvent('1')),
    expect: () => [
      const GoalLoadingState(),
      const GoalLoadedState([]),
    ],
    verify: (_) {
      verify(() => mockGoalRepository.deleteGoal('1')).called(1);
    },
  );
}
