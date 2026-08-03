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

  const testGoal = GoalModel(
    id: '1',
    title: 'Daily Reading',
    description: 'Read 20 pages',
    targetMinutes: 20,
    reminderTimeHour: 8,
    reminderTimeMinute: 30,
    motivationalQuote: 'Readers are leaders.',
    colorHex: '#10B981',
  );

  setUpAll(() {
    registerFallbackValue(testGoal);
  });

  setUp(() {
    mockLocalDataSource = MockGoalLocalDataSource();
    repository = GoalRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getGoals', () {
    test('should return list of goals from local data source', () async {
      when(() => mockLocalDataSource.getGoals())
          .thenAnswer((_) async => [testGoal]);

      final result = await repository.getGoals();

      expect(result.isSuccess, isTrue);
      expect(result.data, equals([testGoal]));
      verify(() => mockLocalDataSource.getGoals()).called(1);
    });

    test('should return CacheFailure when datasource throws an exception', () async {
      when(() => mockLocalDataSource.getGoals())
          .thenThrow(Exception('Hive error'));

      final result = await repository.getGoals();

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<CacheFailure>());
    });
  });

  group('saveGoal', () {
    test('should save goal to local data source', () async {
      when(() => mockLocalDataSource.saveGoal(any()))
          .thenAnswer((_) async => true);

      final result = await repository.saveGoal(testGoal);

      expect(result.isSuccess, isTrue);
      verify(() => mockLocalDataSource.saveGoal(testGoal)).called(1);
    });
  });
}
