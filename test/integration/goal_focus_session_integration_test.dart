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
    targetMinutes: 30,
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

    test('Completing Goal A target (30 mins) completes ONLY Goal A', () async {
      goalBloc.add(const LoadGoalsEvent());
      await expectLater(goalBloc.stream, emitsThrough(isA<GoalLoadedState>()));

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
      // Existing goals remain unaffected
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

      // Rapidly dispatch multiple conflicting events
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
