import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../datasources/calendar_local_datasource.dart';
import '../models/calendar_day_model.dart';

abstract class CalendarRepository {
  Future<Result<List<CalendarDayModel>>> getCalendarEntries(String goalId);
  Future<Result<bool>> saveCalendarDay(String goalId, CalendarDayModel day);
  Future<Result<CalendarDayModel>> addFocusMinutesToToday({
    required String goalId,
    required int targetMinutes,
    required int minutesToAdd,
  });
}

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;

  CalendarRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<CalendarDayModel>>> getCalendarEntries(
    String goalId,
  ) async {
    try {
      final entries = await localDataSource.getCalendarEntries(goalId);
      return Result.success(entries);
    } catch (e) {
      return Result.failure(
        CacheFailure('Failed to load calendar entries: $e'),
      );
    }
  }

  @override
  Future<Result<bool>> saveCalendarDay(
    String goalId,
    CalendarDayModel day,
  ) async {
    try {
      final success = await localDataSource.saveCalendarDay(goalId, day);
      return Result.success(success);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to save calendar day: $e'));
    }
  }

  @override
  Future<Result<CalendarDayModel>> addFocusMinutesToToday({
    required String goalId,
    required int targetMinutes,
    required int minutesToAdd,
  }) async {
    try {
      final updatedDay = await localDataSource.addFocusMinutesToToday(
        goalId: goalId,
        targetMinutes: targetMinutes,
        minutesToAdd: minutesToAdd,
      );
      return Result.success(updatedDay);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to add focus minutes: $e'));
    }
  }
}
