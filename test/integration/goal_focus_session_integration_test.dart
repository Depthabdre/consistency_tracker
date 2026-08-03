import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  final goalA = GoalModel(
    id: 'goal_a',
    title: 'Flutter Coding',
    description: 'Build consistency tracker features',
    targetMinutes: 30,
    reminderTimeHour: 9,
    reminderTimeMinute: 0,
    motivationalQuote: 'Keep coding!',
    colorHex: '#53B5EA',
    createdAt: DateTime(2026, 8, 1),
  );

  final goalB = GoalModel(
    id: 'goal_b',
    title: 'Daily Reading',
    description: 'Read technical books',
    targetMinutes: 25,
    reminderTimeHour: 20,
    reminderTimeMinute: 0,
    motivationalQuote: 'Readers are leaders!',
    colorHex: '#34D399',
    createdAt: DateTime(2026, 8, 1),
  );

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    when(() => mockGoalRepository.getGoals())
        .thenAnswer((_) async => Result.success([goalA, goalB]));
    goalBloc = GoalBloc(goalRepository: mockGoalRepository);
  });

  group('Integration - Multi-Goal Focus Progress Isolation', () {
    test('Focusing 1 minute on Goal A updates ONLY Goal A and leaves Goal B at 0', () async {
      // 1. Initial Load
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(
        goalBloc.stream,
        emitsThrough(isA<GoalLoadedState>()),
      );

      final initialState = goalBloc.state as GoalLoadedState;
      expect(initialState.todayMinutesByGoalId['goal_a'] ?? 0, equals(0));
      expect(initialState.todayMinutesByGoalId['goal_b'] ?? 0, equals(0));

      // 2. User focuses 1 minute on Goal A
      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 1));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Goal A progress',
            equals(1),
          ),
        ),
      );

      final updatedState = goalBloc.state as GoalLoadedState;

      // Assert Goal A has 1 minute focused (1 / 30 mins) -> NOT completed!
      final goalAMins = updatedState.todayMinutesByGoalId['goal_a'] ?? 0;
      final isGoalACompleted = goalAMins >= goalA.targetMinutes;
      expect(goalAMins, equals(1));
      expect(isGoalACompleted, isFalse);

      // Assert Goal B remains untouched at 0 minutes (0 / 25 mins) -> NOT completed!
      final goalBMins = updatedState.todayMinutesByGoalId['goal_b'] ?? 0;
      final isGoalBCompleted = goalBMins >= goalB.targetMinutes;
      expect(goalBMins, equals(0));
      expect(isGoalBCompleted, isFalse);
    });

    test('Completing Goal A target (30 mins) completes ONLY Goal A, leaving Goal B incomplete', () async {
      // 1. Initial Load
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(
        goalBloc.stream,
        emitsThrough(isA<GoalLoadedState>()),
      );

      // 2. User completes full 30 minutes on Goal A
      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 30));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Goal A progress',
            equals(30),
          ),
        ),
      );

      final state = goalBloc.state as GoalLoadedState;

      // Assert Goal A is completed (30 >= 30)
      final goalAMins = state.todayMinutesByGoalId['goal_a'] ?? 0;
      expect(goalAMins >= goalA.targetMinutes, isTrue);

      // Assert Goal B remains incomplete (0 < 25)
      final goalBMins = state.todayMinutesByGoalId['goal_b'] ?? 0;
      expect(goalBMins >= goalB.targetMinutes, isFalse);
    });
  });
}
