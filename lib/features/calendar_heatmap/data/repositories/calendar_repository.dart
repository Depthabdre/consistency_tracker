import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../datasources/calendar_local_datasource.dart';
import '../models/calendar_day_model.dart';

abstract class CalendarRepository {
  Future<Result<List<CalendarDayModel>>> getCalendarEntries(String goalId);
  Future<Result<bool>> saveCalendarDay(String goalId, CalendarDayModel day);
}

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;

  CalendarRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<CalendarDayModel>>> getCalendarEntries(String goalId) async {
    try {
      final entries = await localDataSource.getCalendarEntries(goalId);
      return Result.success(entries);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to load calendar entries: $e'));
    }
  }

  @override
  Future<Result<bool>> saveCalendarDay(String goalId, CalendarDayModel day) async {
    try {
      final success = await localDataSource.saveCalendarDay(goalId, day);
      return Result.success(success);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to save calendar day: $e'));
    }
  }
}
