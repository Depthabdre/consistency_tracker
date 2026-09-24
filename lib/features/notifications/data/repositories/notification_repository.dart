import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../goals/data/models/goal_model.dart';
import '../datasources/notification_local_datasource.dart';

abstract class NotificationRepository {
  Future<Result<void>> initNotifications();
  Future<Result<void>> scheduleReminder({
    required int id,
    required String title,
    required String quote,
    required int hour,
    required int minute,
  });

  /// [skipToday] starts the daily cycle tomorrow (used once today's target is
  /// met). [includeEscalation] defaults to the user's setting.
  Future<Result<void>> scheduleGoalReminders(
    GoalModel goal, {
    bool skipToday = false,
    bool? includeEscalation,
  });
  Future<Result<void>> showImmediateNotification({
    required String title,
    required String body,
  });
  Future<Result<void>> cancelReminder(int id);
  Future<Result<void>> cancelGoalReminders(String goalId);
  Future<bool> requestPermission();
  Future<bool?> hasPermission();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;
  final bool Function()? escalationEnabled;

  NotificationRepositoryImpl({
    required this.localDataSource,
    this.escalationEnabled,
  });

  @override
  Future<Result<void>> initNotifications() async {
    try {
      await localDataSource.initialize();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Notification init failed: $e'),
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await localDataSource.requestPermission();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool?> hasPermission() async {
    try {
      return await localDataSource.hasPermission();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<void>> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    try {
      await localDataSource.showImmediateNotification(title: title, body: body);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Immediate notification failed: $e'),
      );
    }
  }

  @override
  Future<Result<void>> scheduleReminder({
    required int id,
    required String title,
    required String quote,
    required int hour,
    required int minute,
  }) async {
    try {
      await localDataSource.scheduleGoalNotification(
        id: id,
        title: title,
        body: quote.isNotEmpty
            ? quote
            : 'You won\'t regret taking $title minutes for your future self today.',
        hour: hour,
        minute: minute,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to schedule reminder: $e'),
      );
    }
  }

  static const List<int> _escalationOffsets = [-30, -20, -10, -5, -1, 0];
  static const int _maxReminders = 5;

  /// Minutes past midnight after applying [offsetMinutes], plus how many days
  /// the time shifted (-1 when an early nudge crosses midnight).
  static (int, int, int) _calculateOffsetTime(
    int hour,
    int minute,
    int offsetMinutes,
  ) {
    final raw = hour * 60 + minute + offsetMinutes;
    final dayShift = raw < 0 ? -1 : (raw >= 24 * 60 ? 1 : 0);
    final total = raw % (24 * 60);
    return (total ~/ 60, total % 60, dayShift);
  }

  @override
  Future<Result<void>> scheduleGoalReminders(
    GoalModel goal, {
    bool skipToday = false,
    bool? includeEscalation,
  }) async {
    try {
      final baseId = goal.id.hashCode.abs() % 100000;
      final reminders = goal.activeReminderTimes.take(_maxReminders).toList();
      final withEscalation =
          includeEscalation ?? escalationEnabled?.call() ?? true;
      // Daily IDs use baseId..+59; weekly (rest-day) IDs use baseId+100..+309.
      final weekdays = goal.hasRestDays ? goal.activeWeekdays : const <int>[];

      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        for (int j = 0; j < _escalationOffsets.length; j++) {
          final offset = _escalationOffsets[j];
          if (!withEscalation && offset != 0) continue;
          final (hour, minute, dayShift) = _calculateOffsetTime(
            reminder.hour,
            reminder.minute,
            offset,
          );

          final String title;
          final String body;

          if (offset == 0) {
            title = goal.title;
            body = goal.motivationalQuote.isNotEmpty
                ? goal.motivationalQuote
                : 'Time for your ${goal.targetMinutes} minutes today.';
          } else {
            final minsRemaining = -offset;
            title = '${goal.title} in $minsRemaining min';
            body = goal.motivationalQuote.isNotEmpty
                ? goal.motivationalQuote
                : 'Your reminder is coming up in $minsRemaining minutes.';
          }

          if (weekdays.isEmpty) {
            await _schedule(
              id: baseId + (i * 10) + j,
              title: title,
              body: body,
              hour: hour,
              minute: minute,
              skipToday: skipToday,
            );
            continue;
          }
          for (final day in weekdays) {
            await _schedule(
              id: baseId + 100 + ((day - 1) * _maxReminders + i) * 6 + j,
              title: title,
              body: body,
              hour: hour,
              minute: minute,
              skipToday: skipToday,
              weekday: (day - 1 + dayShift) % 7 + 1,
            );
          }
        }
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to schedule goal reminders: $e'),
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required bool skipToday,
    int? weekday,
  }) {
    // Only pass optional args when set so existing call signatures stay stable.
    if (weekday != null) {
      return localDataSource.scheduleGoalNotification(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        startTomorrow: skipToday,
        weekday: weekday,
      );
    }
    if (skipToday) {
      return localDataSource.scheduleGoalNotification(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        startTomorrow: true,
      );
    }
    return localDataSource.scheduleGoalNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    );
  }

  @override
  Future<Result<void>> cancelReminder(int id) async {
    try {
      await localDataSource.cancelNotification(id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to cancel reminder: $e'),
      );
    }
  }

  @override
  Future<Result<void>> cancelGoalReminders(String goalId) async {
    try {
      await localDataSource.cancelGoalReminders(goalId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to cancel goal reminders: $e'),
      );
    }
  }
}
