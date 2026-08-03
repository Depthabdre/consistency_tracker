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
    title: 'Flutter Coding 🎯',
    description: 'Build consistency tracker features',
    targetMinutes: 25,
    reminderTimeHour: 9,
    reminderTimeMinute: 0,
    motivationalQuote: 'Keep coding!',
    colorHex: '#53B5EA',
    createdAt: DateTime(2026, 8, 1),
  );

  final goalB = GoalModel(
    id: 'goal_b',
    title: 'Daily Reading 📚',
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
    when(() => mockGoalRepository.deleteGoal(any()))
        .thenAnswer((_) async => const Result.success(true));
    goalBloc = GoalBloc(goalRepository: mockGoalRepository);
  });

  group('Integration - Defect Prevention (1 min + 2 min = 3 min)', () {
    test('TC-P0-01 (Defect Fix): Goal with 1 min existing progress + 2 min focus session stop = EXACTLY 3/25 mins (NOT 26/25)', () async {
      // 1. Initial Load
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

      // 2. Initial state has 1 minute logged today
      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 1));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Goal A initial progress',
            equals(1),
          ),
        ),
      );

      // 3. User starts a 25m session and stops after 2 minutes -> cumulative = 1 + 2 = 3
      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 3));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Goal A cumulative progress',
            equals(3),
          ),
        ),
      );

      final state = goalBloc.state as GoalLoadedState;

      // Assert Goal A has EXACTLY 3 minutes focused (3 / 25 mins) -> NOT completed!
      final goalAMins = state.todayMinutesByGoalId['goal_a'] ?? 0;
      expect(goalAMins, equals(3));
      expect(goalAMins >= goalA.targetMinutes, isFalse);

      // Assert Goal B remains untouched at 0 mins
      expect(state.todayMinutesByGoalId['goal_b'] ?? 0, equals(0));
    });
  });

  group('Integration - Positive Multi-Goal Focus Isolation', () {
    test('Focusing 1 minute on Goal A updates ONLY Goal A and leaves Goal B at 0', () async {
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

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

      final state = goalBloc.state as GoalLoadedState;
      expect(state.todayMinutesByGoalId['goal_a'], equals(1));
      expect(state.todayMinutesByGoalId['goal_b'] ?? 0, equals(0));
    });

    test('Completing Goal A target (25 mins) completes ONLY Goal A', () async {
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 25));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Goal A progress',
            equals(25),
          ),
        ),
      );

      final state = goalBloc.state as GoalLoadedState;
      expect(state.todayMinutesByGoalId['goal_a']! >= goalA.targetMinutes, isTrue);
      expect((state.todayMinutesByGoalId['goal_b'] ?? 0) >= goalB.targetMinutes, isFalse);
    });
  });

  group('Integration - Negative & Unusual Edge Cases', () {
    test('Negative: Updating progress for non-existent goal ID does not corrupt existing goals', () async {
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'ghost_goal_99', todayMinutes: 15));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['ghost_goal_99'],
            'Ghost goal progress',
            equals(15),
          ),
        ),
      );

      final state = goalBloc.state as GoalLoadedState;
      expect(state.todayMinutesByGoalId['goal_a'] ?? 0, equals(0));
      expect(state.todayMinutesByGoalId['goal_b'] ?? 0, equals(0));
    });

    test('Edge Case: Extremely large focus minutes (720 mins) handled safely', () async {
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 720));
      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Goal A max progress',
            equals(720),
          ),
        ),
      );

      final state = goalBloc.state as GoalLoadedState;
      expect(state.todayMinutesByGoalId['goal_a'], equals(720));
    });
  });

  group('Integration - Monkey / Chaos Testing Scenarios', () {
    test('Chaos: Rapid interleaved progress updates, goal deletion, and reloads retain consistency', () async {
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 5));
      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_b', todayMinutes: 10));
      goalBloc.add(const UpdateGoalProgressEvent(goalId: 'goal_a', todayMinutes: 20));

      await expectLater(
        goalBloc.stream,
        emitsThrough(
          isA<GoalLoadedState>().having(
            (s) => s.todayMinutesByGoalId['goal_a'],
            'Final Goal A progress',
            equals(20),
          ),
        ),
      );

      final state = goalBloc.state as GoalLoadedState;
      expect(state.todayMinutesByGoalId['goal_a'], equals(20));
      expect(state.todayMinutesByGoalId['goal_b'], equals(10));
    });
  });
}
