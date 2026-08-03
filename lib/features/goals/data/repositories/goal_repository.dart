import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../datasources/goal_local_datasource.dart';
import '../models/goal_model.dart';

abstract class GoalRepository {
  Future<Result<List<GoalModel>>> getGoals();
  Future<Result<bool>> saveGoal(GoalModel goal);
  Future<Result<bool>> deleteGoal(String id);
}

class GoalRepositoryImpl implements GoalRepository {
  final GoalLocalDataSource localDataSource;

  GoalRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<GoalModel>>> getGoals() async {
    try {
      final goals = await localDataSource.getGoals();
      return Result.success(goals);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to load goals: $e'));
    }
  }

  @override
  Future<Result<bool>> saveGoal(GoalModel goal) async {
    try {
      final success = await localDataSource.saveGoal(goal);
      return Result.success(success);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to save goal: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteGoal(String id) async {
    try {
      final success = await localDataSource.deleteGoal(id);
      return Result.success(success);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to delete goal: $e'));
    }
  }
}
