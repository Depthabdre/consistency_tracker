import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../datasources/focus_session_local_datasource.dart';
import '../models/focus_session_model.dart';

abstract class FocusSessionRepository {
  Future<Result<List<FocusSessionModel>>> getSessionsForGoal(String goalId);
  Future<Result<bool>> saveSession(FocusSessionModel session);
}

class FocusSessionRepositoryImpl implements FocusSessionRepository {
  final FocusSessionLocalDataSource localDataSource;

  FocusSessionRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<FocusSessionModel>>> getSessionsForGoal(
    String goalId,
  ) async {
    try {
      final sessions = await localDataSource.getSessionsForGoal(goalId);
      return Result.success(sessions);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to load focus sessions: $e'));
    }
  }

  @override
  Future<Result<bool>> saveSession(FocusSessionModel session) async {
    try {
      final success = await localDataSource.saveSession(session);
      return Result.success(success);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to save focus session: $e'));
    }
  }
}
