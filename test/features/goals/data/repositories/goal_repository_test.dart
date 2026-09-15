import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/errors/failures.dart';
import 'package:consistency_tracker/features/goals/data/datasources/goal_local_datasource.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';

class MockGoalLocalDataSource extends Mock implements GoalLocalDataSource {}

void main() {
  late GoalRepository repository;
  late MockGoalLocalDataSource mockLocalDataSource;

  final testGoal = GoalModel(
    id: '1',
    title: 'Daily Reading',
    description: 'Read 20 pages',
    targetMinutes: 20,
    reminderTimeHour: 8,
    reminderTimeMinute: 30,
    motivationalQuote: 'Readers are leaders.',
    colorHex: '#10B981',
    createdAt: DateTime(2026, 8, 1),
  );

  setUpAll(() {
    registerFallbackValue(testGoal);
  });

  setUp(() {
    mockLocalDataSource = MockGoalLocalDataSource();
    repository = GoalRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getGoals', () {
    test(
      'Positive: should return list of goals from local data source',
      () async {
        when(
          () => mockLocalDataSource.getGoals(),
        ).thenAnswer((_) async => [testGoal]);

        final result = await repository.getGoals();

        expect(result.isSuccess, isTrue);
        expect(result.data, equals([testGoal]));
        verify(() => mockLocalDataSource.getGoals()).called(1);
      },
    );

    test('Edge Case: should return empty list when no goals exist', () async {
      when(() => mockLocalDataSource.getGoals()).thenAnswer((_) async => []);

      final result = await repository.getGoals();

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test(
      'Negative: should return CacheFailure when datasource throws an exception',
      () async {
        when(
          () => mockLocalDataSource.getGoals(),
        ).thenThrow(Exception('Hive error'));

        final result = await repository.getGoals();

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<CacheFailure>());
        expect(result.failure!.message, contains('Hive error'));
      },
    );
  });

  group('saveGoal', () {
    test('Positive: should save goal to local data source', () async {
      when(
        () => mockLocalDataSource.saveGoal(any()),
      ).thenAnswer((_) async => true);

      final result = await repository.saveGoal(testGoal);

      expect(result.isSuccess, isTrue);
      expect(result.data, isTrue);
      verify(() => mockLocalDataSource.saveGoal(testGoal)).called(1);
    });

    test(
      'Negative: should return CacheFailure when save Goal throws error',
      () async {
        when(
          () => mockLocalDataSource.saveGoal(any()),
        ).thenThrow(Exception('Disk full'));

        final result = await repository.saveGoal(testGoal);

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<CacheFailure>());
        expect(result.failure!.message, contains('Disk full'));
      },
    );
  });

  group('deleteGoal', () {
    test('Positive: should delete goal from local data source', () async {
      when(
        () => mockLocalDataSource.deleteGoal('1'),
      ).thenAnswer((_) async => true);

      final result = await repository.deleteGoal('1');

      expect(result.isSuccess, isTrue);
      expect(result.data, isTrue);
      verify(() => mockLocalDataSource.deleteGoal('1')).called(1);
    });

    test(
      'Negative: should return CacheFailure when deleteGoal throws error',
      () async {
        when(
          () => mockLocalDataSource.deleteGoal('1'),
        ).thenThrow(Exception('Key not found'));

        final result = await repository.deleteGoal('1');

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<CacheFailure>());
      },
    );
  });
}
